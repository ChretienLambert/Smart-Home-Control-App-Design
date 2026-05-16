import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/device.dart';
import '../config/smart_home_hardware.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';
import '../services/logger_service.dart';

// Events
abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object> get props => [];
}

class LoadDevices extends DeviceEvent {}

class ToggleDevice extends DeviceEvent {
  final String deviceId;
  final bool isOn;

  const ToggleDevice(this.deviceId, this.isOn);

  @override
  List<Object> get props => [deviceId, isOn];
}

class UpdateDevice extends DeviceEvent {
  final Device device;

  const UpdateDevice(this.device);

  @override
  List<Object> get props => [device];
}

class AddDevice extends DeviceEvent {
  final Device device;

  const AddDevice(this.device);

  @override
  List<Object> get props => [device];
}

class DeleteDevice extends DeviceEvent {
  final String deviceId;

  const DeleteDevice(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class DeviceUpdatedFromMQTT extends DeviceEvent {
  final Device device;

  const DeviceUpdatedFromMQTT(this.device);

  @override
  List<Object> get props => [device];
}

// States
abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object> get props => [];
}

class DeviceInitial extends DeviceState {}

class DeviceLoading extends DeviceState {}

class DeviceLoaded extends DeviceState {
  final List<Device> devices;

  const DeviceLoaded(this.devices);

  @override
  List<Object> get props => [devices];
}

class DeviceError extends DeviceState {
  final String message;

  const DeviceError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DatabaseService _db = DatabaseService();
  final MQTTService _mqtt = MQTTService();
  StreamSubscription<MqttMessage>? _mqttSubscription;

  DeviceBloc() : super(DeviceInitial()) {
    on<LoadDevices>(_onLoadDevices);
    on<ToggleDevice>(_onToggleDevice);
    on<UpdateDevice>(_onUpdateDevice);
    on<AddDevice>(_onAddDevice);
    on<DeleteDevice>(_onDeleteDevice);
    on<DeviceUpdatedFromMQTT>(_onDeviceUpdatedFromMQTT);

    // Listen to MQTT messages
    _mqttSubscription = _mqtt.messages.listen(_handleMqttMessage);
  }

  Future<void> _onLoadDevices(
      LoadDevices event, Emitter<DeviceState> emit) async {
    emit(DeviceLoading());
    try {
      final devices = await _db.getAllDevices();
      emit(DeviceLoaded(devices));
    } catch (e) {
      emit(DeviceError('Failed to load devices: $e'));
    }
  }

  Future<void> _onToggleDevice(
      ToggleDevice event, Emitter<DeviceState> emit) async {
    try {
      // Send MQTT command
      _mqtt.toggleDevice(event.deviceId, event.isOn);

      // Update local state immediately for responsive UI
      if (state is DeviceLoaded) {
        final currentDevices = (state as DeviceLoaded).devices;
        final updatedDevices = currentDevices.map((device) {
          if (device.id == event.deviceId) {
            return device.copyWith(
              isOn: event.isOn,
              lastUpdated: DateTime.now(),
            );
          }
          return device;
        }).toList();

        emit(DeviceLoaded(updatedDevices));

        // Update database
        final device = currentDevices.firstWhere((d) => d.id == event.deviceId);
        final updatedDevice = device.copyWith(
          isOn: event.isOn,
          lastUpdated: DateTime.now(),
        );
        await _db.updateDevice(updatedDevice);
      }
    } catch (e) {
      emit(DeviceError('Failed to toggle device: $e'));
    }
  }

  Future<void> _onUpdateDevice(
      UpdateDevice event, Emitter<DeviceState> emit) async {
    try {
      await _db.updateDevice(event.device);

      if (state is DeviceLoaded) {
        final currentDevices = (state as DeviceLoaded).devices;
        final updatedDevices = currentDevices.map((device) {
          return device.id == event.device.id ? event.device : device;
        }).toList();
        emit(DeviceLoaded(updatedDevices));
      }
    } catch (e) {
      emit(DeviceError('Failed to update device: $e'));
    }
  }

  Future<void> _onAddDevice(AddDevice event, Emitter<DeviceState> emit) async {
    try {
      await _db.insertDevice(event.device);

      if (state is DeviceLoaded) {
        final currentDevices = (state as DeviceLoaded).devices;
        final updatedDevices = [...currentDevices, event.device];
        emit(DeviceLoaded(updatedDevices));
      }
    } catch (e) {
      emit(DeviceError('Failed to add device: $e'));
    }
  }

