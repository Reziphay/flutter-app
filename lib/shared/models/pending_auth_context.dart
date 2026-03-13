import 'package:reziphay_mobile/shared/models/app_role.dart';

enum AuthFlowMode { login, register }

extension AuthFlowModeX on AuthFlowMode {
  String get label => switch (this) {
    AuthFlowMode.login => 'Login',
    AuthFlowMode.register => 'Registration',
  };
}

class PendingAuthContext {
  const PendingAuthContext({
    required this.phoneNumber,
    required this.mode,
    required this.intendedRole,
    this.fullName,
    this.email,
  });

  final String phoneNumber;
  final AuthFlowMode mode;
  final AppRole intendedRole;
  final String? fullName;
  final String? email;
}
