import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/services/database_service.dart';
import '../../core/models/user.dart';

Future<void> main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('Testing database service fixes...');

  try {
    final dbService = DatabaseService();

    // Create a test user
    final testUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: 'test_user',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      phoneNumber: '+1234567890',
      role: UserRole.user,
      status: UserStatus.active,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: {
        'theme': 'dark',
        'notifications': false,
      },
      deviceIds: [],
      roomIds: [],
    );

    print('📝 Inserting test user...');
    await dbService.insertUser(testUser);

    print('🔍 Retrieving user by username...');
    final retrievedUser = await dbService.getUserByUsername('test_user');

    if (retrievedUser != null) {
      print('✅ User retrieved successfully!');
      print('   Username: ${retrievedUser.username}');
      print('   Email: ${retrievedUser.email}');
      print('   Preferences: ${retrievedUser.preferences}');
      print('   Theme: ${retrievedUser.preferences?['theme']}');
    } else {
      print('❌ Failed to retrieve user');
    }

    print('🗑️  Cleaning up test user...');
    await dbService.deleteUser(testUser.id);

    print('✅ Database service test completed successfully!');
  } catch (e) {
    print('❌ Test failed: $e');
    exit(1);
  }
}
