import 'dart:async';

import '../bloc/alert_bloc.dart';
import '../bloc/device_bloc.dart';
import '../bloc/room_bloc.dart';
import '../models/automation_rule.dart';
import '../models/device.dart';
import '../models/room.dart';
import '../services/automation_engine.dart';
import '../services/database_seeder.dart';
import '../services/database_service.dart';
import '../services/home_service.dart';
import '../services/mqtt_service.dart';

class AppService {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  final DatabaseService _db = DatabaseService();
  final MQTTService _mqtt = MQTTService();
  final AutomationEngine _automation = AutomationEngine();
  final HomeService _homeService = HomeService();

  late final DeviceBloc _deviceBloc;
  late final RoomBloc _roomBloc;
  late final AlertBloc _alertBloc;

  bool _isInitialized = false;
  bool _isConnected = false;

  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  DeviceBloc get deviceBloc => _deviceBloc;
  RoomBloc get roomBloc => _roomBloc;
  AlertBloc get alertBloc => _alertBloc;
  AutomationEngine get automationEngine => _automation;

  final StreamController<AppState> _stateController =
      StreamController<AppState>.broadcast();

  Stream<AppState> get appState => _stateController.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _emitState(AppState.initializing);

      await DatabaseSeeder().seedDatabase();
      await _homeService.ensureHomesForAllUsers();

      // Ensure the currentUser in the DB is fresh in case seeding added devices
      final currentUser =
          await _db.getUser('john_doe'); // Default login for now
      if (currentUser != null) {
        // This is a bit of a hack to sync the AuthProvider if it's already active
        // but it's safer for initialization.
      }

      _deviceBloc = DeviceBloc();
      _roomBloc = RoomBloc();
      _alertBloc = AlertBloc();

      await _loadBluetoothConfiguration();
      _isConnected = await _mqtt.connect(isAutoConnect: true);

      await _automation.start();

      await _loadInitialData();

      _isInitialized = true;
      _emitState(_isConnected ? AppState.ready : AppState.disconnected);
    } catch (e) {
      _emitState(AppState.error('Initialization failed: $e'));
    }
  }

  Future<void> _loadBluetoothConfiguration() async {
    final config = await getBluetoothConfiguration();

    _mqtt.updateConfig(
      portName: config.portName,
      baudRate: config.baudRate,
      deviceHint: config.deviceHint,
    );
  }

  Future<BluetoothConfiguration> getBluetoothConfiguration() async {
    final storedPortName = await _db.getSetting('bluetooth_port_name');
    final baudRate =
        int.tryParse(await _db.getSetting('bluetooth_baud_rate') ?? '9600') ??
            9600;
    final deviceHint =
        await _db.getSetting('bluetooth_device_hint') ?? 'Arduino Uno';
    final portName = _preferredUsbPortName() ??
        (storedPortName?.trim().isNotEmpty == true
            ? storedPortName!.trim()
            : 'COM9');

    return BluetoothConfiguration(
      portName: portName,
      baudRate: baudRate,
      deviceHint: deviceHint,
    );
  }

  Future<BluetoothConfiguration> getMqttConfiguration() =>
      getBluetoothConfiguration();

  Future<void> _loadInitialData() async {
    _deviceBloc.add(LoadDevices());
    _roomBloc.add(LoadRooms());
    _alertBloc.add(const LoadAlerts());
  }

  String? _preferredUsbPortName() {
    final ports = _mqtt.listAvailablePorts();
    if (ports.isEmpty) return null;

    for (final port in ports) {
      final haystack =
          '${port.name} ${port.description} ${port.manufacturer} ${port.productName}'
              .toLowerCase();
      final looksLikeArduino = haystack.contains('arduino') ||
          haystack.contains('usb serial') ||
          haystack.contains('usb-serial') ||
          haystack.contains('ch340') ||
          haystack.contains('cp210') ||
          haystack.contains('ftdi');
      if (looksLikeArduino) {
        return port.name;
      }
    }

    return null;
  }

  Future<void> updateBluetoothConfiguration({
    required String portName,
    required int baudRate,
    String? deviceHint,
  }) async {
    await _db.setSetting('bluetooth_port_name', portName);
    await _db.setSetting('bluetooth_baud_rate', baudRate.toString());
    await _db.setSetting('bluetooth_device_hint', deviceHint ?? 'Arduino Uno');

    _mqtt.updateConfig(
      portName: portName,
      baudRate: baudRate,
      deviceHint: deviceHint,
    );

    await _mqtt.disconnect(autoReconnect: false);
    _isConnected = await _mqtt.connect(isAutoConnect: false);

    if (_isConnected) {
      _emitState(AppState.ready);
    } else {
      _emitState(AppState.disconnected);
    }
  }

  Future<void> updateMqttConfiguration({
    required String broker,
    required int port,
    String? username,
    String? password,
    String? clientId,
    int? keepAliveSeconds,
    bool? useTls,
    bool? cleanSession,
    String? lastWillTopic,
    String? lastWillMessage,
  }) =>
      updateBluetoothConfiguration(
        portName: broker,
        baudRate: port,
        deviceHint: username,
      );

  Future<void> addDevice(Device device) async {
    await _db.insertDevice(device);
    _deviceBloc.add(AddDevice(device));
  }

  Future<void> addRoom(Room room) async {
    await _db.insertRoom(room);
    _roomBloc.add(AddRoom(room));
  }

  Future<void> refreshHardwareData() async {
    if (_isConnected) {
      _mqtt.requestStateSync();
    }
    _deviceBloc.add(LoadDevices());
    _roomBloc.add(LoadRooms());
    _alertBloc.add(const LoadAlerts());
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
    if (!_isInitialized) {
      return;
    }

    await _automation.stop();
    await _mqtt.disconnect();

    _deviceBloc.close();
    _roomBloc.close();
    _alertBloc.close();
    await _stateController.close();

    _isInitialized = false;
  }
}

class BluetoothConfiguration {
  final String portName;
  final int baudRate;
  final String deviceHint;

  const BluetoothConfiguration({
    required this.portName,
    required this.baudRate,
    required this.deviceHint,
  });
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
