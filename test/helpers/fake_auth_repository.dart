// Extracted from lib/core/auth/auth_repository.dart
// This file is a test-only helper.

import 'dart:math';

import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/auth/models/email_link_result_status.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/auth_tokens.dart';
import 'package:reziphay_mobile/shared/models/pending_auth_context.dart';
import 'package:reziphay_mobile/shared/models/session_user.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Future<UserSession> activateProviderRole(UserSession session) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (session.availableRoles.contains(AppRole.provider)) {
      return session.copyWith(
        activeRole: AppRole.provider,
        tokens: _issueTokens(),
      );
    }

    final updatedUser = session.user.copyWith(
      roles: [...session.availableRoles, AppRole.provider],
    );

    return session.copyWith(
      user: updatedUser,
      activeRole: AppRole.provider,
      tokens: _issueTokens(),
    );
  }

  @override
  Future<void> logout(UserSession? session) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<OtpRequestResult> requestOtp(PendingAuthContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final digits = context.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      throw const AppException(
        'Enter a valid phone number to receive the OTP.',
      );
    }

    return OtpRequestResult(
      debugCode: '123456',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<UserSession> refreshSession(UserSession currentSession) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (currentSession.tokens.refreshToken.isEmpty) {
      throw const AppException(
        'Your session expired. Please sign in again.',
        type: AppExceptionType.unauthorized,
      );
    }

    return currentSession.copyWith(tokens: _issueTokens());
  }

  @override
  Future<EmailLinkResultStatus> verifyEmailMagicLink(Uri uri) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return EmailLinkResultStatusX.fromQuery(uri.queryParameters['status']);
  }

  @override
  Future<UserSession> switchRole(UserSession session, AppRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!session.availableRoles.contains(role)) {
      throw const AppException(
        'This account does not have access to that role.',
        type: AppExceptionType.forbidden,
      );
    }

    return session.copyWith(activeRole: role, tokens: _issueTokens());
  }

  @override
  Future<UserSession> verifyOtp({
    required String otpCode,
    required PendingAuthContext context,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final digits = otpCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      throw const AppException('Enter the 6-digit code from the OTP message.');
    }

    final roles = <AppRole>[AppRole.customer];
    if (context.mode == AuthFlowMode.register &&
        context.intendedRole == AppRole.provider) {
      roles.add(AppRole.provider);
    }

    final user = SessionUser(
      id: 'usr_${_random.nextInt(999999)}',
      fullName: context.fullName ?? 'Reziphay User',
      email: context.email ?? 'hello@reziphay.com',
      phoneNumber: context.phoneNumber,
      roles: roles,
      status: UserStatus.active,
    );

    return UserSession(
      user: user,
      activeRole: roles.contains(AppRole.provider)
          ? context.intendedRole
          : AppRole.customer,
      tokens: _issueTokens(),
    );
  }

  AuthTokens _issueTokens() {
    final tokenSeed = _random.nextInt(999999999);
    final now = DateTime.now();

    return AuthTokens(
      accessToken: 'access_$tokenSeed',
      refreshToken: 'refresh_$tokenSeed',
      accessTokenExpiresAt: now.add(const Duration(minutes: 45)),
    );
  }
}