  Future<void> _onDeleteDevice(
      DeleteDevice event, Emitter<DeviceState> emit) async {
    try {
      await _db.deleteDevice(event.deviceId);

      if (state is DeviceLoaded) {
        final currentDevices = (state as DeviceLoaded).devices;
        final updatedDevices = currentDevices
            .where((device) => device.id != event.deviceId)
            .toList();
        emit(DeviceLoaded(updatedDevices));
      }
    } catch (e) {
      emit(DeviceError('Failed to delete device: $e'));
    }
  }

  Future<void> _onDeviceUpdatedFromMQTT(
      DeviceUpdatedFromMQTT event, Emitter<DeviceState> emit) async {
    try {
      final existing = await _db.getDevice(event.device.id);
      if (existing != null && _sameDeviceSnapshot(existing, event.device)) {
        return;
      }

      // Update database
      await _db.updateDevice(event.device);

      // Update state if devices are loaded
      if (state is DeviceLoaded) {
        final currentDevices = (state as DeviceLoaded).devices;
        
        // Find existing device to check for changes
        final existingIndex = currentDevices.indexWhere((d) => d.id == event.device.id);
        if (existingIndex != -1) {
           final existing = currentDevices[existingIndex];
           // Only skip update if ABSOLUTELY nothing changed including timestamp
           // (though MQTT updates usually change timestamp in _parseDeviceUpdate)
           if (existing.isOn == event.device.isOn && 
               existing.status == event.device.status &&
               existing.lastUpdated == event.device.lastUpdated &&
               _mapEquals(existing.properties, event.device.properties)) {
              return;
           }
        }

        final updatedDevices = currentDevices.map((device) {
          return device.id == event.device.id ? event.device : device;
        }).toList();
        
        emit(DeviceLoaded(updatedDevices));
      }
    } catch (e) {
      // Don't emit error state for MQTT updates, just log it
      debugPrint('Failed to update device from MQTT: $e');
    }
  }

  void _handleMqttMessage(MqttMessage message) {
    // Only process status updates for actual devices
    if (!message.topic.startsWith(SmartHomeHardware.deviceBaseTopic)) {
      return;
    }

    if (message.messageType == 'status' || message.messageType == 'data') {
      _processDeviceUpdate(message);
    }
  }

  Future<void> _processDeviceUpdate(MqttMessage message) async {
    try {
      final hardwareId = message.deviceId;
      if (hardwareId.isEmpty) return;
      
      // 1. Try direct lookup (for admin or raw hardware view)
      var device = await _db.getDevice(hardwareId);

      // 2. If not found, find any device that "maps" to this hardware ID
      if (device == null) {
        final allDevices = await _db.getAllDevices();
        device = allDevices.cast<Device?>().firstWhere(
              (d) => d != null && (d.id.toLowerCase().endsWith('_${hardwareId.toLowerCase()}') || d.id.toLowerCase() == hardwareId.toLowerCase()),
              orElse: () => null,
            );
      }

      if (device != null) {
        final updatedDevice = _parseDeviceUpdate(device, message.data);
        add(DeviceUpdatedFromMQTT(updatedDevice));
      } else {
        LoggerService().warning('Hardware device NOT found in DB for update', context: {
          'hardwareId': hardwareId,
          'topic': message.topic,
        });
      }
    } catch (e) {
      debugPrint('Error processing device update: $e');
    }
  }

  Device _parseDeviceUpdate(Device device, Map<String, dynamic> data) {
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

    // Merge properties instead of replacing them to preserve critical flags like 'arduinoWired'
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

  @override
  Future<void> close() async {
    await _mqttSubscription?.cancel();
    return super.close();
  }

  bool _mapEquals(Map<String, dynamic>? m1, Map<String, dynamic>? m2) {
    if (m1 == null && m2 == null) return true;
    if (m1 == null || m2 == null) return false;
    if (m1.length != m2.length) return false;
    for (final key in m1.keys) {
      if (m1[key] != m2[key]) return false;
    }
    return true;
  }

  bool _sameDeviceSnapshot(Device a, Device b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.roomId == b.roomId &&
        a.type == b.type &&
        a.status == b.status &&
        a.isOn == b.isOn &&
        _mapEquals(a.properties, b.properties) &&
        a.mqttTopic == b.mqttTopic;
  }
}
