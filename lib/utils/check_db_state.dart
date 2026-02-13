import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

Future<void> main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('Checking database state...');
  
  try {
    final dbPath = join(await getDatabasesPath(), 'smart_home.db');
    final db = await openDatabase(dbPath);
    
    // Check users
    final users = await db.query('users');
    print('📊 Users in database: ${users.length}');
    for (final user in users) {
      print('  👤 ${user['username']} (${user['email']}) - ${user['role']}');
    }
    
    // Check auth sessions
    final sessions = await db.query('auth_sessions');
    print('📊 Active sessions: ${sessions.length}');
    
    await db.close();
    
    if (users.isEmpty) {
      print('\n⚠️  No users found. Bypass button should create admin user.');
    } else {
      print('\n✅ Users exist. Bypass button should login with existing admin user.');
    }
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
