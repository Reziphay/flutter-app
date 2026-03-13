import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/push/data/push_messaging_service.dart';
import 'package:reziphay_mobile/features/settings/models/settings_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

abstract class SettingsStore {
  Future<AppSettings?> readSettings();
  Future<void> writeSettings(AppSettings settings);
  Future<PushRegistrationState?> readPushState();
  Future<void> writePushState(PushRegistrationState state);
}

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SecureSettingsStore(),
);

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<PushRegistrationState> getPushState();
  Future<void> setPushNotificationsEnabled(bool value);
  Future<void> setReservationUpdatesEnabled(bool value);
  Future<void> setUpcomingRemindersEnabled(bool value);
  Future<void> setReminderLeadTime(ReminderLeadTime value);
  Future<PushRegistrationState> requestPushPermission();
  Future<PushRegistrationState> syncPushRegistration();
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => BackendSettingsRepository(
    store: ref.watch(settingsStoreProvider),
    apiClient: ref.watch(apiClientProvider),
    pushMessagingService: ref.watch(pushMessagingServiceProvider),
    readSession: () => ref.read(sessionControllerProvider).session,
  ),
);

final appSettingsProvider = FutureProvider.autoDispose<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).getSettings(),
);

final pushRegistrationProvider =
    FutureProvider.autoDispose<PushRegistrationState>(
      (ref) => ref.watch(settingsRepositoryProvider).getPushState(),
    );

final settingsActionsProvider = Provider<SettingsActions>(
  (ref) => SettingsActions(ref),
);

class SettingsActions {
  SettingsActions(this.ref);

  final Ref ref;

  Future<void> setPushNotificationsEnabled(bool value) async {
    await ref
        .read(settingsRepositoryProvider)
        .setPushNotificationsEnabled(value);
    _invalidate();
  }

  Future<void> setReservationUpdatesEnabled(bool value) async {
    await ref
        .read(settingsRepositoryProvider)
        .setReservationUpdatesEnabled(value);
    _invalidate();
  }

  Future<void> setUpcomingRemindersEnabled(bool value) async {
    await ref
        .read(settingsRepositoryProvider)
        .setUpcomingRemindersEnabled(value);
    _invalidate();
  }

  Future<void> setReminderLeadTime(ReminderLeadTime value) async {
    await ref.read(settingsRepositoryProvider).setReminderLeadTime(value);
    _invalidate();
  }

  Future<void> requestPushPermission() async {
    await ref.read(settingsRepositoryProvider).requestPushPermission();
    _invalidate();
  }

  Future<void> syncPushRegistration() async {
    await ref.read(settingsRepositoryProvider).syncPushRegistration();
    _invalidate();
  }

  void _invalidate() {
    ref.invalidate(appSettingsProvider);
    ref.invalidate(pushRegistrationProvider);
  }
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository({
    required SettingsStore store,
    required PushMessagingService pushMessagingService,
  }) : _store = store,
       _pushMessagingService = pushMessagingService;

  final SettingsStore _store;
  final PushMessagingService _pushMessagingService;

  AppSettings? _cachedSettings;
  PushRegistrationState? _cachedPushState;

  @override
  Future<AppSettings> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    _cachedSettings = await _store.readSettings() ?? AppSettings.initial();
    return _cachedSettings!;
  }

  @override
  Future<PushRegistrationState> getPushState() async {
    if (_cachedPushState != null) {
      return _cachedPushState!;
    }

    _cachedPushState =
        await _store.readPushState() ?? PushRegistrationState.initial();
    return _cachedPushState!;
  }

  @override
  Future<PushRegistrationState> requestPushPermission() async {
    await _delay();
    await _pushMessagingService.initialize();
    final currentState = await getPushState();
    final permissionStatus = await _pushMessagingService.requestPermission();
    final deviceToken = permissionStatus == PushPermissionStatus.granted
        ? await _pushMessagingService.getDeviceToken() ??
              currentState.deviceToken
        : null;
    final updatedState = currentState.copyWith(
      permissionStatus: permissionStatus,
      deviceToken: deviceToken,
      clearDeviceToken: permissionStatus != PushPermissionStatus.granted,
      clearLastSyncedAt:
          permissionStatus != PushPermissionStatus.granted ||
          deviceToken == null ||
          deviceToken.isEmpty,
    );

    await _persistPushState(updatedState);
    return updatedState;
  }

  @override
  Future<void> setPushNotificationsEnabled(bool value) async {
    final settings = await getSettings();
    await _persistSettings(settings.copyWith(pushNotificationsEnabled: value));
  }

  @override
  Future<void> setReminderLeadTime(ReminderLeadTime value) async {
    final settings = await getSettings();
    await _persistSettings(settings.copyWith(reminderLeadTime: value));
  }

  @override
  Future<void> setReservationUpdatesEnabled(bool value) async {
    final settings = await getSettings();
    await _persistSettings(settings.copyWith(reservationUpdatesEnabled: value));
  }

  @override
  Future<void> setUpcomingRemindersEnabled(bool value) async {
    final settings = await getSettings();
    await _persistSettings(settings.copyWith(upcomingRemindersEnabled: value));
  }

  @override
  Future<PushRegistrationState> syncPushRegistration() async {
    await _delay();
    await _pushMessagingService.initialize();
    final pushState = await getPushState();
    if (!pushState.canSync) {
      throw const AppException(
        'Enable push permissions before syncing this device.',
      );
    }

    final deviceToken =
        pushState.deviceToken ?? await _pushMessagingService.getDeviceToken();
    if (deviceToken == null || deviceToken.isEmpty) {
      throw const AppException(
        'Push token is unavailable on this device right now.',
      );
    }

    final updatedState = pushState.copyWith(
      deviceToken: deviceToken,
      lastSyncedAt: DateTime.now(),
    );
    await _persistPushState(updatedState);
    return updatedState;
  }

  Future<void> _persistSettings(AppSettings settings) async {
    await _delay();
    _cachedSettings = settings;
    await _store.writeSettings(settings);
  }

  Future<void> _persistPushState(PushRegistrationState state) async {
    _cachedPushState = state;
    await _store.writePushState(state);
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 120));
}

