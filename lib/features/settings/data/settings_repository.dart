import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
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
  LocalSettingsRepository({required SettingsStore store}) : _store = store;

  final SettingsStore _store;

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
    final currentState = await getPushState();
    final updatedState = currentState.copyWith(
      permissionStatus: PushPermissionStatus.granted,
      deviceToken: currentState.deviceToken ?? _issueToken(),
      lastSyncedAt: DateTime.now(),
    );

    _cachedPushState = updatedState;
    await _store.writePushState(updatedState);
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
    final pushState = await getPushState();
    if (!pushState.canSync) {
      throw const AppException(
        'Enable push permissions before syncing this device.',
      );
    }

    final updatedState = pushState.copyWith(
      deviceToken: pushState.deviceToken ?? _issueToken(),
      lastSyncedAt: DateTime.now(),
    );
    _cachedPushState = updatedState;
    await _store.writePushState(updatedState);
    return updatedState;
  }

  Future<void> _persistSettings(AppSettings settings) async {
    await _delay();
    _cachedSettings = settings;
    await _store.writeSettings(settings);
  }

  String _issueToken() {
    final formatter = DateFormat('yyyyMMddHHmmss');
    return 'mock_push_${formatter.format(DateTime.now())}';
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 120));
}

class BackendSettingsRepository implements SettingsRepository {
  BackendSettingsRepository({
    required SettingsStore store,
    required ApiClient apiClient,
    required UserSession? Function() readSession,
  }) : _local = LocalSettingsRepository(store: store),
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
  Future<PushRegistrationState> requestPushPermission() =>
      _local.requestPushPermission();

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
  Future<PushRegistrationState> syncPushRegistration() =>
      _local.syncPushRegistration();

  bool _canUseRemoteReminderSettings(UserSession? session) {
    return session != null &&
        session.availableRoles.contains(AppRole.customer) &&
        session.user.status == UserStatus.active;
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
