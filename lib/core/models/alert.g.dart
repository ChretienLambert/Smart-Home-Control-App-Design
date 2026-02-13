// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Alert _$AlertFromJson(Map<String, dynamic> json) => Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: $enumDecode(_$AlertSeverityEnumMap, json['severity']),
      type: $enumDecode(_$AlertTypeEnumMap, json['type']),
      deviceId: json['deviceId'] as String?,
      ruleId: json['ruleId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      isAcknowledged: json['isAcknowledged'] as bool,
    );

Map<String, dynamic> _$AlertToJson(Alert instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'severity': _$AlertSeverityEnumMap[instance.severity]!,
      'type': _$AlertTypeEnumMap[instance.type]!,
      'deviceId': instance.deviceId,
      'ruleId': instance.ruleId,
      'timestamp': instance.timestamp.toIso8601String(),
      'isRead': instance.isRead,
      'isAcknowledged': instance.isAcknowledged,
    };

const _$AlertSeverityEnumMap = {
  AlertSeverity.info: 'info',
  AlertSeverity.warning: 'warning',
  AlertSeverity.error: 'error',
  AlertSeverity.critical: 'critical',
};

const _$AlertTypeEnumMap = {
  AlertType.deviceOffline: 'deviceOffline',
  AlertType.sensorThreshold: 'sensorThreshold',
  AlertType.automationTriggered: 'automationTriggered',
  AlertType.securityAlert: 'securityAlert',
  AlertType.systemError: 'systemError',
  AlertType.maintenance: 'maintenance',
  AlertType.lowBattery: 'lowBattery',
  AlertType.connectivity: 'connectivity',
};