class BackendSettingsRepository implements SettingsRepository {
  BackendSettingsRepository({
    required SettingsStore store,
    required ApiClient apiClient,
    required PushMessagingService pushMessagingService,
    required UserSession? Function() readSession,
  }) : _local = LocalSettingsRepository(
         store: store,
         pushMessagingService: pushMessagingService,
       ),
       _apiClient = apiClient,
       _readSession = readSession;

  final LocalSettingsRepository _local;
  final ApiClient _apiClient;
  final UserSession? Function() _readSession;

  @override
  Future<AppSettings> getSettings() async {
    final localSettings = await _local.getSettings();
    if (!_canUseRemoteReminderSettings(_readSession())) {
      return localSettings;
    }

    try {
      final data = await _apiClient.get<JsonMap>(
        '/users/me/notification-settings',
        mapper: asJsonMap,
      );
      final merged = _mergeRemoteNotificationSettings(
        localSettings,
        asJsonMap(data['notificationSettings']),
      );
      await _local._persistSettings(merged);
      return merged;
    } on AppException {
      return localSettings;
    }
  }

  @override
  Future<PushRegistrationState> getPushState() => _local.getPushState();

  @override
  Future<PushRegistrationState> requestPushPermission() async {
    final localState = await _local.requestPushPermission();
    if (!_canUseRemotePushRegistration(_readSession()) || !localState.canSync) {
      return localState;
    }

    try {
      return await _syncRemotePushRegistration(localState);
    } on AppException {
      return localState;
    }
  }

  @override
  Future<void> setPushNotificationsEnabled(bool value) =>
      _local.setPushNotificationsEnabled(value);

  @override
  Future<void> setReminderLeadTime(ReminderLeadTime value) async {
    final current = await _local.getSettings();
    final next = current.copyWith(reminderLeadTime: value);

    if (_canUseRemoteReminderSettings(_readSession())) {
      final synced = await _updateRemoteReminderSettings(next);
      await _local._persistSettings(synced);
      return;
    }

    await _local._persistSettings(next);
  }

  @override
  Future<void> setReservationUpdatesEnabled(bool value) =>
      _local.setReservationUpdatesEnabled(value);

  @override
  Future<void> setUpcomingRemindersEnabled(bool value) async {
    final current = await _local.getSettings();
    final next = current.copyWith(upcomingRemindersEnabled: value);

    if (_canUseRemoteReminderSettings(_readSession())) {
      final synced = await _updateRemoteReminderSettings(next);
      await _local._persistSettings(synced);
      return;
    }

    await _local._persistSettings(next);
  }

  @override
  Future<PushRegistrationState> syncPushRegistration() async {
    final localState = await _local.syncPushRegistration();
    if (!_canUseRemotePushRegistration(_readSession())) {
      return localState;
    }

    return _syncRemotePushRegistration(localState);
  }

  bool _canUseRemoteReminderSettings(UserSession? session) {
    return session != null &&
        session.availableRoles.contains(AppRole.customer) &&
        session.user.status == UserStatus.active;
  }

  bool _canUseRemotePushRegistration(UserSession? session) {
    return session != null && session.user.status == UserStatus.active;
  }

  Future<PushRegistrationState> _syncRemotePushRegistration(
    PushRegistrationState localState,
  ) async {
    final token = localState.deviceToken;
    if (token == null || token.isEmpty) {
      return localState;
    }

    final endpoints = [
      '/users/me/push-tokens',
      '/users/me/push-token',
      '/users/me/devices/push-token',
    ];
    final errors = <AppException>[];

    for (final endpoint in endpoints) {
      try {
        final data = await _apiClient.post<dynamic>(
          endpoint,
          data: {
            'token': token,
            'pushToken': token,
            'provider': 'FCM',
            'platform': 'mobile',
          },
          mapper: (payload) => payload,
        );

        final syncedState = _mergeRemotePushState(localState, data);
        await _local._persistPushState(syncedState);
        return syncedState;
      } on AppException catch (error) {
        if (_shouldTryNextPushEndpoint(error)) {
          errors.add(error);
          continue;
        }
        rethrow;
      }
    }

    final lastError = errors.isEmpty ? null : errors.last;
    throw AppException(
      'Push token registration is unavailable right now.',
      type: AppExceptionType.server,
      statusCode: lastError?.statusCode,
      code: lastError?.code,
      details: lastError?.details,
      requestId: lastError?.requestId,
    );
  }

