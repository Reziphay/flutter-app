// user.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

enum UserRole {
  ucr('UCR'),
  uso('USO');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value.toUpperCase(),
      orElse: () => UserRole.ucr,
    );
  }
}

enum AppRole {
  ucr('UCR'),
  uso('USO'),
  admin('ADMIN');

  const AppRole(this.value);
  final String value;

  static AppRole fromString(String value) {
    return AppRole.values.firstWhere(
      (r) => r.value == value.toUpperCase(),
      orElse: () => AppRole.ucr,
    );
  }
}

class UserRoleItem {
  const UserRoleItem({required this.role, required this.id});

  final AppRole role;
  final String id;

  factory UserRoleItem.fromJson(Map<String, dynamic> json) {
    return UserRoleItem(
      id:   json['id'] as String? ?? '',
      role: AppRole.fromString(json['role'] as String? ?? 'UCR'),
    );
  }
}

class User {
  const User({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.phoneVerifiedAt,
    this.emailVerifiedAt,
    this.activeRole,
    this.roles = const [],
    this.isNewUser = false,
    this.avatarUrl,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final DateTime? phoneVerifiedAt;
  final DateTime? emailVerifiedAt;
  final String? activeRole;
  final List<UserRoleItem> roles;
  final bool isNewUser;
  final String? avatarUrl;

  bool get hasUsoRole => roles.any((r) => r.role == AppRole.uso);
  bool get hasUcrRole => roles.any((r) => r.role == AppRole.ucr);
  bool get isProfileComplete =>
      fullName != null && fullName!.isNotEmpty && email != null && email!.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesList = (json['roles'] as List<dynamic>?)
            ?.map((r) => r is String
                ? UserRoleItem(role: AppRole.fromString(r), id: '')
                : UserRoleItem.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return User(
      id:               json['id'] as String? ?? '',
      fullName:         json['fullName'] as String?,
      email:            json['email'] as String?,
      phone:            json['phone'] as String?,
      phoneVerifiedAt:  _parseDate(json['phoneVerifiedAt']),
      emailVerifiedAt:  _parseDate(json['emailVerifiedAt']),
      activeRole:       json['activeRole'] as String?,
      roles:            rolesList,
      isNewUser:        json['isNewUser'] as bool? ?? false,
      // Support both flat "avatarUrl" and nested "avatar.url" formats
      avatarUrl: json['avatarUrl'] as String? ??
          (json['avatar'] as Map<String, dynamic>?)?['url'] as String?,
    );
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? activeRole,
    List<UserRoleItem>? roles,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return User(
      id:          id          ?? this.id,
      fullName:    fullName    ?? this.fullName,
      email:       email       ?? this.email,
      phone:       phone       ?? this.phone,
      activeRole:  activeRole  ?? this.activeRole,
      roles:       roles       ?? this.roles,
      avatarUrl:   clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try { return DateTime.parse(value as String); } catch (_) { return null; }
  }
}
