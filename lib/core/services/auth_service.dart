import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/user.dart';
import '../models/auth_session.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';
import '../utils/password_utils.dart';

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
  bool get isAuthenticated =>
      _currentUser != null &&
      _currentSession != null &&
      _currentSession!.isValid;

  // Stream controllers for auth state changes
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  final StreamController<bool> _authController =
      StreamController<bool>.broadcast();

  Stream<User?> get userStream => _userController.stream;
  Stream<bool> get authStream => _authController.stream;

  // Registration
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      AppLogger.info('Registration attempt for user: ${request.username}');

      // Validate input
      if (request.username.isEmpty || request.email.isEmpty) {
        throw AuthException('Username and email are required');
      }

      if (request.password.isEmpty) {
        throw AuthException('Password is required');
      }

      // Check password strength
      if (!PasswordUtils.isStrongPassword(request.password)) {
        throw AuthException(
          'Password must be at least 8 characters with uppercase, lowercase, and numbers',
        );
      }

      // Check if user already exists
      final existingUser = await _db.getUserByEmail(request.email);
      if (existingUser != null) {
        AppLogger.warning(
            'Registration failed: Email already registered: ${request.email}');
        throw AuthException('Email already registered');
      }

      final existingUsername = await _db.getUserByUsername(request.username);
      if (existingUsername != null) {
        AppLogger.warning(
            'Registration failed: Username taken: ${request.username}');
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

      // Hash and store password
      final passwordHash = PasswordUtils.hashPassword(request.password);
      await _db.setUserPassword(user.id, passwordHash);

      AppLogger.info('User registered successfully: ${user.username}');

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
      AppLogger.error('Registration failed', e);
      throw AuthException('Registration failed: $e');
    }
  }

  // Login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      AppLogger.info('Login attempt for user: ${request.username}');

      // Find user by username or email
      User? user = await _db.getUserByUsername(request.username);
      user ??= await _db.getUserByEmail(request.username);

      if (user == null) {
        AppLogger.warning('Login failed: User not found: ${request.username}');
        throw AuthException('Invalid username or password');
      }

      if (user.status != UserStatus.active) {
        AppLogger.warning('Login failed: Account not active: ${user.username}');
        throw AuthException('Account is not active');
      }

      // Get password hash and verify
      final passwordHash = await _db.getUserPasswordHash(user.id);
      if (passwordHash == null) {
        AppLogger.warning(
            'Login failed: No password set for user: ${user.username}');
        throw AuthException('Invalid username or password');
      }

      if (!PasswordUtils.verifyPassword(request.password, passwordHash)) {
        AppLogger.warning(
            'Login failed: Invalid password for user: ${user.username}');
        throw AuthException('Invalid username or password');
      }

      AppLogger.info('User logged in successfully: ${user.username}');

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
      AppLogger.error('Login failed', e);
      throw AuthException('Login failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    AppLogger.info('Logout for user: ${_currentUser?.username ?? "unknown"}');

    if (_currentSession != null) {
      await _db.deleteAuthSession(_currentSession!.id);
    }

    await _clearCurrentUser();
  }

  // Refresh token
  Future<AuthSession> refreshToken(String refreshToken) async {
    try {
      AppLogger.debug('Token refresh attempt');

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

      AppLogger.info(
          'Token refresh successful for user: ${_currentUser?.username ?? "unknown"}');

      return newSession;
    } catch (e) {
      AppLogger.error('Token refresh failed', e);
      throw AuthException('Token refresh failed: $e');
    }
  }

  // Password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      AppLogger.info('Password reset request for email: $email');

      final user = await _db.getUserByEmail(email);
      if (user == null) {
        // Don't reveal if user exists or not (security best practice)
        AppLogger.warning(
            'Password reset requested for non-existent email: $email');
        return;
      }

      // Generate reset token
      final resetToken = PasswordUtils.generateResetToken();
      final tokenHash = PasswordUtils.hashPassword(resetToken);

      // Store hashed token with 1-hour validity
      await _db.storePasswordResetToken(
          email, tokenHash, const Duration(hours: 1));

      // In a real app, send email with reset token
      AppLogger.info(
          'Password reset token generated for user: ${user.username}');
      // Email should contain: token value and instructions
      // Don't log the actual token!
    } catch (e) {
      AppLogger.error('Password reset request failed', e);
      throw AuthException('Password reset request failed: $e');
    }
  }

  Future<void> confirmPasswordReset(
      String email, String token, String newPassword) async {
    try {
      AppLogger.info('Password reset confirmation attempt for email: $email');

      // Validate new password strength
      if (!PasswordUtils.isStrongPassword(newPassword)) {
        throw AuthException(
          'Password must be at least 8 characters with uppercase, lowercase, and numbers',
        );
      }

      // Get and verify token
      final storedTokenHash = await _db.getPasswordResetToken(email);
      if (storedTokenHash == null) {
        AppLogger.warning(
            'Password reset failed: Invalid or expired token for: $email');
        throw AuthException('Invalid or expired reset token');
      }

      // Verify token (check if provided token hashes to stored hash)
      // Note: We need a simpler verification since we're using our custom hash
      // In production, use bcrypt or similar
      if (!PasswordUtils.verifyPassword(token, storedTokenHash)) {
        AppLogger.warning('Password reset failed: Invalid token for: $email');
        throw AuthException('Invalid reset token');
      }

      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw AuthException('User not found');
      }

      // Hash and store new password
      final newPasswordHash = PasswordUtils.hashPassword(newPassword);
      await _db.setUserPassword(user.id, newPasswordHash);

      AppLogger.info('Password reset successful for user: ${user.username}');

      // Clean up reset token
      await _db.deletePasswordResetToken(email);

      // Invalidate all sessions for this user (force re-login)
      await _db.deleteAuthSessionsByUserId(user.id);
    } catch (e) {
      AppLogger.error('Password reset failed', e);
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

  String _randomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
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
