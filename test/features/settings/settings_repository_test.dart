import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/features/settings/data/settings_repository.dart';
import 'package:reziphay_mobile/features/settings/models/settings_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/auth_tokens.dart';
import 'package:reziphay_mobile/shared/models/session_user.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

void main() {
  group('LocalSettingsRepository', () {
    test(
      'requestPushPermission grants permission and issues a device token',
      () async {
        final repository = LocalSettingsRepository(
          store: InMemorySettingsStore(),
        );

        final pushState = await repository.requestPushPermission();

        expect(pushState.permissionStatus, PushPermissionStatus.granted);
        expect(pushState.deviceToken, isNotNull);
        expect(pushState.lastSyncedAt, isNotNull);
      },
    );

    test('reminder lead time persists through the store', () async {
      final store = InMemorySettingsStore();
      final repository = LocalSettingsRepository(store: store);

      await repository.setReminderLeadTime(ReminderLeadTime.oneDay);
      final reloadedRepository = LocalSettingsRepository(store: store);
      final settings = await reloadedRepository.getSettings();

      expect(settings.reminderLeadTime, ReminderLeadTime.oneDay);
    });
  });

  group('BackendSettingsRepository', () {
    test(
      'getSettings merges remote reminder settings for customer sessions',
      () async {
        final repository = BackendSettingsRepository(
          store: InMemorySettingsStore(),
          apiClient: _FakeApiClient(
            onGet: ({required path, queryParameters}) => {
              'notificationSettings': {
                'upcomingAppointmentReminders': {
                  'enabled': true,
                  'leadMinutes': [1440],
                },
              },
            },
          ),
          readSession: _buildCustomerSession,
        );

        final settings = await repository.getSettings();

        expect(settings.upcomingRemindersEnabled, isTrue);
        expect(settings.reminderLeadTime, ReminderLeadTime.oneDay);
      },
    );

    test(
      'setUpcomingRemindersEnabled sends the backend patch payload',
      () async {
        Map<String, dynamic>? capturedBody;

        final repository = BackendSettingsRepository(
          store: InMemorySettingsStore(),
          apiClient: _FakeApiClient(
            onPatch: ({required path, queryParameters, data}) {
              capturedBody = data as Map<String, dynamic>;
              return {
                'notificationSettings': {
                  'upcomingAppointmentReminders': {
                    'enabled': false,
                    'leadMinutes': [120],
                  },
                },
              };
            },
          ),
          readSession: _buildCustomerSession,
        );

        await repository.setUpcomingRemindersEnabled(false);
        final settings = await repository.getSettings();

        expect(capturedBody, {
          'upcomingAppointmentReminders': {
            'enabled': false,
            'leadMinutes': [360],
          },
        });
        expect(settings.upcomingRemindersEnabled, isFalse);
        expect(settings.reminderLeadTime, ReminderLeadTime.twoHours);
      },
    );
  });
}

UserSession _buildCustomerSession() {
  return UserSession(
    user: const SessionUser(
      id: 'usr_settings',
      fullName: 'Settings User',
      email: 'settings@reziphay.com',
      phoneNumber: '+994500000222',
      roles: [AppRole.customer],
      status: UserStatus.active,
    ),
    activeRole: AppRole.customer,
    tokens: AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresAt: DateTime(2099),
    ),
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.onGet, this.onPatch}) : super(Dio());

  final dynamic Function({
    required String path,
    Map<String, dynamic>? queryParameters,
  })?
  onGet;
  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPatch;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(
      onGet?.call(path: path, queryParameters: queryParameters) ??
          <String, dynamic>{},
    );
  }

  @override
  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(
      onPatch?.call(path: path, data: data, queryParameters: queryParameters) ??
          <String, dynamic>{},
    );
  }
}
