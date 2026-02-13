import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_session.g.dart';

@JsonSerializable()
class AuthSession {
  final String id;
  final String userId;
  final String token;
  final String refreshToken;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? deviceId;
  final String? ipAddress;
  final String? userAgent;
  final bool isActive;

  const AuthSession({
    required this.id,
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.createdAt,
    required this.expiresAt,
    this.deviceId,
    this.ipAddress,
    this.userAgent,
    required this.isActive,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);
  Map<String, dynamic> toJson() => _$AuthSessionToJson(this);

  AuthSession copyWith({
    String? id,
    String? userId,
    String? token,
    String? refreshToken,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? deviceId,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
  }) {
    return AuthSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceId: deviceId ?? this.deviceId,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  bool get isValid {
    return isActive && !isExpired;
  }

  Duration get timeUntilExpiry {
    return expiresAt.difference(DateTime.now());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AuthSession{id: $id, userId: $userId, expiresAt: $expiresAt, isActive: $isActive}';
  }
}

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;
  final String? deviceId;
  final bool rememberMe;

  const LoginRequest({
    required this.username,
    required this.password,
    this.deviceId,
    this.rememberMe = false,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final User user;
  final AuthSession session;
  final String message;

  const AuthResponse({
    required this.user,
    required this.session,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class PasswordResetRequest {
  final String email;

  const PasswordResetRequest({
    required this.email,
  });

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) => _$PasswordResetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PasswordResetRequestToJson(this);
}

@JsonSerializable()
class PasswordResetConfirm {
  final String token;
  final String newPassword;

  const PasswordResetConfirm({
    required this.token,
    required this.newPassword,
  });

  factory PasswordResetConfirm.fromJson(Map<String, dynamic> json) => _$PasswordResetConfirmFromJson(json);
  Map<String, dynamic> toJson() => _$PasswordResetConfirmToJson(this);
}
