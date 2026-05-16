import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  final String id;
  final String name;
  final String roomId;
  final DeviceType type;
  final DeviceStatus status;
  final bool isOn;
  final Map<String, dynamic>? properties;
  final DateTime lastUpdated;
  final String? mqttTopic;

  const Device({
    required this.id,
    required this.name,
    required this.roomId,
    required this.type,
    required this.status,
    required this.isOn,
    this.properties,
    required this.lastUpdated,
    this.mqttTopic,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);

  Device copyWith({
    String? id,
    String? name,
    String? roomId,
    DeviceType? type,
    DeviceStatus? status,
    bool? isOn,
    Map<String, dynamic>? properties,
    DateTime? lastUpdated,
    String? mqttTopic,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      roomId: roomId ?? this.roomId,
      type: type ?? this.type,
      status: status ?? this.status,
      isOn: isOn ?? this.isOn,
      properties: properties ?? this.properties,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      mqttTopic: mqttTopic ?? this.mqttTopic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isOn == other.isOn &&
          status == other.status &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(id, isOn, status, lastUpdated);

  @override
  String toString() {
    return 'Device{id: $id, name: $name, type: $type, status: $status, isOn: $isOn}';
  }
}

enum DeviceType {
  light,
  fan,
  airConditioner,
  television,
  speaker,
  camera,
  doorLock,
  windowSensor,
  motionSensor,
  smokeDetector,
  temperatureSensor,
  humiditySensor,
  switch_,
  outlet,
}

enum DeviceStatus {
  online,
  offline,
  error,
  maintenance,
}

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.light:
        return 'Light';
      case DeviceType.fan:
        return 'Fan';
      case DeviceType.airConditioner:
        return 'Air Conditioner';
      case DeviceType.television:
        return 'Television';
      case DeviceType.speaker:
        return 'Speaker';
      case DeviceType.camera:
        return 'Camera';
      case DeviceType.doorLock:
        return 'Door Lock';
      case DeviceType.windowSensor:
        return 'Window Sensor';
      case DeviceType.motionSensor:
        return 'Motion Sensor';
      case DeviceType.smokeDetector:
        return 'Smoke Detector';
      case DeviceType.temperatureSensor:
        return 'Temperature Sensor';
      case DeviceType.humiditySensor:
        return 'Humidity Sensor';
      case DeviceType.switch_:
        return 'Switch';
      case DeviceType.outlet:
        return 'Outlet';
    }
  }

  String get mqttTopicSuffix {
    switch (this) {
      case DeviceType.light:
        return 'light';
      case DeviceType.fan:
        return 'fan';
      case DeviceType.airConditioner:
        return 'ac';
      case DeviceType.television:
        return 'tv';
      case DeviceType.speaker:
        return 'speaker';
      case DeviceType.camera:
        return 'camera';
      case DeviceType.doorLock:
        return 'lock';
      case DeviceType.windowSensor:
        return 'window';
      case DeviceType.motionSensor:
        return 'motion';
      case DeviceType.smokeDetector:
        return 'smoke';
      case DeviceType.temperatureSensor:
        return 'temp';
      case DeviceType.humiditySensor:
        return 'humidity';
      case DeviceType.switch_:
        return 'switch';
      case DeviceType.outlet:
        return 'outlet';
    }
  }
}

extension DeviceStatusExtension on DeviceStatus {
  String get displayName {
    switch (this) {
      case DeviceStatus.online:
        return 'Online';
      case DeviceStatus.offline:
        return 'Offline';
      case DeviceStatus.error:
        return 'Error';
      case DeviceStatus.maintenance:
        return 'Maintenance';
    }
  }
}
