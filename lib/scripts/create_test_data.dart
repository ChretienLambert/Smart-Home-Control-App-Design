import 'dart:io';
import '../../core/services/auth_service.dart';
import '../../core/models/auth_session.dart';

Future<void> main() async {
  print('Creating test users and data...');

  try {
    final authService = AuthService();

    // Create test users
    final testUsers = [
      {
        'username': 'admin',
        'email': 'admin@smarthome.com',
        'password': 'admin123',
        'firstName': 'Admin',
        'lastName': 'User',
      },
      {
        'username': 'john_doe',
        'email': 'john@example.com',
        'password': 'password123',
        'firstName': 'John',
        'lastName': 'Doe',
      },
      {
        'username': 'jane_smith',
        'email': 'jane@example.com',
        'password': 'password123',
        'firstName': 'Jane',
        'lastName': 'Smith',
      },
    ];

    for (final userData in testUsers) {
      try {
        final response = await authService.register(RegisterRequest(
          username: userData['username']!,
          email: userData['email']!,
          password: userData['password']!,
          firstName: userData['firstName'],
          lastName: userData['lastName'],
        ));
        print('✅ Created user: ${userData['username']} (${userData['email']})');
        print('   Token: ${response.session.token}');
      } catch (e) {
        print('❌ Failed to create user ${userData['username']}: $e');
      }
    }

    print('\n📋 Test Login Credentials:');
    print('Username: admin, Password: admin123');
    print('Username: john_doe, Password: password123');
    print('Username: jane_smith, Password: password123');

    authService.dispose();
  } catch (e) {
    print('❌ Error creating test data: $e');
    exit(1);
  }
}
