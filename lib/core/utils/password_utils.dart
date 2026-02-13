import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'logger.dart';

class PasswordUtils {
  // Simple PBKDF2-like implementation using SHA256
  // For production, use a package like 'pointycastle' or 'bcrypt'
  static const int _iterations = 10000;
  static const int _saltLength = 32;

  static String hashPassword(String password) {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final salt = sha256
        .convert(utf8.encode(random))
        .toString()
        .substring(0, _saltLength);
    return _pbkdf2(password, salt);
  }

  static bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) {
        AppLogger.warning('Invalid hash format');
        return false;
      }

      final salt = parts[0];
      final storedHash = parts[1];

      final computedHash = _pbkdf2(password, salt);
      return computedHash.split(':')[1] == storedHash;
    } catch (e) {
      AppLogger.error('Password verification error', e);
      return false;
    }
  }

  static String _pbkdf2(String password, String salt) {
    var hash = password;
    for (int i = 0; i < _iterations; i++) {
      hash = sha256.convert(utf8.encode(hash + salt)).toString();
    }
    return '$salt:$hash';
  }

  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    return true;
  }

  static String generateResetToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final token = sha256.convert(utf8.encode(random)).toString();
    return token;
  }
}
