import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/device.dart';
import '../models/room.dart';
import '../models/automation_rule.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';
import '../services/automation_engine.dart';
import '../services/database_seeder.dart';
import '../simulation/device_simulator.dart';
import '../bloc/device_bloc.dart';
import '../bloc/room_bloc.dart';
import '../bloc/alert_bloc.dart';

class AppService {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  // Services
  final DatabaseService _db = DatabaseService();
  final MQTTService _mqtt = MQTTService();
  final AutomationEngine _automation = AutomationEngine();
  final DeviceSimulator _simulator = DeviceSimulator();

  // BLoCs
  late final DeviceBloc _deviceBloc;
  late final RoomBloc _roomBloc;
  late final AlertBloc _alertBloc;

  // App state
  bool _isInitialized = false;
  bool _isSimulationMode = false;
  bool _isConnected = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSimulationMode => _isSimulationMode;
  bool get isConnected => _isConnected;
  DeviceBloc get deviceBloc => _deviceBloc;
  RoomBloc get roomBloc => _roomBloc;
  AlertBloc get alertBloc => _alertBloc;

  // Stream controllers
  final StreamController<AppState> _stateController =
      StreamController<AppState>.broadcast();

  Stream<AppState> get appState => _stateController.stream;

  Future<void> initialize({bool simulationMode = false}) async {
    if (_isInitialized) return;

    try {
      _emitState(AppState.initializing);

      // Initialize database and seed with dummy data
      await DatabaseSeeder().seedDatabase();

      // Initialize BLoCs
      _deviceBloc = DeviceBloc();
      _roomBloc = RoomBloc();
      _alertBloc = AlertBloc();

      // Load MQTT configuration
      await _loadMqttConfiguration();

      // Connect to MQTT broker
      if (!simulationMode) {
        _isConnected = await _mqtt.connect();
        if (!_isConnected) {
          _emitState(AppState.error('Failed to connect to MQTT broker'));
          return;
        }
      }

      // Start automation engine
      await _automation.start();

      // Start simulator if in simulation mode
      if (simulationMode) {
        _isSimulationMode = true;
        await _simulator.start();
        await _initializeSampleData();
      }

      // Load initial data
      await _loadInitialData();

      _isInitialized = true;
      _emitState(AppState.ready);
    } catch (e) {
      _emitState(AppState.error('Initialization failed: $e'));
    }
  }

  Future<void> _loadMqttConfiguration() async {
    final broker = await _db.getSetting('mqtt_broker') ?? '192.168.1.100';
    final port =
        int.tryParse(await _db.getSetting('mqtt_port') ?? '1883') ?? 1883;
    final username = await _db.getSetting('mqtt_username') ?? '';
    final password = await _db.getSetting('mqtt_password') ?? '';

    _mqtt.updateConfig(
      broker: broker,
      port: port,
      username: username,
      password: password,
    );
  }