  PushRegistrationState _mergeRemotePushState(
    PushRegistrationState localState,
    dynamic payload,
  ) {
    final entity = payload is Map ? asJsonMap(payload) : <String, dynamic>{};
    final registration = entity['pushRegistration'] is Map
        ? asJsonMap(entity['pushRegistration'])
        : entity['device'] is Map
        ? asJsonMap(entity['device'])
        : entity['item'] is Map
        ? asJsonMap(entity['item'])
        : entity;

    final remoteToken =
        registration['token'] as String? ??
        registration['pushToken'] as String? ??
        localState.deviceToken;
    final syncedAt = _parseDateTime(
      registration['lastSyncedAt'] ??
          registration['registeredAt'] ??
          registration['createdAt'],
    );

    return localState.copyWith(
      deviceToken: remoteToken,
      lastSyncedAt: syncedAt ?? DateTime.now(),
    );
  }

  bool _shouldTryNextPushEndpoint(AppException error) {
    return switch (error.statusCode) {
      404 || 405 || 501 => true,
      _ => false,
    };
  }

  Future<AppSettings> _updateRemoteReminderSettings(AppSettings next) async {
    final data = await _apiClient.patch<JsonMap>(
      '/users/me/notification-settings',
      data: {
        'upcomingAppointmentReminders': {
          'enabled': next.upcomingRemindersEnabled,
          'leadMinutes': [_leadMinutesFor(next.reminderLeadTime)],
        },
      },
      mapper: asJsonMap,
    );

    return _mergeRemoteNotificationSettings(
      next,
      asJsonMap(data['notificationSettings']),
    );
  }

  AppSettings _mergeRemoteNotificationSettings(
    AppSettings local,
    JsonMap notificationSettings,
  ) {
    final reminderSettings =
        notificationSettings['upcomingAppointmentReminders'] == null
        ? <String, dynamic>{}
        : asJsonMap(notificationSettings['upcomingAppointmentReminders']);
    final leadMinutes =
        (reminderSettings['leadMinutes'] as List<dynamic>? ?? const [])
            .map((value) => value as int)
            .toList(growable: false);

    return local.copyWith(
      upcomingRemindersEnabled:
          reminderSettings['enabled'] as bool? ??
          local.upcomingRemindersEnabled,
      reminderLeadTime: _leadTimeFromRemote(leadMinutes),
    );
  }

  ReminderLeadTime _leadTimeFromRemote(List<int> leadMinutes) {
    if (leadMinutes.isEmpty) {
      return ReminderLeadTime.sixHours;
    }

    const supported = <ReminderLeadTime, int>{
      ReminderLeadTime.twoHours: 120,
      ReminderLeadTime.sixHours: 360,
      ReminderLeadTime.oneDay: 1440,
    };

    final primary = leadMinutes.first;
    ReminderLeadTime bestMatch = ReminderLeadTime.sixHours;
    var bestDifference = 1 << 30;

    for (final entry in supported.entries) {
      final difference = (entry.value - primary).abs();
      if (difference < bestDifference) {
        bestDifference = difference;
        bestMatch = entry.key;
      }
    }

    return bestMatch;
  }

  int _leadMinutesFor(ReminderLeadTime leadTime) {
    return switch (leadTime) {
      ReminderLeadTime.twoHours => 120,
      ReminderLeadTime.sixHours => 360,
      ReminderLeadTime.oneDay => 1440,
    };
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}

class SecureSettingsStore implements SettingsStore {
  SecureSettingsStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _settingsKey = 'reziphay.settings';
  static const _pushStateKey = 'reziphay.push_state';

  final FlutterSecureStorage _storage;

  @override
  Future<AppSettings?> readSettings() async {
    final raw = await _storage.read(key: _settingsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppSettings.fromJson(decoded);
  }

  @override
  Future<PushRegistrationState?> readPushState() async {
    final raw = await _storage.read(key: _pushStateKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return PushRegistrationState.fromJson(decoded);
  }

  @override
  Future<void> writePushState(PushRegistrationState state) async {
    await _storage.write(key: _pushStateKey, value: jsonEncode(state.toJson()));
  }

  @override
  Future<void> writeSettings(AppSettings settings) async {
    await _storage.write(
      key: _settingsKey,
      value: jsonEncode(settings.toJson()),
    );
  }
}

class InMemorySettingsStore implements SettingsStore {
  AppSettings? _settings;
  PushRegistrationState? _pushState;

  @override
  Future<PushRegistrationState?> readPushState() async => _pushState;

  @override
  Future<AppSettings?> readSettings() async => _settings;

  @override
  Future<void> writePushState(PushRegistrationState state) async {
    _pushState = state;
  }

  @override
  Future<void> writeSettings(AppSettings settings) async {
    _settings = settings;
  }
}
