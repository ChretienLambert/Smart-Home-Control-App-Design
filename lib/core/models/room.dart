import 'package:json_annotation/json_annotation.dart';
import 'device.dart';

part 'room.g.dart';

@JsonSerializable()
class Room {
  final String id;
  final String name;
  final String? description;
  final List<String> deviceIds;
  final DateTime createdAt;
  final DateTime lastUpdated;

  const Room({
    required this.id,
    required this.name,
    this.description,
    required this.deviceIds,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);

  Room copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? deviceIds,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deviceIds: deviceIds ?? this.deviceIds,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Room{id: $id, name: $name, deviceCount: ${deviceIds.length}}';
  }
}