  Future<void> _initializeSampleData() async {
    // Create sample rooms
    final rooms = [
      Room(
        id: 'sim_living_room',
        name: 'Living Room',
        description: 'Main living area',
        deviceIds: ['sim_light_1', 'sim_temp_1'],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      Room(
        id: 'sim_bedroom',
        name: 'Bedroom',
        description: 'Master bedroom',
        deviceIds: ['sim_ac_1'],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      Room(
        id: 'sim_kitchen',
        name: 'Kitchen',
        description: 'Kitchen area',
        deviceIds: ['sim_smoke_1'],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      Room(
        id: 'sim_hallway',
        name: 'Hallway',
        description: 'Main hallway',
        deviceIds: ['sim_motion_1'],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      Room(
        id: 'sim_entrance',
        name: 'Entrance',
        description: 'Front entrance',
        deviceIds: ['sim_door_1'],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    ];

    for (final room in rooms) {
      await _db.insertRoom(room);
    }

    // Create sample devices
    for (final simDevice in _simulator.simulatedDevices) {
      await _db.insertDevice(simDevice.toDevice());
    }

    // Create sample automation rules
    final rules = [
      AutomationRule(
        id: 'sim_rule_1',
        name: 'Night Light Automation',
        description: 'Turn on lights when motion is detected at night',
        conditions: [
          AutomationCondition(
            deviceId: 'sim_motion_1',
            type: ConditionType.sensorValue,
            value: true,
            operator: ComparisonOperator.equals,
            sensorProperty: 'motion',
          ),
        ],
        actions: [
          AutomationAction(
            deviceId: 'sim_light_1',
            type: ActionType.turnOn,
            value: true,
          ),
        ],
        isEnabled: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      AutomationRule(
        id: 'sim_rule_2',
        name: 'Temperature Control',
        description: 'Turn on AC when temperature exceeds 26°C',
        conditions: [
          AutomationCondition(
            deviceId: 'sim_temp_1',
            type: ConditionType.sensorValue,
            value: 26.0,
            operator: ComparisonOperator.greaterThan,
            sensorProperty: 'temperature',
          ),
        ],
        actions: [
          AutomationAction(
            deviceId: 'sim_ac_1',
            type: ActionType.turnOn,
            value: true,
          ),
        ],
        isEnabled: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    ];

    for (final rule in rules) {
      await _db.insertAutomationRule(rule);
    }
  }

  Future<void> _loadInitialData() async {
    // Load devices
    _deviceBloc.add(LoadDevices());

    // Load rooms
    _roomBloc.add(LoadRooms());

    // Load alerts
    _alertBloc.add(const LoadAlerts());
  }

  Future<void> updateMqttConfiguration({
    required String broker,
    required int port,
    String? username,
    String? password,
  }) async {
    // Save configuration
    await _db.setSetting('mqtt_broker', broker);
    await _db.setSetting('mqtt_port', port.toString());
    await _db.setSetting('mqtt_username', username ?? '');
    await _db.setSetting('mqtt_password', password ?? '');

    // Update MQTT service
    _mqtt.updateConfig(
      broker: broker,
      port: port,
      username: username,
      password: password,
    );

    // Reconnect if not in simulation mode
    if (!_isSimulationMode && _isConnected) {
      _mqtt.disconnect();
      _isConnected = await _mqtt.connect();

      if (_isConnected) {
        _emitState(AppState.ready);
      } else {
        _emitState(AppState.error('Failed to reconnect to MQTT broker'));
      }
    }
  }

  Future<void> toggleSimulationMode() async {
    if (_isSimulationMode) {
      await _simulator.stop();
      _isSimulationMode = false;

      // Connect to real MQTT broker
      _isConnected = await _mqtt.connect();
    } else {
      _mqtt.disconnect();
      _isSimulationMode = true;
      await _simulator.start();
    }

    _emitState(AppState.ready);
  }

  Future<void> addDevice(Device device) async {
    await _db.insertDevice(device);
    _deviceBloc.add(AddDevice(device));
  }

  Future<void> addRoom(Room room) async {
    await _db.insertRoom(room);
    _roomBloc.add(AddRoom(room));
  }

  Future<void> addAutomationRule(AutomationRule rule) async {
    await _automation.addRule(rule);
  }

  Future<void> clearAllData() async {
    await _db.clearAllData();
    _deviceBloc.add(LoadDevices());
    _roomBloc.add(LoadRooms());
    _alertBloc.add(const LoadAlerts());
  }

  void _emitState(AppState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;

    await _automation.stop();
    if (_isSimulationMode) {
      await _simulator.stop();
    } else {
      _mqtt.disconnect();
    }

    _deviceBloc.close();
    _roomBloc.close();
    _alertBloc.close();
    _stateController.close();

    _isInitialized = false;
  }
}

enum AppStateStatus {
  initializing,
  ready,
  error,
  disconnected,
}

class AppState {
  final AppStateStatus status;
  final String? message;

  const AppState(this.status, {this.message});

  static const AppState initializing = AppState(AppStateStatus.initializing);
  static const AppState ready = AppState(AppStateStatus.ready);
  static const AppState disconnected = AppState(AppStateStatus.disconnected);

  static AppState error(String message) =>
      AppState(AppStateStatus.error, message: message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          message == other.message;

  @override
  int get hashCode => status.hashCode ^ message.hashCode;

  @override
  String toString() {
    return 'AppState{status: $status, message: $message}';
  }
}
