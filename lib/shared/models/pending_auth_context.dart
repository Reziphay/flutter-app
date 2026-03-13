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
    this.debugOtpCode,
    this.otpExpiresAt,
  });

  final String phoneNumber;
  final AuthFlowMode mode;
  final AppRole intendedRole;
  final String? fullName;
  final String? email;
  final String? debugOtpCode;
  final DateTime? otpExpiresAt;

  PendingAuthContext copyWith({
    String? phoneNumber,
    AuthFlowMode? mode,
    AppRole? intendedRole,
    String? fullName,
    String? email,
    String? debugOtpCode,
    DateTime? otpExpiresAt,
    bool clearDebugOtpCode = false,
    bool clearOtpExpiresAt = false,
  }) {
    return PendingAuthContext(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mode: mode ?? this.mode,
      intendedRole: intendedRole ?? this.intendedRole,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      debugOtpCode: clearDebugOtpCode
          ? null
          : debugOtpCode ?? this.debugOtpCode,
      otpExpiresAt: clearOtpExpiresAt
          ? null
          : otpExpiresAt ?? this.otpExpiresAt,
    );
  }
}
