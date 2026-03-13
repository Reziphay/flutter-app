import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/features/settings/data/settings_repository.dart';
import 'package:reziphay_mobile/features/settings/models/settings_models.dart';

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
}
