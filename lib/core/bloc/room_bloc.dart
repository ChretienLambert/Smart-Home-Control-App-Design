import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/room.dart';
import '../models/device.dart';
import '../services/database_service.dart';

// Events
abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object> get props => [];
}

class LoadRooms extends RoomEvent {}

class AddRoom extends RoomEvent {
  final Room room;

  const AddRoom(this.room);

  @override
  List<Object> get props => [room];
}

class UpdateRoom extends RoomEvent {
  final Room room;

  const UpdateRoom(this.room);

  @override
  List<Object> get props => [room];
}

class DeleteRoom extends RoomEvent {
  final String roomId;

  const DeleteRoom(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class LoadRoomDevices extends RoomEvent {
  final String roomId;

  const LoadRoomDevices(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class AddDeviceToRoom extends RoomEvent {
  final String roomId;
  final String deviceId;

  const AddDeviceToRoom(this.roomId, this.deviceId);

  @override
  List<Object> get props => [roomId, deviceId];
}

class RemoveDeviceFromRoom extends RoomEvent {
  final String roomId;
  final String deviceId;

  const RemoveDeviceFromRoom(this.roomId, this.deviceId);

  @override
  List<Object> get props => [roomId, deviceId];
}

// States
abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object> get props => [];
}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomLoaded extends RoomState {
  final List<Room> rooms;
  final Map<String, List<Device>> roomDevices;

  const RoomLoaded(this.rooms, this.roomDevices);

  @override
  List<Object> get props => [rooms, roomDevices];
}

class RoomError extends RoomState {
  final String message;

  const RoomError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final DatabaseService _db = DatabaseService();

  RoomBloc() : super(RoomInitial()) {
    on<LoadRooms>(_onLoadRooms);
    on<AddRoom>(_onAddRoom);
    on<UpdateRoom>(_onUpdateRoom);
    on<DeleteRoom>(_onDeleteRoom);
    on<LoadRoomDevices>(_onLoadRoomDevices);
    on<AddDeviceToRoom>(_onAddDeviceToRoom);
    on<RemoveDeviceFromRoom>(_onRemoveDeviceFromRoom);
  }

  Future<void> _onLoadRooms(LoadRooms event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      final rooms = await _db.getAllRooms();
      final roomDevices = <String, List<Device>>{};
      
      // Load devices for each room
      for (final room in rooms) {
        final devices = await _db.getDevicesByRoom(room.id);
        roomDevices[room.id] = devices;
      }
      
      emit(RoomLoaded(rooms, roomDevices));
    } catch (e) {
      emit(RoomError('Failed to load rooms: $e'));
    }
  }

  Future<void> _onAddRoom(AddRoom event, Emitter<RoomState> emit) async {
    try {
      await _db.insertRoom(event.room);
      
      if (state is RoomLoaded) {
        final currentRooms = (state as RoomLoaded).rooms;
        final currentRoomDevices = (state as RoomLoaded).roomDevices;
        final updatedRooms = [...currentRooms, event.room];
        final updatedRoomDevices = Map<String, List<Device>>.from(currentRoomDevices)
          ..[event.room.id] = [];
        
        emit(RoomLoaded(updatedRooms, updatedRoomDevices));
      }
    } catch (e) {
      emit(RoomError('Failed to add room: $e'));
    }
  }

  Future<void> _onUpdateRoom(UpdateRoom event, Emitter<RoomState> emit) async {
    try {
      await _db.updateRoom(event.room);
      
      if (state is RoomLoaded) {
        final currentRooms = (state as RoomLoaded).rooms;
        final updatedRooms = currentRooms.map((room) {
          return room.id == event.room.id ? event.room : room;
        }).toList();
        
        emit(RoomLoaded(updatedRooms, (state as RoomLoaded).roomDevices));
      }
    } catch (e) {
      emit(RoomError('Failed to update room: $e'));
    }
  }

  Future<void> _onDeleteRoom(DeleteRoom event, Emitter<RoomState> emit) async {
    try {
      await _db.deleteRoom(event.roomId);
      
      if (state is RoomLoaded) {
        final currentRooms = (state as RoomLoaded).rooms;
        final currentRoomDevices = (state as RoomLoaded).roomDevices;
        final updatedRooms = currentRooms.where((room) => room.id != event.roomId).toList();
        final updatedRoomDevices = Map<String, List<Device>>.from(currentRoomDevices)
          ..remove(event.roomId);
        
        emit(RoomLoaded(updatedRooms, updatedRoomDevices));
      }
    } catch (e) {
      emit(RoomError('Failed to delete room: $e'));
    }
  }

  Future<void> _onLoadRoomDevices(LoadRoomDevices event, Emitter<RoomState> emit) async {
    try {
      final devices = await _db.getDevicesByRoom(event.roomId);
      
      if (state is RoomLoaded) {
        final currentRooms = (state as RoomLoaded).rooms;
        final currentRoomDevices = (state as RoomLoaded).roomDevices;
        final updatedRoomDevices = Map<String, List<Device>>.from(currentRoomDevices)
          ..[event.roomId] = devices;
        
        emit(RoomLoaded(currentRooms, updatedRoomDevices));
      }
    } catch (e) {
      emit(RoomError('Failed to load room devices: $e'));
    }
  }

  Future<void> _onAddDeviceToRoom(AddDeviceToRoom event, Emitter<RoomState> emit) async {
    try {
      // Update the device's room_id in database
      final device = await _db.getDevice(event.deviceId);
      if (device != null) {
        final updatedDevice = device.copyWith(roomId: event.roomId);
        await _db.updateDevice(updatedDevice);
        
        if (state is RoomLoaded) {
          final currentRooms = (state as RoomLoaded).rooms;
          final currentRoomDevices = (state as RoomLoaded).roomDevices;
          final updatedRoomDevices = Map<String, List<Device>>.from(currentRoomDevices);
          
          // Remove device from old room
          for (final roomId in updatedRoomDevices.keys) {
            updatedRoomDevices[roomId] = updatedRoomDevices[roomId]!
                .where((device) => device.id != event.deviceId)
                .toList();
          }
          
          // Add device to new room
          updatedRoomDevices[event.roomId] = [...updatedRoomDevices[event.roomId]!, updatedDevice];
          
          emit(RoomLoaded(currentRooms, updatedRoomDevices));
        }
      }
    } catch (e) {
      emit(RoomError('Failed to add device to room: $e'));
    }
  }

  Future<void> _onRemoveDeviceFromRoom(RemoveDeviceFromRoom event, Emitter<RoomState> emit) async {
    try {
      if (state is RoomLoaded) {
        final currentRooms = (state as RoomLoaded).rooms;
        final currentRoomDevices = (state as RoomLoaded).roomDevices;
        final updatedRoomDevices = Map<String, List<Device>>.from(currentRoomDevices);
        
        updatedRoomDevices[event.roomId] = updatedRoomDevices[event.roomId]!
            .where((device) => device.id != event.deviceId)
            .toList();
        
        emit(RoomLoaded(currentRooms, updatedRoomDevices));
      }
    } catch (e) {
      emit(RoomError('Failed to remove device from room: $e'));
    }
  }

  // Utility methods
  Room? getRoomById(String roomId) {
    if (state is RoomLoaded) {
      final rooms = (state as RoomLoaded).rooms;
      try {
        return rooms.firstWhere((room) => room.id == roomId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  List<Device> getDevicesByRoom(String roomId) {
    if (state is RoomLoaded) {
      final roomDevices = (state as RoomLoaded).roomDevices;
      return roomDevices[roomId] ?? [];
    }
    return [];
  }

  int getDeviceCountByRoom(String roomId) {
    return getDevicesByRoom(roomId).length;
  }

  List<Device> getOnlineDevicesByRoom(String roomId) {
    final devices = getDevicesByRoom(roomId);
    return devices.where((device) => device.status == DeviceStatus.online).toList();
  }

  int getOnlineDeviceCountByRoom(String roomId) {
    return getOnlineDevicesByRoom(roomId).length;
  }

  List<Device> getActiveDevicesByRoom(String roomId) {
    final devices = getDevicesByRoom(roomId);
    return devices.where((device) => device.isOn).toList();
  }

  int getActiveDeviceCountByRoom(String roomId) {
    return getActiveDevicesByRoom(roomId).length;
  }
}
