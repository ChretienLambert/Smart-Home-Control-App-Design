import '../models/user.dart';
import '../config/smart_home_hardware.dart';
import '../services/database_service.dart';
import '../services/home_service.dart';
import '../services/logger_service.dart';
import '../utils/app_utils.dart';
import '../utils/password_utils.dart';

class DatabaseSeeder {
  static final DatabaseSeeder _instance = DatabaseSeeder._internal();
  factory DatabaseSeeder() => _instance;
  DatabaseSeeder._internal();

  final DatabaseService _db = DatabaseService();
  final HomeService _homeService = HomeService();
  final LoggerService _logger = LoggerService();

  static const Set<String> _coreUsernames = {'admin', 'john_doe'};

  Future<void> seedDatabase() async {
    _logger.info('Starting database seeding...');

    try {
      final existingUsers = await _db.getAllUsers();
      final hasOnlyCoreUsers = existingUsers.isNotEmpty &&
          existingUsers.every((user) => _coreUsernames.contains(user.username));

      if (!hasOnlyCoreUsers) {
        await _resetToCoreAccounts(existingUsers);
        return;
      }

      await _ensureCoreAccounts(existingUsers);
      _logger.info('Database already normalized for core accounts');
    } catch (e, stackTrace) {
      _logger.critical(
        'Database seeding failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _resetToCoreAccounts(List<User> existingUsers) async {
    _logger.warning('Resetting database to admin and john_doe only...');

    try {
      final authSessions = await _db.getAllAuthSessions();
      for (final session in authSessions) {
        await _db.deleteAuthSession(session.id);
      }

      await _db.clearAllData();

      for (final user in existingUsers) {
        await _db.deleteUser(user.id);
      }

      await _createCoreAccounts();
      _logger.info('Database reset to core accounts completed');
    } catch (e) {
      _logger.error('Failed to reset database to core accounts', error: e);
      rethrow;
    }
  }

  Future<void> _ensureCoreAccounts(List<User> existingUsers) async {
    final existingByUsername = {
      for (final user in existingUsers) user.username: user,
    };

    for (final username in _coreUsernames) {
      var user = existingByUsername[username];
      
      if (user == null) {
        final seed = _seedFor(username);
        user = User(
          id: AppUtils.generateId(),
          username: seed['username'] as String,
          email: seed['email'] as String,
          firstName: seed['firstName'] as String?,
          lastName: seed['lastName'] as String?,
          phoneNumber: seed['phoneNumber'] as String?,
          role: seed['role'] as UserRole,
          status: UserStatus.active,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: {
            'theme': 'light',
            'notifications': true,
            'autoBackup': true,
            'language': 'en',
          },
          deviceIds: const [],
          roomIds: const [],
        );
        await _db.insertUser(user);
        await _db.setUserPassword(
          user.id,
          PasswordUtils.hashPassword(seed['password'] as String),
        );
      }

      // Ensure hardware devices exist for this user
      if (user.role != UserRole.admin) {
        final hardwareDevices = await _db.getAllDevices();
        final userOwnedHardware = hardwareDevices.where((d) => 
          user!.deviceIds!.contains(d.id) && SmartHomeHardware.isArduinoWired(d)).toList();
        
        if (userOwnedHardware.length < SmartHomeHardware.arduinoWiredDeviceIds.length) {
          _logger.warning('Hardware devices incomplete for user: ${user.username}. Syncing...');
          await _homeService.ensureHomeForUser(user);
        }
      }
    }
  }

  Future<void> _createCoreAccounts() async {
    for (final username in _coreUsernames) {
      final seed = _seedFor(username);
      final user = User(
        id: AppUtils.generateId(),
        username: seed['username'] as String,
        email: seed['email'] as String,
        firstName: seed['firstName'] as String?,
        lastName: seed['lastName'] as String?,
        phoneNumber: seed['phoneNumber'] as String?,
        role: seed['role'] as UserRole,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: {
          'theme': 'light',
          'notifications': true,
          'autoBackup': true,
          'language': 'en',
        },
        deviceIds: const [],
        roomIds: const [],
      );

      await _db.insertUser(user);
      await _db.setUserPassword(
        user.id,
        PasswordUtils.hashPassword(seed['password'] as String),
      );

      // Ensure home template is created for this user
      await _homeService.ensureHomeForUser(user);

      _logger.info(
        'Created seed user ${user.username}',
        context: {'email': user.email},
      );
    }
  }

  Map<String, Object?> _seedFor(String username) {
    switch (username) {
      case 'admin':
        return {
          'username': 'admin',
          'email': 'admin@smarthome.com',
          'password': 'admin123',
          'firstName': 'System',
          'lastName': 'Administrator',
          'role': UserRole.admin,
          'phoneNumber': '+1234567890',
        };
      case 'john_doe':
      default:
        return {
          'username': 'john_doe',
          'email': 'john@smarthome.com',
          'password': 'user123',
          'firstName': 'John',
          'lastName': 'Doe',
          'role': UserRole.user,
          'phoneNumber': '+1234567891',
        };
    }
  }

  Future<void> clearDatabase() async {
    _logger.warning('Clearing database...');

    try {
      final sessions = await _db.getAllAuthSessions();
      for (final session in sessions) {
        await _db.deleteAuthSession(session.id);
      }

      final users = await _db.getAllUsers();
      for (final user in users) {
        await _db.deleteUser(user.id);
      }

      await _db.clearAllData();
      _logger.info('Database cleared successfully');
    } catch (e) {
      _logger.error('Failed to clear database', error: e);
    }
  }

  Future<bool> userExists(String username) async {
    final user = await _db.getUserByUsername(username);
    return user != null;
  }
}
