import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = false;
  String _userName = '';

  AuthProvider();

  bool get isLoggedIn => _isLoggedIn;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String get userName => _userName;

  Future<void> initialize() async {
    await _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _prefs = await SharedPreferences.getInstance();
    _isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
    _hasSeenOnboarding = _prefs?.getBool('hasSeenOnboarding') ?? false;
    _userName = _prefs?.getString('userName') ?? 'User';
    notifyListeners();
  }

  Future<void> login(String userName) async {
    _isLoggedIn = true;
    _userName = userName;
    await _prefs?.setBool('isLoggedIn', true);
    await _prefs?.setString('userName', userName);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _hasSeenOnboarding = true;
    await _prefs?.setBool('isLoggedIn', false);
    await _prefs?.setBool('hasSeenOnboarding', true);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await _prefs?.setBool('hasSeenOnboarding', true);
    notifyListeners();
  }

  Future<void> register(String userName, String email, String password) async {
    // Simulate registration - in real app, this would call an API
    await Future.delayed(const Duration(seconds: 1));
    await login(userName);
  }

  Future<void> forgotPassword(String email) async {
    // Simulate password reset - in real app, this would call an API
    await Future.delayed(const Duration(seconds: 1));
  }
}
