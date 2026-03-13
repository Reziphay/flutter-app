import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
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

  group('BackendNotificationsRepository', () {
    test(
      'customer-only users do not receive provider-scoped backend notifications',
      () async {
        final repository = BackendNotificationsRepository(
          apiClient: _FakeNotificationsApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/notifications') {
                return {
                  'items': [
                    {
                      'id': 'notif_customer',
                      'type': 'RESERVATION_CONFIRMED',
                      'title': 'Reservation confirmed',
                      'body': 'Your slot is confirmed.',
                      'createdAt': '2026-03-13T09:00:00.000Z',
                      'isRead': false,
                      'roleScope': 'UCR',
                      'destination': {
                        'type': 'CUSTOMER_RESERVATION',
                        'entityId': 'r_1002',
                        'role': 'UCR',
                      },
                    },
                    {
                      'id': 'notif_provider',
                      'type': 'RESERVATION_RECEIVED',
                      'title': 'Reservation received',
                      'body': 'New request waiting.',
                      'createdAt': '2026-03-13T09:05:00.000Z',
                      'isRead': false,
                      'roleScope': 'USO',
                      'destination': {
                        'type': 'PROVIDER_RESERVATION',
                        'entityId': 'r_1006',
                        'role': 'USO',
                      },
                    },
                  ],
                };
              }
              throw StateError('Unexpected GET path $path');
            },
          ),
        );

        final customerOnly = await repository.getNotifications([
          AppRole.customer,
        ]);
        final providerCapable = await repository.getNotifications([
          AppRole.customer,
          AppRole.provider,
        ]);

        expect(customerOnly.map((item) => item.id), ['notif_customer']);
        expect(
          providerCapable.any((item) => item.id == 'notif_provider'),
          isTrue,
        );
      },
    );

    test(
      'opening a provider backend notification marks it read and switches active role',
      () async {
        final sessionStore = InMemorySessionStore();
        final repository = BackendNotificationsRepository(
          apiClient: _FakeNotificationsApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/notifications') {
                return {
                  'items': [
                    {
                      'id': 'notif_provider',
                      'type': 'RESERVATION_RECEIVED',
                      'title': 'Reservation received',
                      'body': 'Amina Hasanli requested a reservation.',
                      'createdAt': '2026-03-13T09:05:00.000Z',
                      'isRead': false,
                      'roleScope': 'USO',
                      'metadata': {'reservationId': 'r_1006', 'role': 'USO'},
                    },
                  ],
                };
              }
              throw StateError('Unexpected GET path $path');
            },
            onPost: ({required path, data, queryParameters}) {
              if (path == '/notifications/notif_provider/read') {
                return <String, dynamic>{};
              }
              throw StateError('Unexpected POST path $path');
            },
          ),
        );
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
        final providerNotification = notifications.single;

        final destination = await container
            .read(notificationsActionsProvider)
            .openNotification(providerNotification);

        final updatedNotifications = await repository.getNotifications([
          AppRole.customer,
          AppRole.provider,
        ]);

        expect(destination.role, AppRole.provider);
        expect(
          destination.type,
          NotificationDestinationType.providerReservation,
        );
        expect(
          container.read(sessionControllerProvider).session?.activeRole,
          AppRole.provider,
        );
        expect(updatedNotifications.single.isRead, isTrue);
      },
    );

    test(
      'markAllRead falls back to local overrides when backend mark-all is unavailable',
      () async {
        final repository = BackendNotificationsRepository(
          apiClient: _FakeNotificationsApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/notifications') {
                return {
                  'items': [
                    {
                      'id': 'notif_customer',
                      'type': 'RESERVATION_CONFIRMED',
                      'title': 'Reservation confirmed',
                      'body': 'Your slot is confirmed.',
                      'createdAt': '2026-03-13T09:00:00.000Z',
                      'isRead': false,
                      'destination': {
                        'type': 'CUSTOMER_RESERVATION',
                        'entityId': 'r_1002',
                        'role': 'UCR',
                      },
                    },
                  ],
                };
              }
              throw StateError('Unexpected GET path $path');
            },
            onPost: ({required path, data, queryParameters}) {
              if (path == '/notifications/mark-all-read') {
                throw const AppException(
                  'Not found',
                  type: AppExceptionType.unknown,
                  statusCode: 404,
                );
              }
              throw StateError('Unexpected POST path $path');
            },
          ),
        );

        await repository.markAllRead([AppRole.customer]);
        final notifications = await repository.getNotifications([
          AppRole.customer,
        ]);

        expect(notifications.single.isRead, isTrue);
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

class _FakeNotificationsApiClient extends ApiClient {
  _FakeNotificationsApiClient({this.onGet, this.onPost}) : super(Dio());

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
