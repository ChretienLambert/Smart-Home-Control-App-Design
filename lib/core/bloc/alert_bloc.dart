import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/alert.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';

// Events
abstract class AlertEvent extends Equatable {
  const AlertEvent();

  @override
  List<Object> get props => [];
}

class LoadAlerts extends AlertEvent {
  final int? limit;
  final bool? unreadOnly;

  const LoadAlerts({this.limit, this.unreadOnly});

  @override
  List<Object> get props => [limit ?? 0, unreadOnly ?? false];
}

class AddAlert extends AlertEvent {
  final Alert alert;

  const AddAlert(this.alert);

  @override
  List<Object> get props => [alert];
}

class MarkAlertAsRead extends AlertEvent {
  final String alertId;

  const MarkAlertAsRead(this.alertId);

  @override
  List<Object> get props => [alertId];
}

class MarkAlertAsAcknowledged extends AlertEvent {
  final String alertId;

  const MarkAlertAsAcknowledged(this.alertId);

  @override
  List<Object> get props => [alertId];
}

class DeleteAlert extends AlertEvent {
  final String alertId;

  const DeleteAlert(this.alertId);

  @override
  List<Object> get props => [alertId];
}

class MarkAllAlertsAsRead extends AlertEvent {}

class ClearOldAlerts extends AlertEvent {
  final int daysToKeep;

  const ClearOldAlerts({this.daysToKeep = 30});

  @override
  List<Object> get props => [daysToKeep];
}

class AlertReceivedFromMQTT extends AlertEvent {
  final Alert alert;

  const AlertReceivedFromMQTT(this.alert);

  @override
  List<Object> get props => [alert];
}

// States
abstract class AlertState extends Equatable {
  const AlertState();

  @override
  List<Object> get props => [];
}

class AlertInitial extends AlertState {}

class AlertLoading extends AlertState {}

class AlertLoaded extends AlertState {
  final List<Alert> alerts;
  final int unreadCount;

  const AlertLoaded(this.alerts, this.unreadCount);

  @override
  List<Object> get props => [alerts, unreadCount];
}

class AlertError extends AlertState {
  final String message;

