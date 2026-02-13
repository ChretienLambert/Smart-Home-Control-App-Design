import 'dart:convert';
import 'dart:math';
import '../models/user.dart';
import '../models/auth_session.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';

class DatabaseSeeder {
  static final DatabaseSeeder _instance = DatabaseSeeder._internal();
  factory DatabaseSeeder() => _instance;
  DatabaseSeeder._internal();

  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  final LoggerService _logger = LoggerService();

  Future<void> seedDatabase() async {
    _logger.info('Starting database seeding...');

    try {
      // Check if users already exist
      final existingUsers = await _db.getAllUsers();
      if (existingUsers.isNotEmpty) {
        _logger.info('Database already has ${existingUsers.length} users',
            context: {
              'userCount': existingUsers.length,
              'users': existingUsers.map((u) => u.username).toList(),
            });
        return;
      }

      // Create dummy users
      await _createDummyUsers();

      _logger.info('Database seeding completed successfully');
    } catch (e, stackTrace) {
      _logger.critical('Database seeding failed',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _createDummyUsers() async {
    final dummyUsers = [
      {
        'username': 'admin',
        'email': 'admin@smarthome.com',
        'password': 'admin123',
        'firstName': 'System',
        'lastName': 'Administrator',
        'role': UserRole.admin,
        'phoneNumber': '+1234567890',
      },
      {
        'username': 'john_doe',
        'email': 'john@smarthome.com',
        'password': 'user123',
        'firstName': 'John',
        'lastName': 'Doe',
        'role': UserRole.user,
        'phoneNumber': '+1234567891',
      },
      {
        'username': 'jane_smith',
        'email': 'jane@smarthome.com',
        'password': 'user123',
        'firstName': 'Jane',
        'lastName': 'Smith',
        'role': UserRole.user,
        'phoneNumber': '+1234567892',
      },
      {
        'username': 'guest_user',
        'email': 'guest@smarthome.com',
        'password': 'guest123',
        'firstName': 'Guest',
        'lastName': 'User',
        'role': UserRole.guest,
        'phoneNumber': '+1234567893',
      },
    ];

    for (final userData in dummyUsers) {
      try {
        final user = User(
          id: _generateId(),
          username: userData['username'] as String,
          email: userData['email'] as String,
          firstName: userData['firstName'] as String?,
          lastName: userData['lastName'] as String?,
          phoneNumber: userData['phoneNumber'] as String?,
          role: userData['role'] as UserRole,
          status: UserStatus.active,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: {
            'theme': 'light',
            'notifications': true,
            'autoBackup': true,
            'language': 'en',
          },
          deviceIds: [],
          roomIds: [],
        );

        await _db.insertUser(user);
        print('👤 Created user: ${user.username} (${user.email})');

        // Create a session for the user (in a real app, this would be done during login)
        final session = AuthSession(
          id: _generateId(),
          userId: user.id,
          token: _generateToken(),
          refreshToken: _generateToken(),
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          deviceId: 'demo_device',
          ipAddress: '127.0.0.1',
          userAgent: 'Smart Home App Demo',
          isActive: true,
        );

        await _db.insertAuthSession(session);
      } catch (e) {
        print('❌ Failed to create user ${userData['username']}: $e');
      }
    }

    print('🎉 Created ${dummyUsers.length} dummy users successfully');
    print('\n📋 Login Credentials:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (final userData in dummyUsers) {
      print('👤 ${userData['username']}');
      print('   📧 ${userData['email']}');
      print('   🔑 ${userData['password']}');
      print('   🎭 ${userData['role']}');
      print('');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  Future<void> createSampleRooms() async {
    final sampleRooms = [
      {
        'id': 'room_1',
        'name': 'Living Room',
        'description': 'Main living area with entertainment system',
      },
      {
        'id': 'room_2',
        'name': 'Master Bedroom',
        'description': 'Primary bedroom with climate control',
      },
      {
        'id': 'room_3',
        'name': 'Kitchen',
        'description': 'Smart kitchen with appliances',
      },
      {
        'id': 'room_4',
        'name': 'Garage',
        'description': 'Smart garage with door control',
      },
    ];

    for (final roomData in sampleRooms) {
      // This would require creating Room model and database methods
      print('🏠 Would create room: ${roomData['name']}');
    }
  }

  Future<void> createSampleDevices() async {
    final sampleDevices = [
      {
        'id': 'device_1',
        'name': 'Living Room Light',
        'roomId': 'room_1',
        'type': 'Smart Light',
        'status': 'online',
        'isOn': true,
      },
      {
        'id': 'device_2',
        'name': 'Thermostat',
        'roomId': 'room_2',
        'type': 'Climate Control',
        'status': 'online',
        'isOn': true,
      },
      {
        'id': 'device_3',
        'name': 'Smart Lock',
        'roomId': 'room_4',
        'type': 'Security',
        'status': 'online',
        'isOn': true,
      },
    ];

    for (final deviceData in sampleDevices) {
      // This would require creating Device model and database methods
      print('🔌 Would create device: ${deviceData['name']}');
    }
  }

  Future<void> clearDatabase() async {
    print('🗑️  Clearing database...');

    try {
      // Delete all sessions
      final sessions = await _db.getAllAuthSessions();
      for (final session in sessions) {
        await _db.deleteAuthSession(session.id);
      }

      // Delete all users
      final users = await _db.getAllUsers();
      for (final user in users) {
        await _db.deleteUser(user.id);
      }

      print('✅ Database cleared successfully');
    } catch (e) {
      print('❌ Failed to clear database: $e');
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

  // Utility method to get user credentials for testing
  Map<String, String> getTestCredentials() {
    return {
      'admin': 'admin123',
      'john_doe': 'user123',
      'jane_smith': 'user123',
      'guest_user': 'guest123',
    };
  }

  // Utility method to check if user exists
  Future<bool> userExists(String username) async {
    final user = await _db.getUserByUsername(username);
    return user != null;
  }

  // Utility method to get user by credentials (for testing)
  Future<User?> getUserByCredentials(String username, String password) async {
    final user = await _db.getUserByUsername(username);
    if (user != null && user.status == UserStatus.active) {
      // In a real app, you would verify the password hash
      // For demo purposes, we'll accept the password if user exists
      return user;
    }
    return null;
  }
}
