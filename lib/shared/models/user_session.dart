import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/auth_tokens.dart';
import 'package:reziphay_mobile/shared/models/session_user.dart';

class UserSession {
  const UserSession({
    required this.user,
    required this.activeRole,
    required this.tokens,
  });

  final SessionUser user;
  final AppRole activeRole;
  final AuthTokens tokens;

  List<AppRole> get availableRoles => user.roles;

  UserSession copyWith({
    SessionUser? user,
    AppRole? activeRole,
    AuthTokens? tokens,
  }) {
    return UserSession(
      user: user ?? this.user,
      activeRole: activeRole ?? this.activeRole,
      tokens: tokens ?? this.tokens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'activeRole': activeRole.queryValue,
      'tokens': tokens.toJson(),
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      user: SessionUser.fromJson(json['user'] as Map<String, dynamic>),
      activeRole: AppRoleX.fromQuery(json['activeRole'] as String?),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }
}
