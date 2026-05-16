import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import '../../core/models/auth_session.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  SharedPreferences? _prefs;
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = false;
  String _userName = '';
  User? _currentUser;

  AuthProvider();

  bool get isLoggedIn => _isLoggedIn;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String get userName => _userName;
  User? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  String get homeId =>
      isAdmin ? '' : _currentUser?.preferences?['homeId'] as String? ?? '';
  String get homeName =>
      isAdmin
          ? 'Admin Control Panel'
          : _currentUser?.preferences?['homeName'] as String? ?? 'Smart Home';

  Future<void> initialize() async {
    await _loadAuthState();

    final sessionToken = _prefs?.getString('sessionToken');
    if (sessionToken != null && sessionToken.isNotEmpty) {
      final restored = await _authService.restoreSession(sessionToken);
      if (!restored) {
        await _prefs?.remove('sessionToken');
      }
    } else {
      await _authService.validateSession();
    }

    _currentUser = _authService.currentUser;
    _isLoggedIn = _authService.isAuthenticated;
    if (_currentUser != null) {
      _userName = _currentUser!.username;
    }
    notifyListeners();
  }

  Future<void> _loadAuthState() async {
    _prefs = await SharedPreferences.getInstance();
    _isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
    _hasSeenOnboarding = _prefs?.getBool('hasSeenOnboarding') ?? false;
    _userName = _prefs?.getString('userName') ?? 'User';
    notifyListeners();
  }

  Future<void> login(String userName, String password) async {
    try {
      final response = await _authService.login(
        LoginRequest(username: userName, password: password),
      );

      _isLoggedIn = true;
      _userName = response.user.username;
      _currentUser = response.user;

      await _prefs?.setBool('isLoggedIn', true);
      await _prefs?.setString('userName', userName);
      await _prefs?.setString('sessionToken', response.session.token);
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _hasSeenOnboarding = true;
    _userName = '';
    _currentUser = null;

    await _prefs?.setBool('isLoggedIn', false);
    await _prefs?.setBool('hasSeenOnboarding', true);
    await _prefs?.remove('userName');
    await _prefs?.remove('sessionToken');
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await _prefs?.setBool('hasSeenOnboarding', true);
    notifyListeners();
  }

  Future<void> register(String userName, String email, String password,
      {String? firstName, String? lastName, String? phoneNumber}) async {
    try {
      final response = await _authService.register(
        RegisterRequest(
          username: userName,
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
        ),
      );

      _isLoggedIn = true;
      _userName = response.user.username;
      _currentUser = response.user;

      await _prefs?.setBool('isLoggedIn', true);
      await _prefs?.setString('userName', userName);
      await _prefs?.setString('sessionToken', response.session.token);
      notifyListeners();
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  void syncCurrentUser(User user) {
    _authService.syncCurrentUser(user);
    _currentUser = user;
    _userName = user.username;
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _authService.requestPasswordReset(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        preferences: preferences,
      );

      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        _userName = _currentUser!.username;
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }
}
