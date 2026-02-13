// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
      id: json['id'] as String,
      name: json['name'] as String,
      roomId: json['roomId'] as String,
      type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
      status: $enumDecode(_$DeviceStatusEnumMap, json['status']),
      isOn: json['isOn'] as bool,
      properties: json['properties'] as Map<String, dynamic>?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      mqttTopic: json['mqttTopic'] as String?,
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'roomId': instance.roomId,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'status': _$DeviceStatusEnumMap[instance.status]!,
      'isOn': instance.isOn,
      'properties': instance.properties,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'mqttTopic': instance.mqttTopic,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.light: 'light',
  DeviceType.fan: 'fan',
  DeviceType.airConditioner: 'airConditioner',
  DeviceType.television: 'television',
  DeviceType.speaker: 'speaker',
  DeviceType.camera: 'camera',
  DeviceType.doorLock: 'doorLock',
  DeviceType.windowSensor: 'windowSensor',
  DeviceType.motionSensor: 'motionSensor',
  DeviceType.smokeDetector: 'smokeDetector',
  DeviceType.temperatureSensor: 'temperatureSensor',
  DeviceType.humiditySensor: 'humiditySensor',
  DeviceType.switch_: 'switch_',
  DeviceType.outlet: 'outlet',
};

const _$DeviceStatusEnumMap = {
  DeviceStatus.online: 'online',
  DeviceStatus.offline: 'offline',
  DeviceStatus.error: 'error',
  DeviceStatus.maintenance: 'maintenance',
};
