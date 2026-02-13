import 'package:json_annotation/json_annotation.dart';

part 'automation_rule.g.dart';

@JsonSerializable()
class AutomationRule {
  final String id;
  final String name;
  final String? description;
  final List<AutomationCondition> conditions;
  final List<AutomationAction> actions;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? lastTriggered;

  const AutomationRule({
    required this.id,
    required this.name,
    this.description,
    required this.conditions,
    required this.actions,
    required this.isEnabled,
    required this.createdAt,
    required this.lastUpdated,
    this.lastTriggered,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) => _$AutomationRuleFromJson(json);
  Map<String, dynamic> toJson() => _$AutomationRuleToJson(this);

  AutomationRule copyWith({
    String? id,
    String? name,
    String? description,
    List<AutomationCondition>? conditions,
    List<AutomationAction>? actions,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? lastTriggered,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomationRule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AutomationRule{id: $id, name: $name, enabled: $isEnabled}';
  }
}

@JsonSerializable()
class AutomationCondition {
  final String deviceId;
  final ConditionType type;
  final dynamic value;
  final ComparisonOperator operator;
  final String? sensorProperty;

  const AutomationCondition({
    required this.deviceId,
    required this.type,
    required this.value,
    required this.operator,
    this.sensorProperty,
  });

  factory AutomationCondition.fromJson(Map<String, dynamic> json) => _$AutomationConditionFromJson(json);
  Map<String, dynamic> toJson() => _$AutomationConditionToJson(this);
}

@JsonSerializable()
class AutomationAction {
  final String deviceId;
  final ActionType type;
  final dynamic value;
  final String? property;

  const AutomationAction({
    required this.deviceId,
    required this.type,
    required this.value,
    this.property,
  });

  factory AutomationAction.fromJson(Map<String, dynamic> json) => _$AutomationActionFromJson(json);
  Map<String, dynamic> toJson() => _$AutomationActionToJson(this);
}

enum ConditionType {
  deviceState,
  sensorValue,
  timeBased,
  systemEvent,
}

enum ActionType {
  turnOn,
  turnOff,
  toggle,
  setValue,
  sendNotification,
  triggerAlarm,
}

enum ComparisonOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  contains,
}

extension ConditionTypeExtension on ConditionType {
  String get displayName {
    switch (this) {
      case ConditionType.deviceState:
        return 'Device State';
      case ConditionType.sensorValue:
        return 'Sensor Value';
      case ConditionType.timeBased:
        return 'Time Based';
      case ConditionType.systemEvent:
        return 'System Event';
    }
  }
}

extension ActionTypeExtension on ActionType {
  String get displayName {
    switch (this) {
      case ActionType.turnOn:
        return 'Turn On';
      case ActionType.turnOff:
        return 'Turn Off';
      case ActionType.toggle:
        return 'Toggle';
      case ActionType.setValue:
        return 'Set Value';
      case ActionType.sendNotification:
        return 'Send Notification';
      case ActionType.triggerAlarm:
        return 'Trigger Alarm';
    }
  }
}

extension ComparisonOperatorExtension on ComparisonOperator {
  String get displayName {
    switch (this) {
      case ComparisonOperator.equals:
        return 'Equals';
      case ComparisonOperator.notEquals:
        return 'Not Equals';
      case ComparisonOperator.greaterThan:
        return 'Greater Than';
      case ComparisonOperator.lessThan:
        return 'Less Than';
      case ComparisonOperator.greaterThanOrEqual:
        return 'Greater Than or Equal';
      case ComparisonOperator.lessThanOrEqual:
        return 'Less Than or Equal';
      case ComparisonOperator.contains:
        return 'Contains';
    }
  }

  String get symbol {
    switch (this) {
      case ComparisonOperator.equals:
        return '==';
      case ComparisonOperator.notEquals:
        return '!=';
      case ComparisonOperator.greaterThan:
        return '>';
      case ComparisonOperator.lessThan:
        return '<';
      case ComparisonOperator.greaterThanOrEqual:
        return '>=';
      case ComparisonOperator.lessThanOrEqual:
        return '<=';
      case ComparisonOperator.contains:
        return 'contains';
    }
  }
}
