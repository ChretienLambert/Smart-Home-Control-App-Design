import 'dart:async';
import 'dart:convert';
import '../models/automation_rule.dart';
import '../models/device.dart';
import '../models/alert.dart';
import '../config/smart_home_hardware.dart';
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
  Timer? _evaluationDebounceTimer;
  bool _isRunning = false;
  bool _autoModeEnabled = true;
  StreamSubscription<MqttMessage>? _mqttSubscription;

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

    // Listen to MQTT messages for real-time updates
    _mqttSubscription = _mqtt.messages.listen(_handleMqttMessage);

    _emitEvent(AutomationEvent('engine_started', 'Automation engine started'));
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;
    _evaluationDebounceTimer?.cancel();
    _evaluationDebounceTimer = null;
    await _mqttSubscription?.cancel();
    _mqttSubscription = null;

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
    if (!_autoModeEnabled) {
      return;
    }

    final now = DateTime.now();
    for (final rule in _rules) {
      if (!rule.isEnabled) continue;
      if (rule.lastTriggered != null &&
          now.difference(rule.lastTriggered!).inSeconds < 30) {
        continue;
      }

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
    final device = _devices.cast<Device?>().firstWhere(
          (d) => d?.id == condition.deviceId,
          orElse: () => null,
        );
    if (device == null) return false;

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
    final device = _devices.cast<Device?>().firstWhere(
          (d) => d?.id == condition.deviceId,
          orElse: () => null,
        );
    if (device == null) return false;

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

    // Parse time format (HH:MM) or range (HH:MM-HH:MM)
    if (targetTime.contains('-')) {
      final parts = targetTime.split('-');
      if (parts.length != 2) return false;
      final start = _parseTime(parts[0]);
      final end = _parseTime(parts[1]);
      if (start == null || end == null) return false;

      final current = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      if (startMinutes < endMinutes) {
        return current >= startMinutes && current <= endMinutes;
      } else {
        // Range crosses midnight (e.g., 22:00-06:00)
        return current >= startMinutes || current <= endMinutes;
      }
    }

    final target = _parseTime(targetTime);
    if (target == null) return false;

    switch (condition.operator) {
      case ComparisonOperator.equals:
        return now.hour == target.hour && now.minute == target.minute;
      case ComparisonOperator.greaterThan:
        // Handle "Late Night" logic if checking for evening times
        if (target.hour >= 18) {
           // If target is 22:00, we consider "greater than" to be 22:00-06:00
           final current = now.hour * 60 + now.minute;
           final targetMin = target.hour * 60 + target.minute;
           return current >= targetMin || current <= 360; // Up to 6 AM
        }
        return now.hour > target.hour ||
            (now.hour == target.hour && now.minute > target.minute);
      case ComparisonOperator.lessThan:
        return now.hour < target.hour ||
            (now.hour == target.hour && now.minute < target.minute);
      default:
        return false;
    }
  }

  DateTime? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
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
    // Determine the LCD feedback based on the rule ID
    String? lcdMsg;
    if (rule.id.contains('night_security')) {
      lcdMsg = 'AUTO_M';
    } else if (rule.id.contains('auto_cooling')) {
      lcdMsg = 'AUTO_H';
    } else if (rule.id.contains('fire_safety')) {
      lcdMsg = 'AUTO_F';
    }

    if (lcdMsg != null) {
      _mqtt.publish('smarthome/system/lcd', lcdMsg);
    }

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
    if (action.deviceId == 'system') {
      if (action.type == ActionType.sendNotification) {
        await _sendNotification(action.value.toString(), rule);
      } else if (action.type == ActionType.triggerAlarm) {
        await _triggerAlarm(action.value.toString(), rule);
      }
      return;
    }

    switch (action.type) {
      case ActionType.turnOn:
        final device = _devices.cast<Device?>().firstWhere(
              (d) => d?.id == action.deviceId,
              orElse: () => null,
            );
        if (device != null && !device.isOn) {
          _mqtt.toggleDevice(action.deviceId, true);
        }
        break;
      case ActionType.turnOff:
        final device = _devices.cast<Device?>().firstWhere(
              (d) => d?.id == action.deviceId,
              orElse: () => null,
            );
        if (device != null && device.isOn) {
          _mqtt.toggleDevice(action.deviceId, false);
        }
        break;
      case ActionType.toggle:
        final device = _devices.cast<Device?>().firstWhere(
              (d) => d?.id == action.deviceId,
              orElse: () => null,
            );
        if (device != null) {
          _mqtt.toggleDevice(action.deviceId, !device.isOn);
        }
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
    if (message.topic == SmartHomeHardware.systemStatusTopic) {
      _handleSystemStatus(message);
      return;
    }

    // Update device cache when receiving device updates
    if ((message.messageType == 'status' || message.messageType == 'data') &&
        message.topic.startsWith(SmartHomeHardware.deviceBaseTopic)) {
      _updateDeviceCache(message);
      _scheduleEvaluation();
    }

    // Handle system events
    if (message.messageType == 'event') {
      _handleSystemEvent(message);
    }
  }

  void _handleSystemStatus(MqttMessage message) {
    final data = message.data;
    final autoMode = data['autoMode'];
    if (autoMode is bool) {
      final changed = _autoModeEnabled != autoMode;
      _autoModeEnabled = autoMode;
      if (changed) {
        _emitEvent(AutomationEvent(
          'auto_mode_changed',
          autoMode ? 'Auto mode enabled' : 'Auto mode disabled',
        ));
        if (autoMode) {
          _scheduleEvaluation();
        } else {
          _evaluationDebounceTimer?.cancel();
        }
      }
    }
  }

  void _scheduleEvaluation() {
    if (!_isRunning || !_autoModeEnabled) return;
    _evaluationDebounceTimer?.cancel();
    _evaluationDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      _evaluateRules();
    });
  }

  Future<void> _updateDeviceCache(MqttMessage message) async {
    try {
      final deviceId = message.deviceId;
      if (deviceId.isEmpty) return;

      var device = _devices.cast<Device?>().firstWhere(
            (d) => d?.id == deviceId,
            orElse: () => null,
          );

      device ??= await _db.getDevice(deviceId);
      if (device == null) return;

      final updatedDevice = _mergeDeviceUpdate(device, message.data);
      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        _devices[index] = updatedDevice;
      } else {
        _devices.add(updatedDevice);
      }
    } catch (e) {
      _emitEvent(
          AutomationEvent('cache_error', 'Error updating device cache: $e'));
    }
  }

  Device _mergeDeviceUpdate(Device device, Map<String, dynamic> data) {
    bool? isOn;
    DeviceStatus? status;

    if (data.containsKey('isOn')) {
      isOn = data['isOn'] as bool?;
    }

    if (data.containsKey('status')) {
      final rawStatus = data['status'] as String?;
      if (rawStatus != null) {
        status = DeviceStatus.values.firstWhere(
          (value) => value.name == rawStatus,
          orElse: () => device.status,
        );
      }
    }

    final mergedProperties = Map<String, dynamic>.from(device.properties ?? {});
    if (data.containsKey('properties')) {
      final incomingProps = data['properties'] as Map<String, dynamic>;
      mergedProperties.addAll(incomingProps);
    }

    return device.copyWith(
      status: status ?? device.status,
      isOn: isOn ?? device.isOn,
      properties: mergedProperties,
      lastUpdated: DateTime.now(),
    );
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
    final rule = _rules.cast<AutomationRule?>().firstWhere(
          (r) => r?.id == ruleId,
          orElse: () => null,
        );
    if (rule == null) return;
    final updatedRule = rule.copyWith(isEnabled: true);
    await updateRule(updatedRule);
  }

  Future<void> disableRule(String ruleId) async {
    final rule = _rules.cast<AutomationRule?>().firstWhere(
          (r) => r?.id == ruleId,
          orElse: () => null,
        );
    if (rule == null) return;
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
