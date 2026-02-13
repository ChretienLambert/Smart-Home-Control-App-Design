import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? preferences;
  final List<String>? deviceIds;
  final List<String>? roomIds;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.lastLoginAt,
    this.profileImageUrl,
    this.preferences,
    this.deviceIds,
    this.roomIds,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
    List<String>? deviceIds,
    List<String>? roomIds,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
      deviceIds: deviceIds ?? this.deviceIds,
      roomIds: roomIds ?? this.roomIds,
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return username;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, role: $role}';
  }
}

enum UserRole {
  admin,
  user,
  guest,
}

enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.user:
        return 'User';
      case UserRole.guest:
        return 'Guest';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full system access and user management';
      case UserRole.user:
        return 'Can control devices and manage automations';
      case UserRole.guest:
        return 'View-only access to devices';
    }
  }
}

extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.pending:
        return 'Pending';
    }
  }

  String get color {
    switch (this) {
      case UserStatus.active:
        return '#00897B'; // Cyano blue
      case UserStatus.inactive:
        return '#757575'; // Grey
      case UserStatus.suspended:
        return '#F44336'; // Red
      case UserStatus.pending:
        return '#FF9800'; // Orange
    }
  }
}
