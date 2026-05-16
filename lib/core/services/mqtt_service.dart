import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../config/smart_home_hardware.dart';
import '../models/alert.dart';
import 'logger_service.dart';

enum HardwareLinkState {
  disconnected,
  connecting,
  connected,
  awaitingPin,
  verified,
  reconnecting,
}

class HardwareLinkStatus {
  final HardwareLinkState state;
  final String message;
  final String? portName;
  final bool isConnected;
  final bool isVerified;

  const HardwareLinkStatus({
    required this.state,
    required this.message,
    required this.portName,
    required this.isConnected,
    required this.isVerified,
  });
}

class HardwareStatusSnapshot {
  final bool? lampOn;
  final bool? switchOn;
  final bool? fanOn;
  final bool? buzzerOn;
  final bool? doorOpen;
  final bool? autoModeEnabled;
  final double? temperature;
  final double? humidity;
  final int? lightLevel;
  final bool? motionDetected;
  final bool? flameDetected;

  const HardwareStatusSnapshot({
    this.lampOn,
    this.switchOn,
    this.fanOn,
    this.buzzerOn,
    this.doorOpen,
    this.autoModeEnabled,
    this.temperature,
    this.humidity,
    this.lightLevel,
    this.motionDetected,
    this.flameDetected,
  });

  String get signature => [
        lampOn,
        switchOn,
        fanOn,
        buzzerOn,
        doorOpen,
        autoModeEnabled,
        temperature,
        humidity,
        lightLevel,
        motionDetected,
        flameDetected,
      ].join('|');
}

HardwareStatusSnapshot? parseHardwareStatusReport(String line) {
  var normalized = line.trim();
  if (normalized.isEmpty) return null;

  final upper = normalized.toUpperCase();
  if (upper.startsWith('STATUS:') ||
      upper.startsWith('TELEMETRY:') ||
      upper.startsWith('SENSOR:')) {
    normalized = normalized.substring(normalized.indexOf(':') + 1);
  }

  final values = <String, String>{};
  for (final part in normalized.split(',')) {
    final chunk = part.trim();
    if (chunk.isEmpty) continue;

    final separator =
        chunk.contains('=') ? '=' : (chunk.contains(':') ? ':' : null);
    if (separator == null) continue;

    final idx = chunk.indexOf(separator);
    if (idx <= 0 || idx >= chunk.length - 1) continue;
    values[chunk.substring(0, idx).trim().toLowerCase()] =
        chunk.substring(idx + 1).trim();
  }

  if (values.isEmpty) return null;

  bool? parseBinary(String? value) {
    if (value == null) return null;
    final v = value.trim().toUpperCase();
    if (v.isEmpty || v == '--') return null;
    if (v == 'ON' ||
        v == 'OPEN' ||
        v == 'YES' ||
        v == '1' ||
        v == 'TRUE' ||
        v == 'ALERT') {
      return true;
    }
    if (v == 'OFF' ||
        v == 'LOCK' ||
        v == 'LOCKED' ||
        v == 'NO' ||
        v == '0' ||
        v == 'FALSE' ||
        v == 'CLEAR') {
      return false;
    }
    return null;
  }

  bool? parseMode(String? value) {
    if (value == null) return null;
    final v = value.trim().toUpperCase();
    if (v.isEmpty || v == '--') return null;
    if (v == 'ON' || v == 'AUTO' || v == 'FULL' || v == 'TRUE' || v == '1') {
      return true;
    }
    if (v == 'OFF' ||
        v == 'MANUAL' ||
        v == 'FALSE' ||
        v == '0' ||
        v == 'IDLE') {
      return false;
    }
    return null;
  }

  return HardwareStatusSnapshot(
    lampOn: parseBinary(values['lamp']),
    switchOn: parseBinary(values['switch']),
    fanOn: parseBinary(values['fan']),
    buzzerOn: parseBinary(values['buzzer']),
    doorOpen: parseBinary(values['door']),
    autoModeEnabled:
        parseMode(values['auto'] ?? values['automode'] ?? values['mode']),
    temperature: double.tryParse(_digitsOnlyStatic(
      values['temp'] ?? values['temperature'] ?? '',
    )),
    humidity: double.tryParse(_digitsOnlyStatic(
      values['hum'] ?? values['humidity'] ?? '',
    )),
    lightLevel: int.tryParse(_digitsOnlyStatic(
      values['light'] ?? values['lightlevel'] ?? '',
    )),
    motionDetected: parseBinary(values['motion']),
    flameDetected: parseBinary(values['flame']),
  );
}

