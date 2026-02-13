import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/device.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';
import '../services/automation_engine.dart';

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
  final AutomationEngine _automation = AutomationEngine();

  DeviceBloc() : super(DeviceInitial()) {
    on<LoadDevices>(_onLoadDevices);
    on<ToggleDevice>(_onToggleDevice);
    on<UpdateDevice>(_onUpdateDevice);
    on<AddDevice>(_onAddDevice);
    on<DeleteDevice>(_onDeleteDevice);
    on<DeviceUpdatedFromMQTT>(_onDeviceUpdatedFromMQTT);

    // Listen to MQTT messages
    _mqtt.messages.listen(_handleMqttMessage);
  }

  Future<void> _onLoadDevices(LoadDevices event, Emitter<DeviceState> emit) async {
    emit(DeviceLoading());
    try {
      final devices = await _db.getAllDevices();
      emit(DeviceLoaded(devices));
    } catch (e) {
      emit(DeviceError('Failed to load devices: $e'));
    }
  }

  Future<void> _onToggleDevice(ToggleDevice event, Emitter<DeviceState> emit) async {
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

  Future<void> _onUpdateDevice(UpdateDevice event, Emitter<DeviceState> emit) async {
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

  Future<void> _onDeleteDevice(DeleteDevice event, Emitter<DeviceState> emit) async {
    try {
      await _db.deleteDevice(event.deviceId);
      
      if (state is DeviceLoaded) {
        final currentDevices = (state as DeviceLoaded).devices;
        final updatedDevices = currentDevices.where((device) => device.id != event.deviceId).toList();
        emit(DeviceLoaded(updatedDevices));
      }
    } catch (e) {
      emit(DeviceError('Failed to delete device: $e'));
    }
  }

  Future<void> _onDeviceUpdatedFromMQTT(DeviceUpdatedFromMQTT event, Emitter<DeviceState> emit) async {
    try {
      // Update database
      await _db.updateDevice(event.device);
      
      // Update state if devices are loaded
      if (state is DeviceLoaded) {
        final currentDevices = (state as DeviceLoaded).devices;
        final updatedDevices = currentDevices.map((device) {
          return device.id == event.device.id ? event.device : device;
        }).toList();
        emit(DeviceLoaded(updatedDevices));
      }
    } catch (e) {
      // Don't emit error state for MQTT updates, just log it
      print('Failed to update device from MQTT: $e');
    }
  }

  void _handleMqttMessage(MqttMessage message) {
    if (message.messageType == 'status' || message.messageType == 'data') {
      _processDeviceUpdate(message);
    }
  }

  Future<void> _processDeviceUpdate(MqttMessage message) async {
    try {
      final deviceId = message.deviceId;
      if (deviceId.isEmpty) return;

      final device = await _db.getDevice(deviceId);
      if (device == null) return;

      final data = message.data;
      final updatedDevice = _parseDeviceUpdate(device, data);

      add(DeviceUpdatedFromMQTT(updatedDevice));
    } catch (e) {
      print('Error processing device update: $e');
    }
  }

  Device _parseDeviceUpdate(Device device, Map<String, dynamic> data) {
    bool? isOn;
    Map<String, dynamic>? properties;

    if (data.containsKey('isOn')) {
      isOn = data['isOn'] as bool?;
    }

    if (data.containsKey('properties')) {
      properties = Map<String, dynamic>.from(data['properties']);
    }

    return device.copyWith(
      isOn: isOn ?? device.isOn,
      properties: properties ?? device.properties,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<void> close() {
    // Cleanup if needed
    return super.close();
  }
}
