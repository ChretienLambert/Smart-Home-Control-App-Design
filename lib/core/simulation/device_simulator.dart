import 'dart:async';
import 'dart:math';
import 'dart:convert';
import '../models/device.dart';
import '../models/alert.dart';
import '../services/mqtt_service.dart';

class DeviceSimulator {
  static final DeviceSimulator _instance = DeviceSimulator._internal();
  factory DeviceSimulator() => _instance;
  DeviceSimulator._internal();

  final MQTTService _mqtt = MQTTService();
  final List<SimulatedDevice> _simulatedDevices = [];
  Timer? _simulationTimer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;
    
    _isRunning = true;
    await _createSimulatedDevices();
    _startSimulation();
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    
    _isRunning = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _simulatedDevices.clear();
  }

  Future<void> _createSimulatedDevices() async {
    _simulatedDevices.clear();
    
    // Create simulated devices for testing
    _simulatedDevices.addAll([
      SimulatedDevice(
        id: 'sim_light_1',
        name: 'Living Room Light',
        type: DeviceType.light,
        roomId: 'sim_living_room',
        isOn: true,
        properties: {'brightness': 80, 'color': '#FFFFFF'},
      ),
      SimulatedDevice(
        id: 'sim_temp_1',
        name: 'Temperature Sensor',
        type: DeviceType.temperatureSensor,
        roomId: 'sim_living_room',
        isOn: true,
        properties: {'temperature': 24.5, 'humidity': 65},
      ),
      SimulatedDevice(
        id: 'sim_motion_1',
        name: 'Motion Sensor',
        type: DeviceType.motionSensor,
        roomId: 'sim_hallway',
        isOn: true,
        properties: {'motion': false, 'lastMotion': null},
      ),
      SimulatedDevice(
        id: 'sim_door_1',
        name: 'Front Door Lock',
        type: DeviceType.doorLock,
        roomId: 'sim_entrance',
        isOn: true,
        properties: {'locked': true, 'battery': 85},
      ),
      SimulatedDevice(
        id: 'sim_smoke_1',
        name: 'Smoke Detector',
        type: DeviceType.smokeDetector,
        roomId: 'sim_kitchen',
        isOn: true,
        properties: {'smokeDetected': false, 'battery': 92},
      ),
      SimulatedDevice(
        id: 'sim_ac_1',
        name: 'Air Conditioner',
        type: DeviceType.airConditioner,
        roomId: 'sim_bedroom',
        isOn: false,
        properties: {'temperature': 22, 'mode': 'cool', 'fanSpeed': 'auto'},
      ),
    ]);
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateSimulatedDevices();
    });
  }

  void _updateSimulatedDevices() {
    for (final device in _simulatedDevices) {
      _updateDevice(device);
    }
  }

  void _updateDevice(SimulatedDevice device) {
    switch (device.type) {
      case DeviceType.temperatureSensor:
        _updateTemperatureSensor(device);
        break;
      case DeviceType.motionSensor:
        _updateMotionSensor(device);
        break;
      case DeviceType.smokeDetector:
        _updateSmokeDetector(device);
        break;
      case DeviceType.doorLock:
        _updateDoorLock(device);
        break;
      case DeviceType.airConditioner:
        _updateAirConditioner(device);
        break;
      case DeviceType.light:
        _updateLight(device);
        break;
      default:
        // For other devices, just send status updates occasionally
        if (Random().nextBool()) {
          _sendDeviceStatus(device);
        }
    }
  }

  void _updateTemperatureSensor(SimulatedDevice device) {
    // Simulate temperature fluctuations
    final currentTemp = device.properties['temperature'] as double;
    final newTemp = currentTemp + (Random().nextDouble() - 0.5) * 2.0; // ±1 degree
    final clampedTemp = newTemp.clamp(18.0, 30.0);
    
    device.properties['temperature'] = clampedTemp.roundToDouble();
    
    // Simulate humidity changes
    final currentHumidity = device.properties['humidity'] as int;
    final newHumidity = currentHumidity + (Random().nextInt(5) - 2); // ±2%
    device.properties['humidity'] = newHumidity.clamp(30, 80);
    
    _sendSensorData(device);
  }

  void _updateMotionSensor(SimulatedDevice device) {
    // Simulate random motion detection (10% chance)
    final motionDetected = Random().nextDouble() < 0.1;
    device.properties['motion'] = motionDetected;
    
    if (motionDetected) {
      device.properties['lastMotion'] = DateTime.now().toIso8601String();
    }
    
    _sendSensorData(device);
    
    // Send alert if motion detected and it's nighttime
    if (motionDetected && _isNightTime()) {
      _sendMotionAlert(device);
    }
  }

  void _updateSmokeDetector(SimulatedDevice device) {
    // Simulate very rare smoke detection (0.5% chance)
    final smokeDetected = Random().nextDouble() < 0.005;
    device.properties['smokeDetected'] = smokeDetected;
    
    _sendSensorData(device);
    
    if (smokeDetected) {
      _sendSmokeAlert(device);
    }
  }

  void _updateDoorLock(SimulatedDevice device) {
    // Simulate battery drain
    final currentBattery = device.properties['battery'] as int;
    final newBattery = max(0, currentBattery - Random().nextInt(2));
    device.properties['battery'] = newBattery;
    
    // Send low battery alert
    if (newBattery < 20 && newBattery % 5 == 0) {
      _sendLowBatteryAlert(device);
    }
    
    // Occasionally simulate lock/unlock (5% chance)
    if (Random().nextDouble() < 0.05) {
      device.properties['locked'] = !device.properties['locked'] as bool;
      _sendDeviceStatus(device);
    }
  }

  void _updateAirConditioner(SimulatedDevice device) {
    if (device.isOn) {
      // Simulate temperature changes when AC is running
      final currentTemp = device.properties['temperature'] as int;
      final targetTemp = currentTemp + (Random().nextInt(3) - 1); // ±1 degree
      device.properties['temperature'] = targetTemp.clamp(18, 26);
    }
    
    _sendDeviceStatus(device);
  }

  void _updateLight(SimulatedDevice device) {
    if (device.isOn) {
      // Simulate brightness changes
      final currentBrightness = device.properties['brightness'] as int;
      final newBrightness = currentBrightness + (Random().nextInt(11) - 5); // ±5%
      device.properties['brightness'] = newBrightness.clamp(10, 100);
    }
    
    _sendDeviceStatus(device);
  }

  void _sendDeviceStatus(SimulatedDevice device) {
    final topic = 'smarthome/devices/${device.id}/status';
    final message = json.encode({
      'deviceId': device.id,
      'name': device.name,
      'type': device.type.name,
      'status': 'online',
      'isOn': device.isOn,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    
    _mqtt.publish(topic, message);
  }

  void _sendSensorData(SimulatedDevice device) {
    final topic = 'smarthome/devices/${device.id}/data';
    final message = json.encode({
      'deviceId': device.id,
      'properties': device.properties,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _mqtt.publish(topic, message);
  }

  void _sendMotionAlert(SimulatedDevice device) {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Motion Detected',
      message: 'Motion detected by ${device.name} during nighttime',
      severity: AlertSeverity.warning,
      type: AlertType.securityAlert,
      deviceId: device.id,
      timestamp: DateTime.now(),
      isRead: false,
      isAcknowledged: false,
    );
    
    final topic = 'smarthome/alerts';
    final message = json.encode(alert.toJson());
    _mqtt.publish(topic, message);
  }

  void _sendSmokeAlert(SimulatedDevice device) {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Smoke Detected',
      message: 'Smoke detected by ${device.name}! Emergency!',
      severity: AlertSeverity.critical,
      type: AlertType.securityAlert,
      deviceId: device.id,
      timestamp: DateTime.now(),
      isRead: false,
      isAcknowledged: false,
    );
    
    final topic = 'smarthome/alerts';
    final message = json.encode(alert.toJson());
    _mqtt.publish(topic, message);
  }

  void _sendLowBatteryAlert(SimulatedDevice device) {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Low Battery',
      message: '${device.name} battery is low: ${device.properties['battery']}%',
      severity: AlertSeverity.warning,
      type: AlertType.lowBattery,
      deviceId: device.id,
      timestamp: DateTime.now(),
      isRead: false,
      isAcknowledged: false,
    );
    
    final topic = 'smarthome/alerts';
    final message = json.encode(alert.toJson());
    _mqtt.publish(topic, message);
  }

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour < 6 || hour > 22; // 10 PM to 6 AM
  }

  // Control methods for testing
  void toggleDevice(String deviceId, bool isOn) {
    final device = _simulatedDevices.firstWhere((d) => d.id == deviceId);
    device.isOn = isOn;
    _sendDeviceStatus(device);
  }

  void setDeviceProperty(String deviceId, String property, dynamic value) {
    final device = _simulatedDevices.firstWhere((d) => d.id == deviceId);
    device.properties[property] = value;
    
    if (device.type == DeviceType.temperatureSensor || 
        device.type == DeviceType.motionSensor ||
        device.type == DeviceType.smokeDetector) {
      _sendSensorData(device);
    } else {
      _sendDeviceStatus(device);
    }
  }

  List<SimulatedDevice> get simulatedDevices => List.unmodifiable(_simulatedDevices);
}

class SimulatedDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String roomId;
  bool isOn;
  final Map<String, dynamic> properties;

  SimulatedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.roomId,
    required this.isOn,
    required this.properties,
  });

  Device toDevice() {
    return Device(
      id: id,
      name: name,
      roomId: roomId,
      type: type,
      status: DeviceStatus.online,
      isOn: isOn,
      properties: Map.from(properties),
      lastUpdated: DateTime.now(),
      mqttTopic: 'smarthome/devices/$id',
    );
  }
}
