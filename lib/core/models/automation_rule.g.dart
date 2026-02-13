// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutomationRule _$AutomationRuleFromJson(Map<String, dynamic> json) =>
    AutomationRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => AutomationCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      actions: (json['actions'] as List<dynamic>)
          .map((e) => AutomationAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      isEnabled: json['isEnabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      lastTriggered: json['lastTriggered'] == null
          ? null
          : DateTime.parse(json['lastTriggered'] as String),
    );

Map<String, dynamic> _$AutomationRuleToJson(AutomationRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'conditions': instance.conditions,
      'actions': instance.actions,
      'isEnabled': instance.isEnabled,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'lastTriggered': instance.lastTriggered?.toIso8601String(),
    };

AutomationCondition _$AutomationConditionFromJson(Map<String, dynamic> json) =>
    AutomationCondition(
      deviceId: json['deviceId'] as String,
      type: $enumDecode(_$ConditionTypeEnumMap, json['type']),
      value: json['value'],
      operator: $enumDecode(_$ComparisonOperatorEnumMap, json['operator']),
      sensorProperty: json['sensorProperty'] as String?,
    );

Map<String, dynamic> _$AutomationConditionToJson(
        AutomationCondition instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'type': _$ConditionTypeEnumMap[instance.type]!,
      'value': instance.value,
      'operator': _$ComparisonOperatorEnumMap[instance.operator]!,
      'sensorProperty': instance.sensorProperty,
    };

const _$ConditionTypeEnumMap = {
  ConditionType.deviceState: 'deviceState',
  ConditionType.sensorValue: 'sensorValue',
  ConditionType.timeBased: 'timeBased',
  ConditionType.systemEvent: 'systemEvent',
};

const _$ComparisonOperatorEnumMap = {
  ComparisonOperator.equals: 'equals',
  ComparisonOperator.notEquals: 'notEquals',
  ComparisonOperator.greaterThan: 'greaterThan',
  ComparisonOperator.lessThan: 'lessThan',
  ComparisonOperator.greaterThanOrEqual: 'greaterThanOrEqual',
  ComparisonOperator.lessThanOrEqual: 'lessThanOrEqual',
  ComparisonOperator.contains: 'contains',
};

AutomationAction _$AutomationActionFromJson(Map<String, dynamic> json) =>
    AutomationAction(
      deviceId: json['deviceId'] as String,
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      value: json['value'],
      property: json['property'] as String?,
    );

Map<String, dynamic> _$AutomationActionToJson(AutomationAction instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'type': _$ActionTypeEnumMap[instance.type]!,
      'value': instance.value,
      'property': instance.property,
    };

const _$ActionTypeEnumMap = {
  ActionType.turnOn: 'turnOn',
  ActionType.turnOff: 'turnOff',
  ActionType.toggle: 'toggle',
  ActionType.setValue: 'setValue',
  ActionType.sendNotification: 'sendNotification',
  ActionType.triggerAlarm: 'triggerAlarm',
};
