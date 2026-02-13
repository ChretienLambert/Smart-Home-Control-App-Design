import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
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
    if (databaseFactory == null) {
      databaseFactory = databaseFactoryFfi;
    }
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
      version: 1,
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
        first_name TEXT,
        last_name TEXT,
        phone_number TEXT,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login_at TEXT NOT NULL,
        profile_image_url TEXT,
        preferences TEXT,
        device_ids TEXT,
        room_ids TEXT
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
    // Handle database upgrades here
  }

  // User operations
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) => User.fromJson(map)).toList();
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
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
      return User.fromJson(maps.first);
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
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toJson(),
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
    return maps.map((map) => AuthSession.fromJson(map)).toList();
  }

  Future<AuthSession?> getAuthSession(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AuthSession.fromJson(maps.first);
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
      return AuthSession.fromJson(maps.first);
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
    return maps.map((map) => AuthSession.fromJson(map)).toList();
  }

  Future<void> insertAuthSession(AuthSession session) async {
    final db = await database;
    await db.insert(
      'auth_sessions',
      session.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAuthSession(AuthSession session) async {
    final db = await database;
    await db.update(
      'auth_sessions',
      session.toJson(),
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
    return maps.map((map) => Room.fromJson(map)).toList();
  }

  Future<Room?> getRoom(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Room.fromJson(maps.first);
    }
    return null;
  }

  Future<void> insertRoom(Room room) async {
    final db = await database;
    await db.insert(
      'rooms',
      room.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRoom(Room room) async {
    final db = await database;
    await db.update(
      'rooms',
      room.toJson(),
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
    return maps.map((map) => Device.fromJson(map)).toList();
  }

  Future<List<Device>> getDevicesByRoom(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
    return maps.map((map) => Device.fromJson(map)).toList();
  }

  Future<Device?> getDevice(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Device.fromJson(maps.first);
    }
    return null;
  }

  Future<void> insertDevice(Device device) async {
    final db = await database;
    await db.insert(
      'devices',
      device.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDevice(Device device) async {
    final db = await database;
    await db.update(
      'devices',
      device.toJson(),
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
    return maps.map((map) => AutomationRule.fromJson(map)).toList();
  }

  Future<AutomationRule?> getAutomationRule(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AutomationRule.fromJson(maps.first);
    }
    return null;
  }

  Future<void> insertAutomationRule(AutomationRule rule) async {
    final db = await database;
    await db.insert(
      'automation_rules',
      rule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAutomationRule(AutomationRule rule) async {
    final db = await database;
    await db.update(
      'automation_rules',
      rule.toJson(),
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
      alert.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAlert(Alert alert) async {
    final db = await database;
    await db.update(
      'alerts',
      alert.toJson(),
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

  // Utility methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('alerts');
    await db.delete('automation_rules');
    await db.delete('devices');
    await db.delete('rooms');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
