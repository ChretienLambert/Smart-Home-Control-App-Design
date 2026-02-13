import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:math';

Future<void> main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('Creating test users...');
  
  try {
    final dbPath = join(await getDatabasesPath(), 'smart_home.db');
    final db = await openDatabase(dbPath);
    
    final testUsers = [
      {
        'id': _generateId(),
        'username': 'admin',
        'email': 'admin@smarthome.com',
        'first_name': 'Admin',
        'last_name': 'User',
        'phone_number': '+1234567890',
        'role': 'admin',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
      },
      {
        'id': _generateId(),
        'username': 'john_doe',
        'email': 'john@example.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'phone_number': '+1234567891',
        'role': 'user',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
      },
      {
        'id': _generateId(),
        'username': 'jane_smith',
        'email': 'jane@example.com',
        'first_name': 'Jane',
        'last_name': 'Smith',
        'phone_number': '+1234567892',
        'role': 'user',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
      },
    ];
    
    for (final user in testUsers) {
      await db.insert('users', user);
      print('✅ Created user: ${user['username']} (${user['email']})');
    }
    
    await db.close();
    
    print('\n📋 Test Login Credentials:');
    print('Username: admin, Password: any (demo accepts any non-empty password)');
    print('Username: john_doe, Password: any (demo accepts any non-empty password)');
    print('Username: jane_smith, Password: any (demo accepts any non-empty password)');
    
    print('\n🔧 Testing Commands (Dart scripts):');
    print('dart run test_login.dart admin');
    print('dart run test_login.dart john_doe');
    print('dart run test_login.dart jane_smith');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

String _generateId() {
  return DateTime.now().millisecondsSinceEpoch.toString() + _randomString(8);
}

String _randomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
}
