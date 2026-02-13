import 'package:json_annotation/json_annotation.dart';

part 'alert.g.dart';

@JsonSerializable()
class Alert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final AlertType type;
  final String? deviceId;
  final String? ruleId;
  final DateTime timestamp;
  final bool isRead;
  final bool isAcknowledged;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.type,
    this.deviceId,
    this.ruleId,
    required this.timestamp,
    required this.isRead,
    required this.isAcknowledged,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
  Map<String, dynamic> toJson() => _$AlertToJson(this);

  Alert copyWith({
    String? id,
    String? title,
    String? message,
    AlertSeverity? severity,
    AlertType? type,
    String? deviceId,
    String? ruleId,
    DateTime? timestamp,
    bool? isRead,
    bool? isAcknowledged,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      type: type ?? this.type,
      deviceId: deviceId ?? this.deviceId,
      ruleId: ruleId ?? this.ruleId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alert &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Alert{id: $id, title: $title, severity: $severity, type: $type}';
  }
}

enum AlertSeverity {
  info,
  warning,
  error,
  critical,
}

enum AlertType {
  deviceOffline,
  sensorThreshold,
  automationTriggered,
  securityAlert,
  systemError,
  maintenance,
  lowBattery,
  connectivity,
}

extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.error:
        return 'Error';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  String get color {
    switch (this) {
      case AlertSeverity.info:
        return '#2196F3'; // Blue
      case AlertSeverity.warning:
        return '#FF9800'; // Orange
      case AlertSeverity.error:
        return '#F44336'; // Red
      case AlertSeverity.critical:
        return '#9C27B0'; // Purple
    }
  }
}

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.deviceOffline:
        return 'Device Offline';
      case AlertType.sensorThreshold:
        return 'Sensor Threshold';
      case AlertType.automationTriggered:
        return 'Automation Triggered';
      case AlertType.securityAlert:
        return 'Security Alert';
      case AlertType.systemError:
        return 'System Error';
      case AlertType.maintenance:
        return 'Maintenance';
      case AlertType.lowBattery:
        return 'Low Battery';
      case AlertType.connectivity:
        return 'Connectivity';
    }
  }
}
