import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:crypto/crypto.dart';
import 'app_utils.dart';

class PasswordUtils {
  // Simple PBKDF2-like implementation using SHA256
  // For production, use a package like 'pointycastle' or 'bcrypt'
  static const int _iterations = 10000;

  static String hashPassword(String password) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt =
        saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return _pbkdf2(password, salt);
  }

  static bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) {
        log('Invalid hash format', name: 'PasswordUtils', level: 900);
        return false;
      }

      final salt = parts[0];
      final storedHash = parts[1];

      final computedHash = _pbkdf2(password, salt);
      return computedHash.split(':')[1] == storedHash;
    } catch (e) {
      log('Password verification error: $e',
          name: 'PasswordUtils', level: 1000);
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

  static String generateResetToken() => AppUtils.generateSecureToken();
}
