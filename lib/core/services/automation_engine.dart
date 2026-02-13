import 'dart:async';
import 'dart:convert';
import '../models/automation_rule.dart';
import '../models/device.dart';
import '../models/alert.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';

class AutomationEngine {
  static final AutomationEngine _instance = AutomationEngine._internal();
  factory AutomationEngine() => _instance;
  AutomationEngine._internal();

  final DatabaseService _db = DatabaseService();
  final MQTTService _mqtt = MQTTService();

  List<AutomationRule> _rules = [];
  List<Device> _devices = [];
  Timer? _evaluationTimer;
  bool _isRunning = false;

  // Stream controllers for events
  final StreamController<AutomationEvent> _eventController =
      StreamController<AutomationEvent>.broadcast();

  Stream<AutomationEvent> get events => _eventController.stream;
  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    await _loadRules();
    await _loadDevices();

    // Start periodic evaluation (every 5 seconds)
    _evaluationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _evaluateRules();
    });

    // Listen to MQTT messages for real-time updates
    _mqtt.messages.listen(_handleMqttMessage);

    _emitEvent(AutomationEvent('engine_started', 'Automation engine started'));
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;
    _evaluationTimer?.cancel();
    _evaluationTimer = null;

    _emitEvent(AutomationEvent('engine_stopped', 'Automation engine stopped'));
  }

  Future<void> _loadRules() async {
    _rules = await _db.getAllAutomationRules();
  }

  Future<void> _loadDevices() async {
    _devices = await _db.getAllDevices();
  }

  Future<void> _evaluateRules() async {
    if (!_isRunning) return;

    for (final rule in _rules) {
      if (!rule.isEnabled) continue;

      try {
        final shouldTrigger = await _evaluateConditions(rule.conditions);

        if (shouldTrigger) {
          await _executeActions(rule);
          await _updateRuleLastTriggered(rule);
        }
      } catch (e) {
        _emitEvent(AutomationEvent(
            'rule_error', 'Error evaluating rule ${rule.name}: $e'));
      }
    }
  }

  Future<bool> _evaluateConditions(List<AutomationCondition> conditions) async {
    if (conditions.isEmpty) return false;

    // For now, use AND logic - all conditions must be true
    for (final condition in conditions) {
      if (!await _evaluateCondition(condition)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _evaluateCondition(AutomationCondition condition) async {
    switch (condition.type) {
      case ConditionType.deviceState:
        return await _evaluateDeviceStateCondition(condition);
      case ConditionType.sensorValue:
        return await _evaluateSensorValueCondition(condition);
      case ConditionType.timeBased:
        return _evaluateTimeBasedCondition(condition);
      case ConditionType.systemEvent:
        return false; // Handled by event-driven evaluation
    }
  }

  Future<bool> _evaluateDeviceStateCondition(
      AutomationCondition condition) async {
    final device = _devices.firstWhere((d) => d.id == condition.deviceId);

    switch (condition.operator) {
      case ComparisonOperator.equals:
        return device.isOn == condition.value;
      case ComparisonOperator.notEquals:
        return device.isOn != condition.value;
      default:
        return false;
    }
  }

  Future<bool> _evaluateSensorValueCondition(
      AutomationCondition condition) async {
    final device = _devices.firstWhere((d) => d.id == condition.deviceId);

    if (device.properties == null || condition.sensorProperty == null) {
      return false;
    }

    final sensorValue = device.properties![condition.sensorProperty!];
    final targetValue = condition.value;

    switch (condition.operator) {
      case ComparisonOperator.equals:
        return sensorValue == targetValue;
      case ComparisonOperator.notEquals:
        return sensorValue != targetValue;
      case ComparisonOperator.greaterThan:
        return _compareValues(sensorValue, targetValue) > 0;
      case ComparisonOperator.lessThan:
        return _compareValues(sensorValue, targetValue) < 0;
      case ComparisonOperator.greaterThanOrEqual:
        return _compareValues(sensorValue, targetValue) >= 0;
      case ComparisonOperator.lessThanOrEqual:
        return _compareValues(sensorValue, targetValue) <= 0;
      case ComparisonOperator.contains:
        return sensorValue.toString().contains(targetValue.toString());
    }
  }

  bool _evaluateTimeBasedCondition(AutomationCondition condition) {
    final now = DateTime.now();
    final targetTime = condition.value as String;

    // Parse time format (HH:MM)
    final parts = targetTime.split(':');
    if (parts.length != 2) return false;

    final targetHour = int.tryParse(parts[0]) ?? 0;
    final targetMinute = int.tryParse(parts[1]) ?? 0;

    switch (condition.operator) {
      case ComparisonOperator.equals:
        return now.hour == targetHour && now.minute == targetMinute;
      case ComparisonOperator.greaterThan:
        return now.hour > targetHour ||
            (now.hour == targetHour && now.minute > targetMinute);
      case ComparisonOperator.lessThan:
        return now.hour < targetHour ||
            (now.hour == targetHour && now.minute < targetMinute);
      default:
        return false;
    }
  }

  int _compareValues(dynamic value1, dynamic value2) {
    if (value1 is num && value2 is num) {
      return value1.compareTo(value2);
    }

    final num1 = num.tryParse(value1.toString()) ?? 0;
    final num2 = num.tryParse(value2.toString()) ?? 0;
    return num1.compareTo(num2);
  }

  Future<void> _executeActions(AutomationRule rule) async {
    for (final action in rule.actions) {
      try {
        await _executeAction(action, rule);
      } catch (e) {
        _emitEvent(
            AutomationEvent('action_error', 'Error executing action: $e'));
      }
    }

    _emitEvent(AutomationEvent(
        'rule_triggered', 'Automation rule "${rule.name}" triggered'));
  }

  Future<void> _executeAction(
      AutomationAction action, AutomationRule rule) async {
    switch (action.type) {
      case ActionType.turnOn:
        _mqtt.toggleDevice(action.deviceId, true);
        break;
      case ActionType.turnOff:
        _mqtt.toggleDevice(action.deviceId, false);
        break;
      case ActionType.toggle:
        final device = _devices.firstWhere((d) => d.id == action.deviceId);
        _mqtt.toggleDevice(action.deviceId, !device.isOn);
        break;
      case ActionType.setValue:
        if (action.property != null) {
          _mqtt.setDeviceValue(action.deviceId, action.property!, action.value);
        }
        break;
      case ActionType.sendNotification:
        await _sendNotification(action.value.toString(), rule);
        break;
      case ActionType.triggerAlarm:
        await _triggerAlarm(action.value.toString(), rule);
        break;
    }
  }

  Future<void> _sendNotification(String message, AutomationRule rule) async {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Automation Triggered',
      message: message,
      severity: AlertSeverity.info,
      type: AlertType.automationTriggered,
      ruleId: rule.id,
      timestamp: DateTime.now(),
      isRead: false,
      isAcknowledged: false,
    );

    await _db.insertAlert(alert);
    _mqtt.sendAlert(alert);
  }

  Future<void> _triggerAlarm(String alarmType, AutomationRule rule) async {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Alarm Triggered',
      message: 'Automation rule "${rule.name}" triggered alarm: $alarmType',
      severity: AlertSeverity.critical,
      type: AlertType.securityAlert,
      ruleId: rule.id,
      timestamp: DateTime.now(),
      isRead: false,
      isAcknowledged: false,
    );

    await _db.insertAlert(alert);
    _mqtt.sendAlert(alert);

    // Send alarm command to security system
    _mqtt.publish(
        'smarthome/security/alarm',
        json.encode({
          'type': alarmType,
          'triggered': true,
          'timestamp': DateTime.now().toIso8601String(),
        }));
  }

  Future<void> _updateRuleLastTriggered(AutomationRule rule) async {
    final updatedRule = rule.copyWith(lastTriggered: DateTime.now());
    await _db.updateAutomationRule(updatedRule);

    // Update local cache
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = updatedRule;
    }
  }

  void _handleMqttMessage(MqttMessage message) {
    // Update device cache when receiving device updates
    if (message.messageType == 'status' || message.messageType == 'data') {
      _updateDeviceCache(message);
    }

    // Handle system events
    if (message.messageType == 'event') {
      _handleSystemEvent(message);
    }
  }

  Future<void> _updateDeviceCache(MqttMessage message) async {
    try {
      final deviceId = message.deviceId;
      if (deviceId.isEmpty) return;

      final device = await _db.getDevice(deviceId);
      if (device != null) {
        // Update device in cache
        final index = _devices.indexWhere((d) => d.id == deviceId);
        if (index != -1) {
          _devices[index] = device;
        }
      }
    } catch (e) {
      _emitEvent(
          AutomationEvent('cache_error', 'Error updating device cache: $e'));
    }
  }

  void _handleSystemEvent(MqttMessage message) {
    final data = message.data;
    final eventType = data['type'] as String?;

    if (eventType != null) {
      // Evaluate rules that listen to system events
      _evaluateSystemEventRules(eventType, data);
    }
  }

  Future<void> _evaluateSystemEventRules(
      String eventType, Map<String, dynamic> eventData) async {
    for (final rule in _rules) {
      if (!rule.isEnabled) continue;

      for (final condition in rule.conditions) {
        if (condition.type == ConditionType.systemEvent) {
          // Check if this rule matches the system event
          if (_matchesSystemEvent(condition, eventType, eventData)) {
            await _executeActions(rule);
            await _updateRuleLastTriggered(rule);
            break; // Only trigger once per rule
          }
        }
      }
    }
  }

  bool _matchesSystemEvent(AutomationCondition condition, String eventType,
      Map<String, dynamic> eventData) {
    final expectedEvent = condition.value as String?;

    switch (condition.operator) {
      case ComparisonOperator.equals:
        return eventType == expectedEvent;
      case ComparisonOperator.contains:
        return eventType.contains(expectedEvent ?? '');
      default:
        return false;
    }
  }

  Future<void> addRule(AutomationRule rule) async {
    await _db.insertAutomationRule(rule);
    _rules.add(rule);
    _emitEvent(
        AutomationEvent('rule_added', 'Automation rule "${rule.name}" added'));
  }

  Future<void> updateRule(AutomationRule rule) async {
    await _db.updateAutomationRule(rule);

    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = rule;
    }

    _emitEvent(AutomationEvent(
        'rule_updated', 'Automation rule "${rule.name}" updated'));
  }

  Future<void> deleteRule(String ruleId) async {
    await _db.deleteAutomationRule(ruleId);
    _rules.removeWhere((r) => r.id == ruleId);
    _emitEvent(AutomationEvent('rule_deleted', 'Automation rule deleted'));
  }

  Future<void> enableRule(String ruleId) async {
    final rule = _rules.firstWhere((r) => r.id == ruleId);
    final updatedRule = rule.copyWith(isEnabled: true);
    await updateRule(updatedRule);
  }

  Future<void> disableRule(String ruleId) async {
    final rule = _rules.firstWhere((r) => r.id == ruleId);
    final updatedRule = rule.copyWith(isEnabled: false);
    await updateRule(updatedRule);
  }

  void _emitEvent(AutomationEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void dispose() {
    stop();
    _eventController.close();
  }
}

class AutomationEvent {
  final String type;
  final String message;
  final DateTime timestamp;

  AutomationEvent(this.type, this.message) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'AutomationEvent{type: $type, message: $message, timestamp: $timestamp}';
  }
}
