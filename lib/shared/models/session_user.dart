import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    required this.status,
  });

  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final List<AppRole> roles;
  final UserStatus status;

  SessionUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    List<AppRole>? roles,
    UserStatus? status,
  }) {
    return SessionUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roles: roles ?? this.roles,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'roles': roles.map((role) => role.queryValue).toList(),
      'status': status.name,
    };
  }

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      roles: (json['roles'] as List<dynamic>)
          .map((role) => AppRoleX.fromQuery(role as String))
          .toList(),
      status: UserStatusX.parse(json['status'] as String?),
    );
  }
}
