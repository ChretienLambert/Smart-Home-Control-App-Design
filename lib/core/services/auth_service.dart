import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../models/auth_session.dart';
import '../services/database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _db = DatabaseService();
  User? _currentUser;
  AuthSession? _currentSession;

  // Getters
  User? get currentUser => _currentUser;
  AuthSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentUser != null && _currentSession != null && _currentSession!.isValid;

  // Stream controllers for auth state changes
  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  final StreamController<bool> _authController = StreamController<bool>.broadcast();

  Stream<User?> get userStream => _userController.stream;
  Stream<bool> get authStream => _authController.stream;

  // Registration
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      // Check if user already exists
      final existingUser = await _db.getUserByEmail(request.email);
      if (existingUser != null) {
        throw AuthException('Email already registered');
      }

      final existingUsername = await _db.getUserByUsername(request.username);
      if (existingUsername != null) {
        throw AuthException('Username already taken');
      }

      // Create new user
      final user = User(
        id: _generateId(),
        username: request.username,
        email: request.email,
        firstName: request.firstName,
        lastName: request.lastName,
        phoneNumber: request.phoneNumber,
        role: UserRole.user,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _db.insertUser(user);

      // Create session
      final session = await _createSession(user.id);

      // Update current state
      await _setCurrentUser(user, session);

      return AuthResponse(
        user: user,
        session: session,
        message: 'Registration successful',
      );
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  // Login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      // Find user by username or email
      User? user = await _db.getUserByUsername(request.username);
      if (user == null) {
        user = await _db.getUserByEmail(request.username);
      }

      if (user == null) {
        throw AuthException('User not found');
      }

      if (user.status != UserStatus.active) {
        throw AuthException('Account is not active');
      }

      // Verify password (in a real app, use proper password hashing)
      // For demo purposes, we'll accept any password
      if (request.password.isEmpty) {
        throw AuthException('Invalid password');
      }

      // Update last login
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _db.updateUser(updatedUser);

      // Create session
      final session = await _createSession(user.id, deviceId: request.deviceId);

      // Update current state
      await _setCurrentUser(updatedUser, session);

      return AuthResponse(
        user: updatedUser,
        session: session,
        message: 'Login successful',
      );
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    if (_currentSession != null) {
      await _db.deleteAuthSession(_currentSession!.id);
    }

    await _clearCurrentUser();
  }

  // Refresh token
  Future<AuthSession> refreshToken(String refreshToken) async {
    try {
      // Find session by refresh token
      final sessions = await _db.getAllAuthSessions();
      final session = sessions.firstWhere(
        (s) => s.refreshToken == refreshToken && s.isValid,
        orElse: () => throw AuthException('Invalid refresh token'),
      );

      // Create new session
      final newSession = await _createSession(session.userId);
      
      // Delete old session
      await _db.deleteAuthSession(session.id);

      // Update current session
      _currentSession = newSession;
      _authController.add(true);

      return newSession;
    } catch (e) {
      throw AuthException('Token refresh failed: $e');
    }
  }

  // Password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        // Don't reveal if user exists or not
        return;
      }

      // Generate reset token
      final resetToken = _generateResetToken();
      
      // In a real app, send email with reset token
      print('Password reset token for $email: $resetToken');
      
      // Store reset token (in a real app, this would be in a separate table with expiry)
      await _db.setSetting('reset_token_$email', resetToken);
      await _db.setSetting('reset_token_time_$email', DateTime.now().toIso8601String());
    } catch (e) {
      throw AuthException('Password reset request failed: $e');
    }
  }

  Future<void> confirmPasswordReset(String email, String token, String newPassword) async {
    try {
      final storedToken = await _db.getSetting('reset_token_$email');
      final tokenTime = await _db.getSetting('reset_token_time_$email');

      if (storedToken != token) {
        throw AuthException('Invalid reset token');
      }

      final tokenDateTime = DateTime.parse(tokenTime!);
      if (DateTime.now().difference(tokenDateTime).inHours > 24) {
        throw AuthException('Reset token expired');
      }

      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw AuthException('User not found');
      }

      // Update password (in a real app, hash the password)
      // For demo purposes, we'll just log it
      print('Password updated for $email: $newPassword');

      // Clean up reset token
      await _db.setSetting('reset_token_$email', '');
      await _db.setSetting('reset_token_time_$email', '');

      // Invalidate all sessions for this user
      await _db.deleteAuthSessionsByUserId(user.id);
    } catch (e) {
      throw AuthException('Password reset failed: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    if (_currentUser == null) {
      throw AuthException('Not authenticated');
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        preferences: preferences,
      );

      await _db.updateUser(updatedUser);
      await _setCurrentUser(updatedUser, _currentSession);
    } catch (e) {
      throw AuthException('Profile update failed: $e');
    }
  }

  // Validate current session
  Future<bool> validateSession() async {
    if (_currentSession == null) return false;

    if (_currentSession!.isExpired) {
      await logout();
      return false;
    }

    // Check if session still exists in database
    final session = await _db.getAuthSession(_currentSession!.id);
    if (session == null || !session.isActive) {
      await logout();
      return false;
    }

    return true;
  }

  // Private methods
  Future<AuthSession> _createSession(String userId, {String? deviceId}) async {
    final session = AuthSession(
      id: _generateId(),
      userId: userId,
      token: _generateToken(),
      refreshToken: _generateToken(),
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)), // 7 days
      deviceId: deviceId,
      isActive: true,
    );

    await _db.insertAuthSession(session);
    return session;
  }

  Future<void> _setCurrentUser(User user, AuthSession? session) async {
    _currentUser = user;
    _currentSession = session;
    _userController.add(user);
    _authController.add(isAuthenticated);
  }

  Future<void> _clearCurrentUser() async {
    _currentUser = null;
    _currentSession = null;
    _userController.add(null);
    _authController.add(false);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + _randomString(8);
  }

  String _generateToken() {
    final bytes = List<int>.generate(32, (_) => Random().nextInt(256));
    return base64.encode(bytes);
  }

  String _generateResetToken() {
    return base64.encode(List<int>.generate(16, (_) => Random().nextInt(256)));
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Cleanup
  void dispose() {
    _userController.close();
    _authController.close();
  }
}

class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => message;
}
