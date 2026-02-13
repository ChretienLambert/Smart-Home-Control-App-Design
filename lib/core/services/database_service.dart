import 'dart:async';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/device.dart';
import '../models/room.dart';
import '../models/automation_rule.dart';
import '../models/alert.dart';
import '../models/user.dart';
import '../models/auth_session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    // Initialize FFI database factory for Windows
    databaseFactory = databaseFactoryFfi;
  }

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'smart_home.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        firstName TEXT,
        lastName TEXT,
        phoneNumber TEXT,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastLoginAt TEXT NOT NULL,
        profileImageUrl TEXT,
        preferences TEXT,
        deviceIds TEXT,
        roomIds TEXT
      )
    ''');

    // Create user credentials table for password storage
    await db.execute('''
      CREATE TABLE user_credentials (
        id TEXT PRIMARY KEY,
        user_id TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create auth_sessions table
    await db.execute('''
      CREATE TABLE auth_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token TEXT UNIQUE NOT NULL,
        refresh_token TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        device_id TEXT,
        ip_address TEXT,
        user_agent TEXT,
        is_active INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create rooms table
    await db.execute('''
      CREATE TABLE rooms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        device_ids TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create devices table
    await db.execute('''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        room_id TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        is_on INTEGER NOT NULL,
        properties TEXT,
        last_updated TEXT NOT NULL,
        mqtt_topic TEXT,
        FOREIGN KEY (room_id) REFERENCES rooms (id)
      )
    ''');

    // Create automation rules table
    await db.execute('''
      CREATE TABLE automation_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        conditions TEXT NOT NULL,
        actions TEXT NOT NULL,
        is_enabled INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_triggered TEXT
      )
    ''');

    // Create alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        type TEXT NOT NULL,
        device_id TEXT,
        rule_id TEXT,
        timestamp TEXT NOT NULL,
        is_read INTEGER NOT NULL,
        is_acknowledged INTEGER NOT NULL,
        FOREIGN KEY (device_id) REFERENCES devices (id),
        FOREIGN KEY (rule_id) REFERENCES automation_rules (id)
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute(
        'CREATE INDEX idx_auth_sessions_user_id ON auth_sessions(user_id)');
    await db.execute(
        'CREATE INDEX idx_auth_sessions_token ON auth_sessions(token)');
    await db.execute('CREATE INDEX idx_devices_room_id ON devices(room_id)');
    await db.execute('CREATE INDEX idx_devices_type ON devices(type)');
    await db.execute('CREATE INDEX idx_alerts_timestamp ON alerts(timestamp)');
    await db.execute('CREATE INDEX idx_alerts_is_read ON alerts(is_read)');
    await db.execute(
        'CREATE INDEX idx_automation_rules_enabled ON automation_rules(is_enabled)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop all tables to ensure clean schema update
      await db.execute('DROP TABLE IF EXISTS settings');
      await db.execute('DROP TABLE IF EXISTS alerts');
      await db.execute('DROP TABLE IF EXISTS automation_rules');
      await db.execute('DROP TABLE IF EXISTS devices');
      await db.execute('DROP TABLE IF EXISTS rooms');
      await db.execute('DROP TABLE IF EXISTS auth_sessions');
      await db.execute('DROP TABLE IF EXISTS users');

      await _onCreate(db, newVersion);
    }
  }

  // User operations
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);

      // Parse preferences if it's a JSON string
      if (mutableMap['preferences'] is String) {
        try {
          mutableMap['preferences'] =
              jsonDecode(mutableMap['preferences'] as String);
        } catch (e) {
          mutableMap['preferences'] = {};
        }
      }

      // Parse deviceIds if it's a JSON string
      if (mutableMap['deviceIds'] is String) {
        try {
          final List<dynamic> deviceIds =
              jsonDecode(mutableMap['deviceIds'] as String);
          mutableMap['deviceIds'] = deviceIds.cast<String>();
        } catch (e) {
          mutableMap['deviceIds'] = [];
        }
      }

      // Parse roomIds if it's a JSON string
      if (mutableMap['roomIds'] is String) {
        try {
          final List<dynamic> roomIds =
              jsonDecode(mutableMap['roomIds'] as String);
          mutableMap['roomIds'] = roomIds.cast<String>();
        } catch (e) {
          mutableMap['roomIds'] = [];
        }
      }

      return User.fromJson(mutableMap);
    }).toList();
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final userData = Map<String, dynamic>.from(maps.first);

      // Parse preferences if it's a JSON string
      if (userData['preferences'] is String) {
        try {
          userData['preferences'] =
              jsonDecode(userData['preferences'] as String);
        } catch (e) {
          userData['preferences'] = {};
        }
      }

      if (userData['deviceIds'] is String) {
        try {
          final List<dynamic> deviceIds =
              jsonDecode(userData['deviceIds'] as String);
          userData['deviceIds'] = deviceIds.cast<String>();
        } catch (e) {
          userData['deviceIds'] = [];
        }
      }

      if (userData['roomIds'] is String) {
        try {
          final List<dynamic> roomIds =
              jsonDecode(userData['roomIds'] as String);
          userData['roomIds'] = roomIds.cast<String>();
        } catch (e) {
          userData['roomIds'] = [];
        }
      }

      return User.fromJson(userData);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      final userData = Map<String, dynamic>.from(maps.first);

      if (userData['preferences'] is String) {
        try {
          userData['preferences'] =
              jsonDecode(userData['preferences'] as String);
        } catch (e) {
          userData['preferences'] = {};
        }
      }

      if (userData['deviceIds'] is String) {
        try {
          final List<dynamic> deviceIds =
              jsonDecode(userData['deviceIds'] as String);
          userData['deviceIds'] = deviceIds.cast<String>();
        } catch (e) {
          userData['deviceIds'] = [];
        }
      }

      if (userData['roomIds'] is String) {
        try {
          final List<dynamic> roomIds =
              jsonDecode(userData['roomIds'] as String);
          userData['roomIds'] = roomIds.cast<String>();
        } catch (e) {
          userData['roomIds'] = [];
        }
      }

      return User.fromJson(userData);
    }
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      final userData = Map<String, dynamic>.from(maps.first);

      if (userData['preferences'] is String) {
        try {
          userData['preferences'] =
              jsonDecode(userData['preferences'] as String);
        } catch (e) {
          userData['preferences'] = {};
        }
      }

      if (userData['deviceIds'] is String) {
        try {
          final List<dynamic> deviceIds =
              jsonDecode(userData['deviceIds'] as String);
          userData['deviceIds'] = deviceIds.cast<String>();
        } catch (e) {
          userData['deviceIds'] = [];
        }
      }

      if (userData['roomIds'] is String) {
        try {
          final List<dynamic> roomIds =
              jsonDecode(userData['roomIds'] as String);
          userData['roomIds'] = roomIds.cast<String>();
        } catch (e) {
          userData['roomIds'] = [];
        }
      }

      return User.fromJson(userData);
    }
    return null;
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    final userData = <String, dynamic>{
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'phoneNumber': user.phoneNumber,
      'role': user.role.toString().split('.').last,
      'status': user.status.toString().split('.').last,
      'createdAt': user.createdAt.toIso8601String(),
      'lastLoginAt': user.lastLoginAt.toIso8601String(),
      'profileImageUrl': user.profileImageUrl,
      'preferences':
          user.preferences != null ? jsonEncode(user.preferences) : null,
      'deviceIds': user.deviceIds != null ? jsonEncode(user.deviceIds) : null,
      'roomIds': user.roomIds != null ? jsonEncode(user.roomIds) : null,
    };

    await db.insert(
      'users',
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    final userData = <String, dynamic>{
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'phoneNumber': user.phoneNumber,
      'role': user.role.toString().split('.').last,
      'status': user.status.toString().split('.').last,
      'createdAt': user.createdAt.toIso8601String(),
      'lastLoginAt': user.lastLoginAt.toIso8601String(),
      'profileImageUrl': user.profileImageUrl,
      'preferences':
          user.preferences != null ? jsonEncode(user.preferences) : null,
      'deviceIds': user.deviceIds != null ? jsonEncode(user.deviceIds) : null,
      'roomIds': user.roomIds != null ? jsonEncode(user.roomIds) : null,
    };

    await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Auth session operations
  Future<List<AuthSession>> getAllAuthSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('auth_sessions');
    return maps.map((map) => _deserializeAuthSession(map)).toList();
  }

  Future<AuthSession?> getAuthSession(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _deserializeAuthSession(maps.first);
    }
    return null;
  }

  Future<AuthSession?> getAuthSessionByToken(String token) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_sessions',
      where: 'token = ?',
      whereArgs: [token],
    );
    if (maps.isNotEmpty) {
      return _deserializeAuthSession(maps.first);
    }
    return null;
  }

  Future<List<AuthSession>> getAuthSessionsByUserId(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _deserializeAuthSession(map)).toList();
  }

  AuthSession _deserializeAuthSession(Map<String, dynamic> map) {
    final m = Map<String, dynamic>.from(map);

    final converted = <String, dynamic>{
      'id': m['id'],
      'userId': m['user_id'],
      'token': m['token'],
      'refreshToken': m['refresh_token'],
      'createdAt': m['created_at'],
      'expiresAt': m['expires_at'],
      'deviceId': m['device_id'],
      'ipAddress': m['ip_address'],
      'userAgent': m['user_agent'],
      'isActive':
          m['is_active'] is int ? (m['is_active'] == 1) : (m['is_active'] == true),
    };

    return AuthSession.fromJson(converted);
  }

  Future<void> insertAuthSession(AuthSession session) async {
    final db = await database;
    final data = {
      'id': session.id,
      'user_id': session.userId,
      'token': session.token,
      'refresh_token': session.refreshToken,
      'created_at': session.createdAt.toIso8601String(),
      'expires_at': session.expiresAt.toIso8601String(),
      'device_id': session.deviceId,
      'ip_address': session.ipAddress,
      'user_agent': session.userAgent,
      'is_active': session.isActive ? 1 : 0,
    };

    await db.insert(
      'auth_sessions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAuthSession(AuthSession session) async {
    final db = await database;
    final data = {
      'id': session.id,
      'user_id': session.userId,
      'token': session.token,
      'refresh_token': session.refreshToken,
      'created_at': session.createdAt.toIso8601String(),
      'expires_at': session.expiresAt.toIso8601String(),
      'device_id': session.deviceId,
      'ip_address': session.ipAddress,
      'user_agent': session.userAgent,
      'is_active': session.isActive ? 1 : 0,
    };

    await db.update(
      'auth_sessions',
      data,
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteAuthSession(String id) async {
    final db = await database;
    await db.delete(
      'auth_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAuthSessionsByUserId(String userId) async {
    final db = await database;
    await db.delete(
      'auth_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteExpiredSessions() async {
    final db = await database;
    await db.delete(
      'auth_sessions',
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  // Room operations
  Future<List<Room>> getAllRooms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('rooms');
    return maps.map((map) {
      return _deserializeRoom(map);
    }).toList();
  }

  Future<Room?> getRoom(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _deserializeRoom(maps.first);
    }
    return null;
  }

  Room _deserializeRoom(Map<String, dynamic> map) {
    final mutableMap = Map<String, dynamic>.from(map);

    // Convert snake_case to camelCase
    if (mutableMap.containsKey('device_ids')) {
      final value = mutableMap.remove('device_ids');
      if (value is String) {
        try {
          final List<dynamic> deviceIds = jsonDecode(value);
          mutableMap['deviceIds'] = deviceIds.cast<String>();
        } catch (e) {
          mutableMap['deviceIds'] = [];
        }
      } else {
        mutableMap['deviceIds'] = value ?? [];
      }
    }

    if (mutableMap.containsKey('created_at')) {
      mutableMap['createdAt'] = mutableMap.remove('created_at');
    }

    if (mutableMap.containsKey('updated_at')) {
      mutableMap['lastUpdated'] = mutableMap.remove('updated_at');
    }

    return Room.fromJson(mutableMap);
  }

  Future<void> insertRoom(Room room) async {
    final db = await database;
    final data = {
      'id': room.id,
      'name': room.name,
      'description': room.description,
      'device_ids': jsonEncode(room.deviceIds),
      'created_at': room.createdAt.toIso8601String(),
      'updated_at': room.lastUpdated.toIso8601String(),
    };

    await db.insert(
      'rooms',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRoom(Room room) async {
    final db = await database;
    final data = {
      'id': room.id,
      'name': room.name,
      'description': room.description,
      'device_ids': jsonEncode(room.deviceIds),
      'created_at': room.createdAt.toIso8601String(),
      'updated_at': room.lastUpdated.toIso8601String(),
    };

    await db.update(
      'rooms',
      data,
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  Future<void> deleteRoom(String id) async {
    final db = await database;
    await db.delete(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Device operations
  Future<List<Device>> getAllDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('devices');
    return maps.map((map) {
      return _deserializeDevice(map);
    }).toList();
  }

  Future<List<Device>> getDevicesByRoom(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
    return maps.map((map) {
      return _deserializeDevice(map);
    }).toList();
  }

  Future<Device?> getDevice(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _deserializeDevice(maps.first);
    }
    return null;
  }

  Device _deserializeDevice(Map<String, dynamic> map) {
    final mutableMap = Map<String, dynamic>.from(map);

    // Convert snake_case to camelCase
    if (mutableMap.containsKey('room_id')) {
      mutableMap['roomId'] = mutableMap.remove('room_id');
    }

    if (mutableMap.containsKey('last_updated')) {
      mutableMap['lastUpdated'] = mutableMap.remove('last_updated');
    }

    if (mutableMap.containsKey('mqtt_topic')) {
      mutableMap['mqttTopic'] = mutableMap.remove('mqtt_topic');
    }

    // Handle is_on as boolean
    if (mutableMap.containsKey('is_on') && mutableMap['is_on'] is int) {
      mutableMap['isOn'] = mutableMap.remove('is_on') == 1;
    } else if (mutableMap.containsKey('is_on')) {
      mutableMap['isOn'] = mutableMap.remove('is_on');
    }

    // Parse properties if it's a JSON string
    if (mutableMap['properties'] is String) {
      try {
        mutableMap['properties'] =
            jsonDecode(mutableMap['properties'] as String);
      } catch (e) {
        mutableMap['properties'] = {};
      }
    }

    return Device.fromJson(mutableMap);
  }

  Future<void> insertDevice(Device device) async {
    final db = await database;
    await db.insert(
      'devices',
      {
        'id': device.id,
        'name': device.name,
        'room_id': device.roomId,
        'type': device.type.toString().split('.').last,
        'status': device.status.toString().split('.').last,
        'is_on': device.isOn ? 1 : 0,
        'properties':
            device.properties != null ? jsonEncode(device.properties) : null,
        'last_updated': device.lastUpdated.toIso8601String(),
        'mqtt_topic': device.mqttTopic,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDevice(Device device) async {
    final db = await database;
    await db.update(
      'devices',
      {
        'id': device.id,
        'name': device.name,
        'room_id': device.roomId,
        'type': device.type.toString().split('.').last,
        'status': device.status.toString().split('.').last,
        'is_on': device.isOn ? 1 : 0,
        'properties':
            device.properties != null ? jsonEncode(device.properties) : null,
        'last_updated': device.lastUpdated.toIso8601String(),
        'mqtt_topic': device.mqttTopic,
      },
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  Future<void> deleteDevice(String id) async {
    final db = await database;
    await db.delete(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Automation rule operations
  Future<List<AutomationRule>> getAllAutomationRules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('automation_rules');
    return maps.map((map) {
      return _deserializeAutomationRule(map);
    }).toList();
  }

  Future<AutomationRule?> getAutomationRule(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _deserializeAutomationRule(maps.first);
    }
    return null;
  }

  AutomationRule _deserializeAutomationRule(Map<String, dynamic> map) {
    final mutableMap = Map<String, dynamic>.from(map);

    // Convert snake_case to camelCase
    if (mutableMap.containsKey('created_at')) {
      mutableMap['createdAt'] = mutableMap.remove('created_at');
    }

    if (mutableMap.containsKey('updated_at')) {
      mutableMap['lastUpdated'] = mutableMap.remove('updated_at');
    }

    if (mutableMap.containsKey('last_triggered')) {
      mutableMap['lastTriggered'] = mutableMap.remove('last_triggered');
    }

    // Handle is_enabled as boolean
    if (mutableMap.containsKey('is_enabled') &&
        mutableMap['is_enabled'] is int) {
      mutableMap['isEnabled'] = mutableMap.remove('is_enabled') == 1;
    } else if (mutableMap.containsKey('is_enabled')) {
      mutableMap['isEnabled'] = mutableMap.remove('is_enabled');
    }

    // Parse conditions if it's a JSON string
    if (mutableMap['conditions'] is String) {
      try {
        final List<dynamic> conditionsList =
            jsonDecode(mutableMap['conditions'] as String);
        mutableMap['conditions'] = conditionsList;
      } catch (e) {
        mutableMap['conditions'] = [];
      }
    }

    // Parse actions if it's a JSON string
    if (mutableMap['actions'] is String) {
      try {
        final List<dynamic> actionsList =
            jsonDecode(mutableMap['actions'] as String);
        mutableMap['actions'] = actionsList;
      } catch (e) {
        mutableMap['actions'] = [];
      }
    }

    return AutomationRule.fromJson(mutableMap);
  }

  Future<void> insertAutomationRule(AutomationRule rule) async {
    final db = await database;
    await db.insert(
      'automation_rules',
      {
        'id': rule.id,
        'name': rule.name,
        'description': rule.description,
        'conditions': jsonEncode(rule.conditions),
        'actions': jsonEncode(rule.actions),
        'is_enabled': rule.isEnabled ? 1 : 0,
        'created_at': rule.createdAt.toIso8601String(),
        'updated_at': rule.lastUpdated.toIso8601String(),
        'last_triggered': rule.lastTriggered?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAutomationRule(AutomationRule rule) async {
    final db = await database;
    await db.update(
      'automation_rules',
      {
        'id': rule.id,
        'name': rule.name,
        'description': rule.description,
        'conditions': jsonEncode(rule.conditions),
        'actions': jsonEncode(rule.actions),
        'is_enabled': rule.isEnabled ? 1 : 0,
        'created_at': rule.createdAt.toIso8601String(),
        'updated_at': rule.lastUpdated.toIso8601String(),
        'last_triggered': rule.lastTriggered?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> deleteAutomationRule(String id) async {
    final db = await database;
    await db.delete(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Alert operations
  Future<List<Alert>> getAllAlerts({int? limit, bool? unreadOnly}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (unreadOnly == true) {
      whereClause = 'is_read = ?';
      whereArgs = [0];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => Alert.fromJson(map)).toList();
  }

  Future<Alert?> getAlert(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Alert.fromJson(maps.first);
    }
    return null;
  }

  Future<void> insertAlert(Alert alert) async {
    final db = await database;
    await db.insert(
      'alerts',
      {
        'id': alert.id,
        'title': alert.title,
        'message': alert.message,
        'severity': alert.severity.toString().split('.').last,
        'type': alert.type.toString().split('.').last,
        'device_id': alert.deviceId,
        'rule_id': alert.ruleId,
        'timestamp': alert.timestamp.toIso8601String(),
        'is_read': alert.isRead ? 1 : 0,
        'is_acknowledged': alert.isAcknowledged ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAlert(Alert alert) async {
    final db = await database;
    await db.update(
      'alerts',
      {
        'id': alert.id,
        'title': alert.title,
        'message': alert.message,
        'severity': alert.severity.toString().split('.').last,
        'type': alert.type.toString().split('.').last,
        'device_id': alert.deviceId,
        'rule_id': alert.ruleId,
        'timestamp': alert.timestamp.toIso8601String(),
        'is_read': alert.isRead ? 1 : 0,
        'is_acknowledged': alert.isAcknowledged ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<void> markAlertAsRead(String id) async {
    final db = await database;
    await db.update(
      'alerts',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAlertAsAcknowledged(String id) async {
    final db = await database;
    await db.update(
      'alerts',
      {'is_acknowledged': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAlert(String id) async {
    final db = await database;
    await db.delete(
      'alerts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearOldAlerts({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    await db.delete(
      'alerts',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Settings operations
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // User credentials operations
  Future<void> setUserPassword(String userId, String passwordHash) async {
    final db = await database;
    final credentialId = DateTime.now().millisecondsSinceEpoch.toString() +
        userId.substring(0, 4);

    await db.insert(
      'user_credentials',
      {
        'id': credentialId,
        'user_id': userId,
        'password_hash': passwordHash,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getUserPasswordHash(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_credentials',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first['password_hash'] as String;
    }
    return null;
  }

  Future<void> storePasswordResetToken(
      String email, String tokenHash, Duration validityDuration) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': 'reset_token_$email',
        'value': tokenHash,
        'updated_at': DateTime.now().add(validityDuration).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPasswordResetToken(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['reset_token_$email'],
    );

    if (maps.isNotEmpty) {
      final updatedAt = maps.first['updated_at'] as String;
      final expiryTime = DateTime.parse(updatedAt);

      if (DateTime.now().isBefore(expiryTime)) {
        return maps.first['value'] as String;
      }

      // Token expired, delete it
      await db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: ['reset_token_$email'],
      );
    }
    return null;
  }

  Future<void> deletePasswordResetToken(String email) async {
    final db = await database;
    await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: ['reset_token_$email'],
    );
  }

  // Utility methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('alerts');
    await db.delete('automation_rules');
    await db.delete('devices');
    await db.delete('rooms');
  }

  Future<void> clearAllDataIncludingUsers() async {
    final db = await database;
    await db.delete('alerts');
    await db.delete('automation_rules');
    await db.delete('devices');
    await db.delete('rooms');
    await db.delete('auth_sessions');
    await db.delete('users');
    await db.delete('settings');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
