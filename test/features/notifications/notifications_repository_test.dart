import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/storage/session_store.dart';
import 'package:reziphay_mobile/features/notifications/data/notifications_repository.dart';
import 'package:reziphay_mobile/features/notifications/models/app_notification_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/auth_tokens.dart';
import 'package:reziphay_mobile/shared/models/session_user.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

void main() {
  group('MockNotificationsRepository', () {
    test(
      'customer-only users do not receive provider-scoped notifications',
      () async {
        final repository = MockNotificationsRepository();

        final customerOnly = await repository.getNotifications([
          AppRole.customer,
        ]);
        final providerCapable = await repository.getNotifications([
          AppRole.customer,
          AppRole.provider,
        ]);

        expect(
          customerOnly.any((item) => item.roleScope == AppRole.provider),
          isFalse,
        );
        expect(
          providerCapable.any((item) => item.roleScope == AppRole.provider),
          isTrue,
        );
      },
    );

    test(
      'opening a provider notification marks it read and switches active role',
      () async {
        final sessionStore = InMemorySessionStore();
        final repository = MockNotificationsRepository();
        final container = ProviderContainer(
          overrides: [
            sessionStoreProvider.overrideWithValue(sessionStore),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            notificationsRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        await sessionStore.writeSession(
          _buildSession(
            roles: const [AppRole.customer, AppRole.provider],
            activeRole: AppRole.customer,
          ),
        );
        await container.read(sessionControllerProvider.notifier).bootstrap();

        final notifications = await container.read(
          notificationsProvider.future,
        );
        final providerNotification = notifications.firstWhere(
          (item) =>
              item.destination.type ==
              NotificationDestinationType.providerReservation,
        );

        final destination = await container
            .read(notificationsActionsProvider)
            .openNotification(providerNotification);

        final updatedNotifications = await repository.getNotifications([
          AppRole.customer,
          AppRole.provider,
        ]);
        final updatedItem = updatedNotifications.firstWhere(
          (item) => item.id == providerNotification.id,
        );

        expect(destination.role, AppRole.provider);
        expect(
          container.read(sessionControllerProvider).session?.activeRole,
          AppRole.provider,
        );
        expect(updatedItem.isRead, isTrue);
      },
    );
  });
}

UserSession _buildSession({
  required List<AppRole> roles,
  required AppRole activeRole,
}) {
  return UserSession(
    user: SessionUser(
      id: 'usr_phase5',
      fullName: 'Phase Five User',
      email: 'phase5@reziphay.com',
      phoneNumber: '+994500000123',
      roles: roles,
      status: UserStatus.active,
    ),
    activeRole: activeRole,
    tokens: AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
    ),
  );
}
