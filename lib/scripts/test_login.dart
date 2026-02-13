import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run test_login.dart <username>');
    exit(1);
  }

  final username = args.first;

  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('Testing login for user: $username');

  try {
    final dbPath = join(await getDatabasesPath(), 'smart_home.db');
    final db = await openDatabase(dbPath);

    // Find user by username
    final users = await db.query(
      'users',
      where: 'username = ? OR email = ?',
      whereArgs: [username, username],
    );

    if (users.isEmpty) {
      print('❌ User not found: $username');
      await db.close();
      exit(1);
    }

    final user = users.first;
    print('✅ User found: ${user['username']} (${user['email']})');
    print('   Role: ${user['role']}');
    print('   Status: ${user['status']}');

    // Check if user is active
    if (user['status'] != 'active') {
      print('❌ Account is not active');
      await db.close();
      exit(1);
    }

    // Simulate login (in real app, would verify password)
    print('✅ Login successful!');

    // Create auth session
    final sessionId = _generateId();
    final token = _generateToken();
    final refreshToken = _generateToken();
    final now = DateTime.now().toIso8601String();
    final expiresAt = DateTime.now().add(const Duration(days: 7)).toIso8601String();

    final session = {
      'id': sessionId,
      'user_id': user['id'],
      'token': token,
      'refresh_token': refreshToken,
      'created_at': now,
      'expires_at': expiresAt,
      'device_id': 'test_device',
      'ip_address': '127.0.0.1',
      'user_agent': 'test_script',
      'is_active': 1,
    };

    await db.insert('auth_sessions', session);

    print('🎫 Session created:');
    print('   Session ID: $sessionId');
    print('   Token: $token');
    print('   Refresh Token: $refreshToken');
    print('   Expires: $expiresAt');

    await db.close();
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
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
