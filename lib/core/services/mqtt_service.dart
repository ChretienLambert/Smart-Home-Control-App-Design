import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/alert.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;
  bool _isConnected = false;
  final StreamController<MqttMessage> _messageController =
      StreamController<MqttMessage>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // MQTT Configuration
  String _broker = '192.168.1.100'; // Default local broker
  int _port = 1883;
  String _username = '';
  String _password = '';
  static const String _clientId = 'smart_home_app';

  // Stream getters
  Stream<MqttMessage> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool get isConnected => _isConnected;

  // Update configuration
  void updateConfig({
    required String broker,
    required int port,
    String? username,
    String? password,
  }) {
    _broker = broker;
    _port = port;
    _username = username ?? '';
    _password = password ?? '';
  }

  Future<bool> connect() async {
    try {
      _client = MqttServerClient(_broker, _clientId);
      _client!.port = _port;
      _client!.keepAlivePeriod = 60;
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onUnsubscribed = _onUnsubscribed;
      _client!.pongCallback = _pong;

      // Set authentication if provided
      if (_username.isNotEmpty) {
        _client!.logging(on: true);
        _client!.secure = false;
        _client!.keepAlivePeriod = 20;
      }

      final connMessage = MqttConnectMessage()
          .authenticateAs(_username, _password)
          .withWillTopic('willtopic')
          .withWillMessage('Will message')
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      try {
        await _client!.connect();
        return true;
      } catch (e) {
        print('MQTT Connection Exception: $e');
        _client!.disconnect();
        return false;
      }
    } catch (e) {
      print('MQTT Service Error: $e');
      return false;
    }
  }

  void disconnect() {
    if (_client != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      _client!.disconnect();
    }
  }

  void _onConnected() {
    print('MQTT Connected');
    _isConnected = true;
    _connectionController.add(true);

    // Set up message listener
    _client!.updates?.listen((messages) {
      for (final message in messages) {
        if (message.payload is MqttPublishMessage) {
          final payload =
              (message.payload as MqttPublishMessage).payload.toString();
          _messageController.add(MqttMessage(message.topic, payload));
        }
      }
    });

    // Subscribe to all device topics
    _subscribeToAllDevices();
    _subscribeToSystemTopics();
  }

  void _onDisconnected() {
    print('MQTT Disconnected');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onSubscribed(String topic) {
    print('MQTT Subscribed to topic: $topic');
  }

  void _onUnsubscribed(String? topic) {
    print('MQTT Unsubscribed from topic: $topic');
  }

  void _pong() {
    print('MQTT Ping response received');
  }

  void _subscribeToAllDevices() {
    // Subscribe to device status updates
    subscribe('smarthome/devices/+/status', MqttQos.atLeastOnce);
    subscribe('smarthome/devices/+/data', MqttQos.atLeastOnce);
    subscribe('smarthome/devices/+/control', MqttQos.atLeastOnce);
  }

  void _subscribeToSystemTopics() {
    // Subscribe to system alerts and automation
    subscribe('smarthome/alerts', MqttQos.atLeastOnce);
    subscribe('smarthome/automation/+', MqttQos.atLeastOnce);
    subscribe('smarthome/system/+', MqttQos.atLeastOnce);
  }

  void subscribe(String topic, MqttQos qos) {
    if (_client != null && _isConnected) {
      _client!.subscribe(topic, qos);
    }
  }

  void publish(String topic, String message,
      {MqttQos qos = MqttQos.atLeastOnce}) {
    if (_client != null && _isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, qos, builder.payload!);
    }
  }

  // Device control methods
  void toggleDevice(String deviceId, bool isOn) {
    final topic = 'smarthome/devices/$deviceId/control';
    final message = json.encode({
      'command': 'toggle',
      'state': isOn,
      'timestamp': DateTime.now().toIso8601String(),
    });
    publish(topic, message);
  }

  void setDeviceValue(String deviceId, String property, dynamic value) {
    final topic = 'smarthome/devices/$deviceId/control';
    final message = json.encode({
      'command': 'setValue',
      'property': property,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
    publish(topic, message);
  }

  // Automation control
  void triggerAutomation(String ruleId) {
    final topic = 'smarthome/automation/trigger';
    final message = json.encode({
      'ruleId': ruleId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    publish(topic, message);
  }

  void updateAutomationRule(String ruleId, Map<String, dynamic> rule) {
    final topic = 'smarthome/automation/rules/$ruleId';
    final message = json.encode(rule);
    publish(topic, message);
  }

  // Alert methods
  void sendAlert(Alert alert) {
    final topic = 'smarthome/alerts';
    final message = json.encode(alert.toJson());
    publish(topic, message);
  }

  void dispose() {
    _messageController.close();
    _connectionController.close();
    disconnect();
  }
}

class MqttMessage {
  final String topic;
  final String payload;

  MqttMessage(this.topic, this.payload);

  Map<String, dynamic> get data {
    try {
      return json.decode(payload) as Map<String, dynamic>;
    } catch (e) {
      return {'raw': payload};
    }
  }

  String get deviceId {
    final parts = topic.split('/');
    if (parts.length >= 3) {
      return parts[2];
    }
    return '';
  }

  String get messageType {
    final parts = topic.split('/');
    if (parts.length >= 4) {
      return parts[3];
    }
    return 'unknown';
  }
}