  const AlertError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class AlertBloc extends Bloc<AlertEvent, AlertState> {
  final DatabaseService _db = DatabaseService();
  final MQTTService _mqtt = MQTTService();

  AlertBloc() : super(AlertInitial()) {
    on<LoadAlerts>(_onLoadAlerts);
    on<AddAlert>(_onAddAlert);
    on<MarkAlertAsRead>(_onMarkAlertAsRead);
    on<MarkAlertAsAcknowledged>(_onMarkAlertAsAcknowledged);
    on<DeleteAlert>(_onDeleteAlert);
    on<MarkAllAlertsAsRead>(_onMarkAllAlertsAsRead);
    on<ClearOldAlerts>(_onClearOldAlerts);
    on<AlertReceivedFromMQTT>(_onAlertReceivedFromMQTT);

    // Listen to MQTT messages for alerts
    _mqtt.messages.listen(_handleMqttMessage);
  }

  Future<void> _onLoadAlerts(LoadAlerts event, Emitter<AlertState> emit) async {
    emit(AlertLoading());
    try {
      final alerts = await _db.getAllAlerts(
        limit: event.limit,
        unreadOnly: event.unreadOnly,
      );
      final unreadCount = alerts.where((alert) => !alert.isRead).length;
      emit(AlertLoaded(alerts, unreadCount));
    } catch (e) {
      emit(AlertError('Failed to load alerts: $e'));
    }
  }

  Future<void> _onAddAlert(AddAlert event, Emitter<AlertState> emit) async {
    try {
      await _db.insertAlert(event.alert);

      if (state is AlertLoaded) {
        final currentAlerts = (state as AlertLoaded).alerts;
        final updatedAlerts = [event.alert, ...currentAlerts];
        final unreadCount =
            updatedAlerts.where((alert) => !alert.isRead).length;
        emit(AlertLoaded(updatedAlerts, unreadCount));
      }
    } catch (e) {
      emit(AlertError('Failed to add alert: $e'));
    }
  }

  Future<void> _onMarkAlertAsRead(
      MarkAlertAsRead event, Emitter<AlertState> emit) async {
    try {
      await _db.markAlertAsRead(event.alertId);

      if (state is AlertLoaded) {
        final currentAlerts = (state as AlertLoaded).alerts;
        final updatedAlerts = currentAlerts.map((alert) {
          return alert.id == event.alertId
              ? alert.copyWith(isRead: true)
              : alert;
        }).toList();
        final unreadCount =
            updatedAlerts.where((alert) => !alert.isRead).length;
        emit(AlertLoaded(updatedAlerts, unreadCount));
      }
    } catch (e) {
      emit(AlertError('Failed to mark alert as read: $e'));
    }
  }

  Future<void> _onMarkAlertAsAcknowledged(
      MarkAlertAsAcknowledged event, Emitter<AlertState> emit) async {
    try {
      await _db.markAlertAsAcknowledged(event.alertId);

      if (state is AlertLoaded) {
        final currentAlerts = (state as AlertLoaded).alerts;
        final updatedAlerts = currentAlerts.map((alert) {
          return alert.id == event.alertId
              ? alert.copyWith(isAcknowledged: true)
              : alert;
        }).toList();
        final unreadCount =
            updatedAlerts.where((alert) => !alert.isRead).length;
        emit(AlertLoaded(updatedAlerts, unreadCount));
      }
    } catch (e) {
      emit(AlertError('Failed to mark alert as acknowledged: $e'));
    }
  }

  Future<void> _onDeleteAlert(
      DeleteAlert event, Emitter<AlertState> emit) async {
    try {
      await _db.deleteAlert(event.alertId);

      if (state is AlertLoaded) {
        final currentAlerts = (state as AlertLoaded).alerts;
        final updatedAlerts =
            currentAlerts.where((alert) => alert.id != event.alertId).toList();
        final unreadCount =
            updatedAlerts.where((alert) => !alert.isRead).length;
        emit(AlertLoaded(updatedAlerts, unreadCount));
      }
    } catch (e) {
      emit(AlertError('Failed to delete alert: $e'));
    }
  }

  Future<void> _onMarkAllAlertsAsRead(
      MarkAllAlertsAsRead event, Emitter<AlertState> emit) async {
    try {
      if (state is AlertLoaded) {
        final currentAlerts = (state as AlertLoaded).alerts;
        final unreadAlerts = currentAlerts.where((alert) => !alert.isRead);

        for (final alert in unreadAlerts) {
          await _db.markAlertAsRead(alert.id);
        }

        final updatedAlerts =
            currentAlerts.map((alert) => alert.copyWith(isRead: true)).toList();
        emit(AlertLoaded(updatedAlerts, 0));
      }
    } catch (e) {
      emit(AlertError('Failed to mark all alerts as read: $e'));
    }
  }

  Future<void> _onClearOldAlerts(
      ClearOldAlerts event, Emitter<AlertState> emit) async {
    try {
      await _db.clearOldAlerts(daysToKeep: event.daysToKeep);

      // Reload alerts after clearing
      add(const LoadAlerts());
    } catch (e) {
      emit(AlertError('Failed to clear old alerts: $e'));
    }
  }

  Future<void> _onAlertReceivedFromMQTT(
      AlertReceivedFromMQTT event, Emitter<AlertState> emit) async {
    try {
      await _db.insertAlert(event.alert);

      if (state is AlertLoaded) {
        final currentAlerts = (state as AlertLoaded).alerts;
        final updatedAlerts = [event.alert, ...currentAlerts];
        final unreadCount =
            updatedAlerts.where((alert) => !alert.isRead).length;
        emit(AlertLoaded(updatedAlerts, unreadCount));
      }
    } catch (e) {
      // Don't emit error state for MQTT alerts, just log it
      print('Failed to save MQTT alert: $e');
    }
  }

  void _handleMqttMessage(MqttMessage message) {
    if (message.messageType == 'alerts') {
      _processAlertMessage(message);
    }
  }

  Future<void> _processAlertMessage(MqttMessage message) async {
    try {
      final data = message.data;
      final alert = Alert.fromJson(data);
      add(AlertReceivedFromMQTT(alert));
    } catch (e) {
      print('Error processing alert message: $e');
    }
  }

  // Utility methods
  List<Alert> getAlertsBySeverity(AlertSeverity severity) {
    if (state is AlertLoaded) {
      final alerts = (state as AlertLoaded).alerts;
      return alerts.where((alert) => alert.severity == severity).toList();
    }
    return [];
  }

  List<Alert> getAlertsByType(AlertType type) {
    if (state is AlertLoaded) {
      final alerts = (state as AlertLoaded).alerts;
      return alerts.where((alert) => alert.type == type).toList();
    }
    return [];
  }

  List<Alert> getUnreadAlerts() {
    if (state is AlertLoaded) {
      final alerts = (state as AlertLoaded).alerts;
      return alerts.where((alert) => !alert.isRead).toList();
    }
    return [];
  }

  List<Alert> getCriticalAlerts() {
    if (state is AlertLoaded) {
      final alerts = (state as AlertLoaded).alerts;
      return alerts
          .where((alert) => alert.severity == AlertSeverity.critical)
          .toList();
    }
    return [];
  }

  int getUnreadCount() {
    if (state is AlertLoaded) {
      return (state as AlertLoaded).unreadCount;
    }
    return 0;
  }

  int getCriticalCount() {
    return getCriticalAlerts().length;
  }

  bool hasUnreadCriticalAlerts() {
    final criticalAlerts = getCriticalAlerts();
    return criticalAlerts.any((alert) => !alert.isRead);
  }

  Alert? getLatestAlert() {
    if (state is AlertLoaded) {
      final alerts = (state as AlertLoaded).alerts;
      if (alerts.isNotEmpty) {
        return alerts
            .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      }
    }
    return null;
  }

  @override
  Future<void> close() {
    // Cleanup if needed
    return super.close();
  }
}