bool isHardwareVerificationLine(String line) {
  final normalized = line.trim();
  final upper = normalized.toUpperCase();
  return upper == 'ACK:PIN_OK' ||
      upper == 'ACK:AUTH_OK' ||
      upper == 'ACK:PIN_ACCEPTED' ||
      upper.contains('AUTHORIZED') ||
      upper.contains('ACCESS_GRANTED') ||
      upper.contains('ACCESS GRANTED');
}

bool isHardwareReadyLine(String line) {
  final upper = line.trim().toUpperCase();
  return upper == 'BT_READY' || upper == 'WELCOME:SMART_HOME_READY';
}

Duration hardwareReconnectDelayForAttempt(int attempt) {
  final seconds = switch (attempt) {
    <= 1 => 2,
    2 => 4,
    3 => 8,
    4 => 12,
    5 => 20,
    _ => 30,
  };
  return Duration(seconds: seconds);
}

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  SerialPort? _port;
  Timer? _readTimer;
  Timer? _reconnectTimer;
  Timer? _handshakeTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _awaitingHandshake = false;
  bool _hardwareVerified = false;
  bool _isDisposing = false;
  bool _isDisconnecting = false;
  int _reconnectAttempts = 0;
  String? _lastStatusSignature;
  String? _pendingPin;
  String? _lastSuccessfulPin;
  bool _restoreVerificationAfterRestart = false;
  bool? _autoModeEnabled;
  int _pendingPinRetryCount = 0;
  HardwareLinkStatus _linkStatus = const HardwareLinkStatus(
    state: HardwareLinkState.disconnected,
    message: 'Disconnected',
    portName: null,
    isConnected: false,
    isVerified: false,
  );

  final StreamController<MqttMessage> _messageController =
      StreamController<MqttMessage>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<HardwareLinkStatus> _linkController =
      StreamController<HardwareLinkStatus>.broadcast();

  String _portName = SmartHomeHardware.defaultBluetoothPort;
  int _baudRate = SmartHomeHardware.defaultBaudRate;
  String _deviceHint = SmartHomeHardware.controllerHint;
  final StringBuffer _incomingBuffer = StringBuffer();
  final LoggerService _logger = LoggerService();

  Stream<MqttMessage> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  Stream<HardwareLinkStatus> get linkStatus => _linkController.stream;
  bool get isConnected => _isConnected;
  bool get isHardwareVerified => _hardwareVerified;
  bool get isAwaitingHandshake => _awaitingHandshake;
  HardwareLinkStatus get currentLinkStatus => _linkStatus;

  void updateConfig({
    required String portName,
    required int baudRate,
    String? deviceHint,
  }) {
    _portName = portName.trim();
    _baudRate = baudRate;
    _deviceHint = deviceHint?.trim().isNotEmpty == true
        ? deviceHint!.trim()
        : SmartHomeHardware.controllerHint;
  }

  List<BluetoothPortInfo> listAvailablePorts() {
    try {
      final ports = SerialPort.availablePorts;
      return ports.map((name) {
        final port = SerialPort(name);
        try {
          return BluetoothPortInfo(
            name: name,
            description: port.description ?? '',
            manufacturer: port.manufacturer ?? '',
            productName: port.productName ?? '',
            serialNumber: port.serialNumber ?? '',
            macAddress: port.macAddress ?? '',
            vendorId: port.vendorId,
            productId: port.productId,
            transport: port.transport,
          );
        } finally {
          port.dispose();
        }
      }).toList()
        ..sort((a, b) {
          final ah = a.isLikelyBluetooth ? 0 : 1;
          final bh = b.isLikelyBluetooth ? 0 : 1;
          if (ah != bh) return ah.compareTo(bh);
          return a.name.compareTo(b.name);
        });
    } catch (e) {
      _logger.debug('Error listing ports: $e');
      return [];
    }
  }

  String? preferredPortName({bool autoConnectOnly = false}) {
    final ports = listAvailablePorts();
    if (ports.isEmpty) return null;

    for (final port in ports) {
      final haystack =
          '${port.name} ${port.description} ${port.manufacturer} ${port.productName} ${port.macAddress}'
              .toLowerCase();
      if (haystack.contains(_deviceHint.toLowerCase())) {
        return port.name;
      }
    }

    for (final port in ports) {
      final haystack =
          '${port.description} ${port.manufacturer} ${port.productName}'
              .toLowerCase();
      if (haystack.contains('arduino') ||
          haystack.contains('ch340') ||
          haystack.contains('usb-serial')) {
        return port.name;
      }
    }

    if (!autoConnectOnly) return ports.first.name;
    return null;
  }

  Future<bool> connect({bool isAutoConnect = false}) async {
    if (_isConnected || _isConnecting) return _isConnected;

    _isConnecting = true;
    try {
      _updateLinkStatus(
        HardwareLinkState.connecting,
        'Connecting to Arduino hardware...',
        portName: _portName.isNotEmpty ? _portName : null,
      );

      final resolvedPortName = _portName.isNotEmpty
          ? _portName
          : preferredPortName(autoConnectOnly: isAutoConnect);

      if (resolvedPortName == null) {
        _setDisconnected(scheduleReconnect: false);
        return false;
      }

      _logger.info('Opening hardware port: $resolvedPortName');

      final oldPort = _port;
      if (oldPort != null && oldPort.isOpen) oldPort.close();

      _port = SerialPort(resolvedPortName);

      bool opened = false;
      for (int i = 0; i < 2; i++) {
        try {
          if (_port!.openReadWrite()) {
            opened = true;
            break;
          }
        } catch (_) {}
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!opened) {
        _logger.error('Failed to open hardware port $resolvedPortName');
        _setDisconnected(scheduleReconnect: false);
        return false;
      }

      final config = SerialPortConfig();
      try {
        config.baudRate = _baudRate;
        config.bits = 8;
        config.parity = SerialPortParity.none;
        config.stopBits = 1;
        config.setFlowControl(SerialPortFlowControl.none);
        _port!.config = config;
      } finally {
        config.dispose();
      }

      _isConnected = true;
      _hardwareVerified = false;
      _awaitingHandshake = true;
      _lastStatusSignature = null;
      _pendingPinRetryCount = 0;
      _incomingBuffer.clear();
      _connectionController.add(true);
      _reconnectAttempts = 0;
      _updateLinkStatus(
        HardwareLinkState.connected,
        'USB serial transport connected on $resolvedPortName. Send the controller PIN to unlock hardware.',
        portName: resolvedPortName,
      );

      _startReadLoop();
      requestStateSync(silent: true);
      if (_pendingPin != null && _awaitingHandshake) {
        _schedulePendingPinRetry();
      }

      return true;
    } catch (e, stackTrace) {
      _logger.error('Hardware connection failed',
          error: e, stackTrace: stackTrace);
      _setDisconnected(scheduleReconnect: true);
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect({bool autoReconnect = false}) async {
    if (_isDisposing) return;
    _isDisposing = true;
    _setDisconnected(scheduleReconnect: autoReconnect);
    _isDisposing = false;
  }

  void publish(String topic, String message) {
    if (!_isConnected || _port == null || !_port!.isOpen) return;

    if (topic == SmartHomeHardware.syncRequestTopic) {
      requestStateSync();
      return;
    }

    if (topic == 'smarthome/system/lcd') {
      _sendRaw(message, label: 'LCD');
    }
  }

  String toggleDevice(String deviceId, bool isOn,
      {String? homeId, String? commandId}) {
    final resolvedCommandId = commandId ?? _createCommandId();
    final command = SmartHomeHardware.commandForDevice(deviceId, isOn);
    if (command != null) {
      _sendRaw(command);
      _emitDeviceStatus(deviceId, isOn);
    }
    return resolvedCommandId;
  }

  void setDeviceValue(String deviceId, String property, dynamic value) {
    _emitDeviceStatus(deviceId, true, properties: {property: value});
  }

  String submitPin(String pin, {String? homeId, String? commandId}) {
    final cid = commandId ?? _createCommandId();
    _awaitingHandshake = true;
    _pendingPin = pin.trim();
    if (_pendingPin!.isNotEmpty) {
      _lastSuccessfulPin = _pendingPin;
      _restoreVerificationAfterRestart = true;
    }
    _pendingPinRetryCount = 0;
    _updateLinkStatus(
      HardwareLinkState.awaitingPin,
      'Controller PIN sent. Waiting for Arduino verification...',
      portName: _portName.isNotEmpty ? _portName : null,
    );
    _sendRaw('*${_pendingPin!}#', label: 'PIN', appendNewline: false);
    _schedulePendingPinRetry();
    return cid;
  }

  String sendKeypadAction(String key, {String? homeId, String? commandId}) {
    final cid = commandId ?? _createCommandId();
    _sendRaw(key);
    return cid;
  }

  Future<void> requestStateSync({String? homeId, bool silent = false}) async {
    if (!_isConnected || _port == null || !_port!.isOpen) return;
    _sendRaw('S', label: 'PING');
  }

  void sendAlert(Alert alert) {
    const topic = 'smarthome/alerts';
    final message = json.encode(alert.toJson());
    _messageController.add(MqttMessage(topic, message));
  }

  void _handleIncomingLine(String line) {
    if (line.isEmpty) return;

    if (isHardwareReadyLine(line)) {
      final shouldRestoreVerification =
          _restoreVerificationAfterRestart && _lastSuccessfulPin != null;
      _isConnected = true;
      _hardwareVerified = false;
      _awaitingHandshake = false;
      _handshakeTimer?.cancel();
      _logger.info('Hardware boot/restart detected: $line');
      _connectionController.add(true);
      if (shouldRestoreVerification) {
        _messageController.add(MqttMessage(
          SmartHomeHardware.systemStatusTopic,
          json.encode({
            'message':
                'Arduino restarted and is ready. Restoring controller PIN...',
            'state': 'restart_detected',
            'verified': false,
            'connected': true,
            'autoMode': _autoModeEnabled ?? true,
            'restartDetected': true,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        ));
      }
      _updateLinkStatus(
        HardwareLinkState.connected,
        'Arduino restarted and is ready. Resend the controller PIN to reauthorize hardware.',
        portName: _portName.isNotEmpty ? _portName : null,
      );
      if (shouldRestoreVerification) {
        _awaitingHandshake = true;
        _pendingPin = _lastSuccessfulPin;
        _pendingPinRetryCount = 0;
        Timer(const Duration(milliseconds: 350), () {
          if (_pendingPin != null && _isConnected && !_hardwareVerified) {
            _sendRaw('*$_pendingPin#',
                label: 'PIN-RESTORE', appendNewline: false);
            _schedulePendingPinRetry();
          }
        });
      } else if (_pendingPin != null) {
        _awaitingHandshake = true;
        _schedulePendingPinRetry();
      }
      return;
    }

    if (isHardwareVerificationLine(line)) {
      _hardwareVerified = true;
      _awaitingHandshake = false;
      _handshakeTimer?.cancel();
      _pendingPin = null;
      _pendingPinRetryCount = 0;
      _updateLinkStatus(
        HardwareLinkState.verified,
        'Hardware verified. Live control is available.',
        portName: _portName.isNotEmpty ? _portName : null,
      );
      return;
    }

    if (line.startsWith('ACK:')) {
      if (line == 'ACK:PIN_OK') {
        _hardwareVerified = true;
        _awaitingHandshake = false;
        _handshakeTimer?.cancel();
        _restoreVerificationAfterRestart = true;
        _lastSuccessfulPin = _pendingPin ?? _lastSuccessfulPin;
        _pendingPin = null;
        _pendingPinRetryCount = 0;
        _updateLinkStatus(
          HardwareLinkState.verified,
          'Hardware verified. Live control is available.',
          portName: _portName.isNotEmpty ? _portName : null,
        );
      } else if (line == 'ACK:PIN_BAD' || line == 'ACK:PIN_FAIL') {
        _hardwareVerified = false;
        _awaitingHandshake = false;
        _pendingPin = null;
        _pendingPinRetryCount = 0;
        _restoreVerificationAfterRestart = false;
        _updateLinkStatus(
          HardwareLinkState.connected,
          'PIN rejected by Arduino. Check the controller PIN and try again.',
          portName: _portName.isNotEmpty ? _portName : null,
        );
      } else if (line == 'ACK:1') {
        _emitDeviceStatus(SmartHomeHardware.bedroomLightId, false);
      } else if (line == 'ACK:2') {
        _emitDeviceStatus(SmartHomeHardware.bedroomLightId, true);
      } else if (line == 'ACK:3') {
        _emitDeviceStatus(SmartHomeHardware.livingRoomLightId, false);
      } else if (line == 'ACK:4') {
        _emitDeviceStatus(SmartHomeHardware.livingRoomLightId, true);
      } else if (line == 'ACK:5') {
        _emitDeviceStatus(SmartHomeHardware.bedroomFanId, false);
      } else if (line == 'ACK:6') {
        _emitDeviceStatus(SmartHomeHardware.bedroomFanId, true);
      } else if (line == 'ACK:7') {
        _emitDeviceStatus(SmartHomeHardware.bedroomLightId, true);
        _emitDeviceStatus(SmartHomeHardware.livingRoomLightId, true);
        _emitDeviceStatus(SmartHomeHardware.bedroomFanId, true);
      } else if (line == 'ACK:8') {
        _emitDeviceStatus(SmartHomeHardware.bedroomLightId, false);
        _emitDeviceStatus(SmartHomeHardware.livingRoomLightId, false);
        _emitDeviceStatus(SmartHomeHardware.bedroomFanId, false);
      } else if (line == 'ACK:9') {
        _emitDeviceStatus(SmartHomeHardware.doorLockId, true);
      } else if (line == 'ACK:0') {
        _emitDeviceStatus(SmartHomeHardware.doorLockId, false);
      } else if (line == 'ACK:A') {
        _autoModeEnabled = !(_autoModeEnabled ?? true);
        _messageController.add(MqttMessage(
          SmartHomeHardware.systemStatusTopic,
          json.encode({
            'message': _autoModeEnabled == true
                ? 'Auto mode toggled ON.'
                : 'Auto mode toggled OFF.',
            'state': 'auto_mode_toggle',
            'verified': _hardwareVerified,
            'connected': _isConnected,
            'autoMode': _autoModeEnabled ?? true,
            'restartDetected': false,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        ));
      } else if (line.contains('ACK:B') || line.contains('ACK:D')) {
        _emitDeviceStatus(SmartHomeHardware.buzzerDeviceId, true);
      } else if (line.contains('ACK:C')) {
        _emitDeviceStatus(SmartHomeHardware.buzzerDeviceId, false);
      }
      return;
    }

    if (line == 'PONG') {
      _isConnected = true;
      _connectionController.add(true);
      _updateLinkStatus(
        _hardwareVerified
            ? HardwareLinkState.verified
            : HardwareLinkState.connected,
        _hardwareVerified
            ? 'Arduino responded to status ping.'
            : 'Arduino is ready. Send the controller PIN to unlock hardware.',
        portName: _portName.isNotEmpty ? _portName : null,
      );
      return;
    }

    final snapshot = parseHardwareStatusReport(line);
    if (snapshot != null) {
      _handleStatusReport(line, snapshot);
    }
  }

  void _handleStatusReport(String line, HardwareStatusSnapshot snapshot) {
    // We do NOT set _hardwareVerified = true here anymore to prevent bypass.
    if (snapshot.signature == _lastStatusSignature) {
      return;
    }
    _lastStatusSignature = snapshot.signature;
    _logger.info('Hardware RX status: $line');

    final lampOn = snapshot.lampOn ?? false;
    final switchOn = snapshot.switchOn ?? false;
    final fanOn = snapshot.fanOn ?? false;
    final buzzerOn = snapshot.buzzerOn ?? false;
    final doorOpen = snapshot.doorOpen ?? false;
    final autoModeEnabled = snapshot.autoModeEnabled;
    _autoModeEnabled = autoModeEnabled ?? _autoModeEnabled;
    final temp = snapshot.temperature ?? 0;
    final humid = snapshot.humidity ?? 0;
    final light = snapshot.lightLevel ?? 0;
    final motion = snapshot.motionDetected ?? false;
    final flame = snapshot.flameDetected ?? false;

    _emitDeviceStatus(SmartHomeHardware.bedroomLightId, lampOn,
        properties: {'pin': 'D2'});
    _emitDeviceStatus(SmartHomeHardware.livingRoomLightId, switchOn,
        properties: {'pin': 'D3'});
    _emitDeviceStatus(SmartHomeHardware.bedroomFanId, fanOn,
        properties: {'pin': 'D12'});
    _emitDeviceStatus(SmartHomeHardware.buzzerDeviceId, buzzerOn,
        properties: {'pin': 'A4'});
    _emitDeviceStatus(SmartHomeHardware.doorLockId, doorOpen,
        properties: {'pin': 'A2', 'locked': !doorOpen});

    final sensors = {
      SmartHomeHardware.tempSensorId: {'temperature': temp, 'pin': 'D13'},
      SmartHomeHardware.humiditySensorId: {'humidity': humid, 'pin': 'D13'},
      SmartHomeHardware.lightSensorId: {'lightLevel': light, 'pin': 'A3'},
      SmartHomeHardware.motionSensorId: {'detected': motion, 'pin': 'A0'},
      SmartHomeHardware.flameSensorDeviceId: {'detected': flame, 'pin': 'A1'},
    };

    for (final s in sensors.entries) {
      _messageController.add(MqttMessage(
          SmartHomeHardware.deviceStatusTopic(s.key),
          json.encode({
            'deviceId': s.key,
            'status': 'online',
            'properties': {...s.value, 'source': 'hardware'},
            'lastUpdated': DateTime.now().toIso8601String(),
          })));
    }

    _messageController.add(MqttMessage(
      SmartHomeHardware.systemStatusTopic,
      json.encode({
        'message': autoModeEnabled == true
            ? 'Hardware status updated. Auto mode is ON.'
            : 'Hardware status updated. Auto mode is OFF.',
        'state': 'status_report',
        'verified': _hardwareVerified,
        'connected': _isConnected,
        'autoMode': autoModeEnabled ?? true,
        'restartDetected': false,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    ));

    if (flame) {
      _logger.critical('Critical hardware alert: flame detected', context: {
        'line': line,
        'portName': _portName,
      });
    }
  }

  Future<void> _sendRaw(
    String value, {
    String label = 'TX',
    bool appendNewline = true,
  }) async {
    final port = _port;
    if (port == null || !port.isOpen) return;
    try {
      final payload = appendNewline ? '$value\n' : value;
      port.write(Uint8List.fromList(utf8.encode(payload)));
      _logger.debug('Hardware $label: $value');
    } catch (e) {
      _setDisconnected(scheduleReconnect: true);
    }
  }

  void _startReadLoop() {
    _readTimer?.cancel();
    _readTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final port = _port;
      if (port == null || !port.isOpen) {
        return;
      }
      try {
        if (!SerialPort.availablePorts.contains(port.name)) {
          throw Exception('Lost');
        }
        final available = port.bytesAvailable;
        if (available <= 0) {
          return;
        }
        final bytes = port.read(available.clamp(1, 1024), timeout: 50);
        if (bytes.isNotEmpty) {
          _handleIncomingBytes(bytes);
        }
      } catch (_) {
        _setDisconnected(scheduleReconnect: true);
      }
    });
  }

  void _handleIncomingBytes(Uint8List bytes) {
    _incomingBuffer.write(utf8.decode(bytes, allowMalformed: true));
    final raw = _incomingBuffer.toString();
    if (raw.contains('\n')) {
      final lines = raw.split(RegExp(r'[\r\n]+'));
      _incomingBuffer
        ..clear()
        ..write(raw.endsWith('\n') ? '' : lines.removeLast());
      for (final l in lines) {
        _handleIncomingLine(l.trim());
      }
    }
  }

  void _setDisconnected({bool scheduleReconnect = true}) {
    if (_isDisconnecting) {
      return;
    }
    _isDisconnecting = true;
    try {
      final wasVerified = _hardwareVerified;
      _isConnected = false;
      _hardwareVerified = false;
      _connectionController.add(false);
      _readTimer?.cancel();
      _handshakeTimer?.cancel();
      _awaitingHandshake = false;
      final p = _port;
      _port = null;
      if (p != null) {
        try {
          p.close();
          p.dispose();
        } catch (_) {}
      }
      if (scheduleReconnect && !_isDisposing) {
        _reconnectTimer?.cancel();
        _reconnectAttempts += 1;
        final delay = _nextReconnectDelay(_reconnectAttempts);
        _restoreVerificationAfterRestart =
            wasVerified || _restoreVerificationAfterRestart;
        _updateLinkStatus(
          HardwareLinkState.reconnecting,
          'Hardware disconnected. Retrying in ${delay.inSeconds} seconds...',
          portName: _portName.isNotEmpty ? _portName : null,
        );
        _reconnectTimer = Timer(delay, () => connect(isAutoConnect: true));
      } else {
        _reconnectAttempts = 0;
        _restoreVerificationAfterRestart = false;
        _lastSuccessfulPin = null;
        _updateLinkStatus(
          HardwareLinkState.disconnected,
          'Hardware disconnected. Save a port and reconnect to continue.',
          portName: _portName.isNotEmpty ? _portName : null,
        );
        _pendingPin = null;
        _pendingPinRetryCount = 0;
      }
    } finally {
      _isDisconnecting = false;
    }
  }

  void _emitDeviceStatus(String id, bool isOn,
      {Map<String, dynamic>? properties}) {
    _messageController.add(MqttMessage(
        SmartHomeHardware.deviceStatusTopic(id),
        json.encode({
          'deviceId': id,
          'status': 'online',
          'isOn': isOn,
          'properties': properties ?? {},
          'lastUpdated': DateTime.now().toIso8601String(),
        })));
  }

  String _createCommandId() => '${DateTime.now().microsecondsSinceEpoch}';

  Duration _nextReconnectDelay(int attempt) {
    return hardwareReconnectDelayForAttempt(attempt);
  }

  void _updateLinkStatus(
    HardwareLinkState state,
    String message, {
    String? portName,
  }) {
    _linkStatus = HardwareLinkStatus(
      state: state,
      message: message,
      portName: portName,
      isConnected: _isConnected,
      isVerified: _hardwareVerified,
    );
    if (!_linkController.isClosed) {
      _linkController.add(_linkStatus);
    }
  }

  void _schedulePendingPinRetry() {
    if (_pendingPin == null || !_awaitingHandshake) {
      return;
    }

    _handshakeTimer?.cancel();
    _handshakeTimer = Timer(const Duration(milliseconds: 500), () {
      final pendingPin = _pendingPin;
      if (pendingPin == null || !_awaitingHandshake || !_isConnected) {
        return;
      }

      if (_hardwareVerified) {
        _pendingPin = null;
        _pendingPinRetryCount = 0;
        return;
      }

      if (_pendingPinRetryCount >= 2) {
        _updateLinkStatus(
          HardwareLinkState.connected,
          'Arduino is online but did not acknowledge the PIN. Try sending it again.',
          portName: _portName.isNotEmpty ? _portName : null,
        );
        return;
      }

      _pendingPinRetryCount += 1;
      _sendRaw('*$pendingPin#', label: 'PIN-RETRY', appendNewline: false);
      _schedulePendingPinRetry();
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _readTimer?.cancel();
    _handshakeTimer?.cancel();
    if (!_messageController.isClosed) {
      _messageController.close();
    }
    if (!_connectionController.isClosed) {
      _connectionController.close();
    }
    if (!_linkController.isClosed) {
      _linkController.close();
    }
  }
}

class MqttMessage {
  final String topic, payload;
  MqttMessage(this.topic, this.payload);
  Map<String, dynamic> get data => json.decode(payload);
  String get deviceId {
    final p = topic.split('/');
    return p.length >= 3 ? p[2] : '';
  }

  String get messageType {
    final p = topic.split('/');
    if (p.length >= 4) return p[3];
    return p.length >= 2 ? p.last : 'unknown';
  }
}

class BluetoothPortInfo {
  final String name,
      description,
      manufacturer,
      productName,
      serialNumber,
      macAddress;
  final int? vendorId, productId;
  final int transport;
  const BluetoothPortInfo(
      {required this.name,
      required this.description,
      required this.manufacturer,
      required this.productName,
      required this.serialNumber,
      required this.macAddress,
      this.vendorId,
      this.productId,
      required this.transport});
  bool get isLikelyBluetooth =>
      description.toLowerCase().contains('bluetooth') || macAddress.isNotEmpty;
}

String _digitsOnlyStatic(String v) => v.replaceAll(RegExp(r'[^0-9.\-]'), '');
