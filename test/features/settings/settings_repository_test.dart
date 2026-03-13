import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/features/push/data/push_messaging_service.dart';
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
          pushMessagingService: _FakePushMessagingService(
            permissionStatus: PushPermissionStatus.granted,
            deviceToken: 'push_token_123',
          ),
        );

        final pushState = await repository.requestPushPermission();

        expect(pushState.permissionStatus, PushPermissionStatus.granted);
        expect(pushState.deviceToken, 'push_token_123');
        expect(pushState.lastSyncedAt, isNull);
      },
    );

    test(
      'requestPushPermission clears push registration when permission is denied',
      () async {
        final store = InMemorySettingsStore();
        await store.writePushState(
          PushRegistrationState(
            permissionStatus: PushPermissionStatus.granted,
            deviceToken: 'stale_token',
            lastSyncedAt: DateTime.parse('2026-03-13T10:00:00.000Z'),
          ),
        );
        final repository = LocalSettingsRepository(
          store: store,
          pushMessagingService: _FakePushMessagingService(
            permissionStatus: PushPermissionStatus.denied,
          ),
        );

        final pushState = await repository.requestPushPermission();

        expect(pushState.permissionStatus, PushPermissionStatus.denied);
        expect(pushState.deviceToken, isNull);
        expect(pushState.lastSyncedAt, isNull);
      },
    );

    test(
      'syncPushRegistration pulls a token from the messaging service',
      () async {
        final store = InMemorySettingsStore();
        await store.writePushState(
          const PushRegistrationState(
            permissionStatus: PushPermissionStatus.granted,
          ),
        );
        final repository = LocalSettingsRepository(
          store: store,
          pushMessagingService: _FakePushMessagingService(
            permissionStatus: PushPermissionStatus.granted,
            deviceToken: 'fresh_push_token',
          ),
        );

        final pushState = await repository.syncPushRegistration();

        expect(pushState.deviceToken, 'fresh_push_token');
        expect(pushState.lastSyncedAt, isNotNull);
      },
    );

    test('reminder lead time persists through the store', () async {
      final store = InMemorySettingsStore();
      final repository = LocalSettingsRepository(
        store: store,
        pushMessagingService: _FakePushMessagingService(
          permissionStatus: PushPermissionStatus.granted,
        ),
      );

      await repository.setReminderLeadTime(ReminderLeadTime.oneDay);
      final reloadedRepository = LocalSettingsRepository(
        store: store,
        pushMessagingService: _FakePushMessagingService(
          permissionStatus: PushPermissionStatus.granted,
        ),
      );
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
          pushMessagingService: _FakePushMessagingService(
            permissionStatus: PushPermissionStatus.granted,
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
          pushMessagingService: _FakePushMessagingService(
            permissionStatus: PushPermissionStatus.granted,
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

    test(
      'requestPushPermission registers the token with backend when a session exists',
      () async {
        Map<String, dynamic>? capturedBody;

        final repository = BackendSettingsRepository(
          store: InMemorySettingsStore(),
          apiClient: _FakeApiClient(
            onPost: ({required path, queryParameters, data}) {
              capturedBody = data as Map<String, dynamic>;
              return {
                'pushRegistration': {
                  'token': capturedBody!['token'],
                  'registeredAt': '2026-03-13T10:00:00.000Z',
                },
              };
            },
          ),
          pushMessagingService: _FakePushMessagingService(
            permissionStatus: PushPermissionStatus.granted,
            deviceToken: 'backend_push_token',
          ),
          readSession: _buildCustomerSession,
        );

        final pushState = await repository.requestPushPermission();

        expect(capturedBody?['provider'], 'FCM');
        expect(capturedBody?['platform'], 'mobile');
        expect(pushState.deviceToken, 'backend_push_token');
        expect(
          pushState.lastSyncedAt,
          DateTime.parse('2026-03-13T10:00:00.000Z'),
        );
      },
    );

    test(
      'syncPushRegistration sends the backend token registration payload',
      () async {
        Map<String, dynamic>? capturedBody;

        final repository = BackendSettingsRepository(
          store: InMemorySettingsStore(),
          apiClient: _FakeApiClient(
            onPost: ({required path, queryParameters, data}) {
              capturedBody = data as Map<String, dynamic>;
              return <String, dynamic>{};
            },
          ),
          pushMessagingService: _FakePushMessagingService(
            permissionStatus: PushPermissionStatus.granted,
            deviceToken: 'synced_push_token',
          ),
          readSession: _buildCustomerSession,
        );

        await repository.requestPushPermission();
        final pushState = await repository.syncPushRegistration();

        expect(capturedBody?['token'], isNotNull);
        expect(capturedBody?['pushToken'], capturedBody?['token']);
        expect(pushState.lastSyncedAt, isNotNull);
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
  _FakeApiClient({this.onGet, this.onPatch, this.onPost}) : super(Dio());

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
  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPost;

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

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(
      onPost?.call(path: path, data: data, queryParameters: queryParameters) ??
          <String, dynamic>{},
    );
  }
}

class _FakePushMessagingService implements PushMessagingService {
  _FakePushMessagingService({
    required this.permissionStatus,
    String? deviceToken,
  }) : _deviceToken = deviceToken;

  final PushPermissionStatus permissionStatus;
  final String? _deviceToken;

  @override
  Stream<PushInboundEvent> get inboundEvents => const Stream.empty();

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> getDeviceToken() async => _deviceToken;

  @override
  Future<void> initialize() async {}

  @override
  Future<PushPermissionStatus> requestPermission() async => permissionStatus;

  @override
  Future<PushInboundEvent?> takeInitialEvent() async => null;
}
