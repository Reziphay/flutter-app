import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/auth/models/email_link_result_status.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/auth_tokens.dart';
import 'package:reziphay_mobile/shared/models/pending_auth_context.dart';
import 'package:reziphay_mobile/shared/models/session_user.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => BackendAuthRepository(
    publicApiClient: ref.watch(publicApiClientProvider),
    apiClient: ref.watch(apiClientProvider),
  ),
);

class OtpRequestResult {
  const OtpRequestResult({this.debugCode, this.expiresAt});

  final String? debugCode;
  final DateTime? expiresAt;
}

abstract class AuthRepository {
  Future<OtpRequestResult> requestOtp(PendingAuthContext context);

  Future<UserSession> verifyOtp({
    required String otpCode,
    required PendingAuthContext context,
  });

  Future<EmailLinkResultStatus> verifyEmailMagicLink(Uri uri);

  Future<UserSession> refreshSession(UserSession currentSession);

  Future<UserSession> activateProviderRole(UserSession session);

  Future<UserSession> switchRole(UserSession session, AppRole role);

  Future<void> logout(UserSession? session);
}

class BackendAuthRepository implements AuthRepository {
  BackendAuthRepository({
    required ApiClient publicApiClient,
    required ApiClient apiClient,
  }) : _publicApiClient = publicApiClient,
       _apiClient = apiClient;

  final ApiClient _publicApiClient;
  final ApiClient _apiClient;

  @override
  Future<UserSession> activateProviderRole(UserSession session) async {
    final data = await _apiClient.post<JsonMap>(
      '/users/me/activate-uso',
      mapper: asJsonMap,
    );
    return _parseSessionPayload(data);
  }

  @override
  Future<EmailLinkResultStatus> verifyEmailMagicLink(Uri uri) async {
    final token = _extractMagicLinkToken(uri);
    if (token == null || token.isEmpty) {
      return EmailLinkResultStatus.invalid;
    }

    try {
      final data = await _publicApiClient.post<dynamic>(
        '/auth/verify-email-magic-link',
        data: {'token': token},
        extra: const {'skipAuth': true},
        mapper: (payload) => payload,
      );

      if (data is Map) {
        final map = asJsonMap(data);
        return EmailLinkResultStatusX.fromBackendValue(
          map['status'] as String? ??
              map['result'] as String? ??
              map['code'] as String?,
        );
      }

      return EmailLinkResultStatus.success;
    } on AppException catch (error) {
      return _mapEmailLinkError(error, uri);
    }
  }

  @override
  Future<void> logout(UserSession? session) async {
    if (session == null) {
      return;
    }

    await _apiClient.post<void>('/auth/logout', mapper: (_) {});
  }

  @override
  Future<OtpRequestResult> requestOtp(PendingAuthContext context) async {
    final data = await _publicApiClient.post<JsonMap>(
      '/auth/request-phone-otp',
      data: {
        'phone': context.phoneNumber.trim(),
        'purpose': _otpPurposeForContext(context),
        if (context.mode == AuthFlowMode.register) ...{
          'fullName': context.fullName?.trim(),
          'email': context.email?.trim(),
        },
      },
      extra: const {'skipAuth': true},
      mapper: asJsonMap,
    );

    return OtpRequestResult(
      debugCode: data['debugCode'] as String?,
      expiresAt: _parseDateTime(data['expiresAt']),
    );
  }

  @override
  Future<UserSession> refreshSession(UserSession currentSession) async {
    final data = await _publicApiClient.post<JsonMap>(
      '/auth/refresh',
      data: {'refreshToken': currentSession.tokens.refreshToken},
      extra: const {'skipAuth': true},
      mapper: asJsonMap,
    );

    return _parseSessionPayload(data);
  }

  @override
  Future<UserSession> switchRole(UserSession session, AppRole role) async {
    final data = await _apiClient.post<JsonMap>(
      '/users/me/switch-role',
      data: {'role': role.backendValue},
      mapper: asJsonMap,
    );
    return _parseSessionPayload(data);
  }

  @override
  Future<UserSession> verifyOtp({
    required String otpCode,
    required PendingAuthContext context,
  }) async {
    final digits = otpCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      throw const AppException('Enter the 6-digit code from the OTP message.');
    }

    final data = await _publicApiClient.post<JsonMap>(
      '/auth/verify-phone-otp',
      data: {
        'phone': context.phoneNumber.trim(),
        'code': digits,
        'purpose': _otpPurposeForContext(context),
        if (context.mode == AuthFlowMode.register) ...{
          'fullName': context.fullName?.trim(),
          'email': context.email?.trim(),
        },
      },
      extra: const {'skipAuth': true},
      mapper: asJsonMap,
    );

    return _parseSessionPayload(data);
  }

  String _otpPurposeForContext(PendingAuthContext context) {
    return switch (context.mode) {
      AuthFlowMode.login => 'LOGIN',
      AuthFlowMode.register => 'REGISTER',
    };
  }

  String? _extractMagicLinkToken(Uri uri) {
    final query = <String, dynamic>{...uri.queryParameters};
    if (query.isEmpty && uri.fragment.isNotEmpty) {
      query.addAll(Uri.splitQueryString(uri.fragment));
    }
    final token = query['token'];
    return token is String ? token.trim() : null;
  }

  EmailLinkResultStatus _mapEmailLinkError(AppException error, Uri uri) {
    final fromQuery = EmailLinkResultStatusX.fromQuery(
      uri.queryParameters['status'] ??
          (uri.fragment.isEmpty
              ? null
              : Uri.splitQueryString(uri.fragment)['status']),
    );
    if (fromQuery != EmailLinkResultStatus.success) {
      return fromQuery;
    }

    return switch (error.statusCode) {
      409 => EmailLinkResultStatus.alreadyUsed,
      410 => EmailLinkResultStatus.expired,
      _ => EmailLinkResultStatus.invalid,
    };
  }

  UserSession _parseSessionPayload(JsonMap data) {
    final userJson = asJsonMap(data['user']);
    final tokensJson = asJsonMap(data['tokens']);
    final activeRole = AppRoleX.fromQuery(userJson['activeRole'] as String?);

    return UserSession(
      user: SessionUser(
        id: userJson['id'] as String,
        fullName: userJson['fullName'] as String? ?? 'Reziphay User',
        email: userJson['email'] as String? ?? '',
        phoneNumber:
            userJson['phone'] as String? ??
            userJson['phoneNumber'] as String? ??
            '',
        roles: (userJson['roles'] as List<dynamic>? ?? const <dynamic>[])
            .map((role) => AppRoleX.fromQuery(role as String?))
            .toList(growable: false),
        status: UserStatusX.parse(userJson['status'] as String?),
      ),
      activeRole: activeRole,
      tokens: AuthTokens(
        accessToken: tokensJson['accessToken'] as String,
        refreshToken: tokensJson['refreshToken'] as String,
        accessTokenExpiresAt: _parseDateTime(
          tokensJson['accessTokenExpiresAt'],
        ),
      ),
    );
  }
}

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

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }

  throw const AppException(
    'Unexpected date value returned by the server.',
    type: AppExceptionType.server,
  );
}
