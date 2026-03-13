import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/auth_tokens.dart';
import 'package:reziphay_mobile/shared/models/session_user.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

void main() {
  group('MockReservationsRepository', () {
    late MockReservationsRepository repository;

    setUp(() {
      repository = MockReservationsRepository(
        discoveryRepository: MockDiscoveryRepository(),
      );
    });

    test('customer reservations are scoped by customer context id', () async {
      final before = await repository.getCustomerReservations('current-user');

      final reservationId = await repository.createReservation(
        serviceId: 'classic-haircut',
        scheduledAt: DateTime.now().add(const Duration(days: 3)),
        note: 'Need a sharp finish.',
        customerId: 'current-user',
        customerName: 'Test Customer',
      );

      final customerReservations = await repository.getCustomerReservations(
        'current-user',
      );
      final otherReservations = await repository.getCustomerReservations(
        'other-user',
      );

      expect(customerReservations.length, before.length + 1);
      expect(
        customerReservations.any(
          (reservation) => reservation.id == reservationId,
        ),
        isTrue,
      );
      expect(
        otherReservations.any((reservation) => reservation.id == reservationId),
        isFalse,
      );
    });

    test(
      'provider accepting a customer change updates the scheduled time',
      () async {
        final originalTime = DateTime.now().add(
          const Duration(days: 2, hours: 2),
        );
        final proposedTime = originalTime.add(const Duration(hours: 3));

        final reservationId = await repository.createReservation(
          serviceId: 'precision-beard-trim',
          scheduledAt: originalTime,
          note: '',
          customerId: 'current-user',
          customerName: 'Test Customer',
        );

        await repository.requestCustomerChange(
          reservationId: reservationId,
          proposedTime: proposedTime,
          reason: 'Need a later slot.',
        );
        await repository.acceptProviderReservation(reservationId);

        final detail = await repository.getCustomerReservationDetail(
          reservationId,
          'current-user',
        );

        expect(detail.summary.status, ReservationStatus.confirmed);
        expect(detail.summary.scheduledAt, proposedTime);
        expect(detail.changeHistory.first.statusLabel, 'Accepted by provider');
      },
    );

    test(
      'provider can decline a customer change and keep the original schedule',
      () async {
        final originalTime = DateTime.now().add(
          const Duration(days: 2, hours: 1),
        );
        final proposedTime = originalTime.add(const Duration(hours: 2));

        final reservationId = await repository.createReservation(
          serviceId: 'precision-beard-trim',
          scheduledAt: originalTime,
          note: '',
          customerId: 'current-user',
          customerName: 'Test Customer',
        );

        await repository.requestCustomerChange(
          reservationId: reservationId,
          proposedTime: proposedTime,
          reason: 'Need a later arrival window.',
        );
        await repository.declineCustomerChange(
          reservationId: reservationId,
          reason: 'The original slot is the only one the team can keep.',
        );

        final detail = await repository.getCustomerReservationDetail(
          reservationId,
          'current-user',
        );

        expect(detail.summary.status, ReservationStatus.confirmed);
        expect(detail.summary.scheduledAt, originalTime);
        expect(detail.changeHistory.first.statusLabel, 'Declined by provider');
        expect(detail.timeline.first.title, 'Original time kept');
      },
    );

    test(
      'customer accepting a provider change updates the scheduled time',
      () async {
        final originalTime = DateTime.now().add(
          const Duration(days: 1, hours: 4),
        );
        final proposedTime = originalTime.add(const Duration(hours: 2));

        final reservationId = await repository.createReservation(
          serviceId: 'precision-beard-trim',
          scheduledAt: originalTime,
          note: '',
          customerId: 'current-user',
          customerName: 'Test Customer',
        );

        await repository.requestProviderChange(
          reservationId: reservationId,
          proposedTime: proposedTime,
          reason: 'Need to move this slightly later.',
        );
        await repository.acceptCustomerChange(reservationId);

        final detail = await repository.getCustomerReservationDetail(
          reservationId,
          'current-user',
        );

        expect(detail.summary.status, ReservationStatus.confirmed);
        expect(detail.summary.scheduledAt, proposedTime);
        expect(detail.changeHistory.first.statusLabel, 'Accepted by customer');
      },
    );

    test(
      'provider dashboard treats customer change requests as urgent',
      () async {
        final reservationId = await repository.createReservation(
          serviceId: 'precision-beard-trim',
          scheduledAt: DateTime.now().add(const Duration(days: 2)),
          note: '',
          customerId: 'current-user',
          customerName: 'Test Customer',
        );

        await repository.requestCustomerChange(
          reservationId: reservationId,
          proposedTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
          reason: 'Running late.',
        );

        final dashboard = await repository.getProviderDashboard(
          'rauf-mammadov',
        );

        expect(
          dashboard.pendingRequests.any(
            (reservation) => reservation.id == reservationId,
          ),
          isTrue,
        );
      },
    );

    test(
      'provider dashboard does not treat provider-originated changes as urgent',
      () async {
        final reservationId = await repository.createReservation(
          serviceId: 'classic-haircut',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          note: '',
          customerId: 'current-user',
          customerName: 'Test Customer',
        );

        await repository.requestProviderChange(
          reservationId: reservationId,
          proposedTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          reason: 'Need to move this slightly later.',
        );

        final dashboard = await repository.getProviderDashboard(
          'rauf-mammadov',
        );

        expect(
          dashboard.pendingRequests.any(
            (reservation) => reservation.id == reservationId,
          ),
          isFalse,
        );
      },
    );

    test(
      'provider dashboard today list excludes cancelled reservations',
      () async {
        final reservationId = await repository.createReservation(
          serviceId: 'classic-haircut',
          scheduledAt: DateTime.now().add(const Duration(hours: 2)),
          note: '',
          customerId: 'current-user',
          customerName: 'Test Customer',
        );

        await repository.cancelProviderReservation(
          reservationId: reservationId,
          reason: 'Closed for the afternoon.',
        );

        final dashboard = await repository.getProviderDashboard(
          'rauf-mammadov',
        );

        expect(
          dashboard.todayReservations.any(
            (reservation) => reservation.id == reservationId,
          ),
          isFalse,
        );
      },
    );

    test(
      'customer can submit a no-show objection and penalty summary reflects review state',
      () async {
        await repository.submitNoShowObjection(
          reservationId: 'r_1005',
          customerId: 'current-user',
          reason: NoShowObjectionReason.arrivedOnTime,
          details: 'I arrived on time and waited outside the location.',
        );

        final detail = await repository.getCustomerReservationDetail(
          'r_1005',
          'current-user',
        );
        final penaltySummary = await repository.getCustomerPenaltySummary(
          'current-user',
        );

        expect(detail.noShowObjection, isNotNull);
        expect(
          detail.noShowObjection?.status,
          NoShowObjectionStatus.underReview,
        );
        expect(detail.timeline.first.title, 'No-show objection submitted');
        expect(penaltySummary.activePenaltyPoints, 1);
        expect(penaltySummary.objectionsUnderReview, 1);
      },
    );

    test(
      'provider dashboard service and brand counts reflect provider management changes',
      () async {
        final discoveryRepository = MockDiscoveryRepository();
        repository = MockReservationsRepository(
          discoveryRepository: discoveryRepository,
        );

        final brandId = await discoveryRepository.createProviderBrand(
          providerId: 'rauf-mammadov',
          draft: const ProviderBrandDraft(
            name: 'North Collective',
            headline:
                'Second provider-owned brand for dashboard count coverage.',
            addressLine: '9 Sahil Rd, Baku',
            description: 'Brand created during test coverage.',
            mapHint: 'Third floor studio.',
            visibilityLabels: [VisibilityLabel.common],
            openNow: true,
          ),
        );

        await discoveryRepository.createProviderService(
          providerId: 'rauf-mammadov',
          draft: ProviderServiceDraft(
            name: 'Deluxe lineup',
            categoryId: 'barber',
            categoryName: 'Barber',
            addressLine: '9 Sahil Rd, Baku',
            descriptionSnippet: 'New dashboard count service.',
            about: 'Service used to confirm dashboard counts.',
            approvalMode: ApprovalMode.manual,
            isAvailable: true,
            serviceType: ManagedServiceType.solo,
            waitingTimeMinutes: 10,
            leadTimeHours: 2,
            freeCancellationHours: 3,
            visibilityLabels: const [VisibilityLabel.common],
            requestableSlots: [
              AvailabilityWindow(
                startsAt: DateTime.now().add(const Duration(days: 3)),
                label: 'In 3 days · 12:00',
                available: true,
                note: 'Manual approval',
              ),
            ],
            exceptionNotes: const [],
            galleryMedia: const [
              AppMediaAsset.generated(
                id: 'north-collective-service-cover',
                label: 'Lineup station',
              ),
            ],
            brandId: brandId,
            brandName: 'North Collective',
            price: 42,
          ),
        );

        final dashboard = await repository.getProviderDashboard(
          'rauf-mammadov',
        );

        expect(dashboard.serviceCount, 3);
        expect(dashboard.brandCount, 2);
      },
    );
  });

  group('BackendReservationsRepository', () {
    test(
      'provider reservations map backend pending change requests into mobile summaries',
      () async {
        final repository = BackendReservationsRepository(
          apiClient: _FakeReservationsApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/reservations/incoming') {
                return {
                  'items': [
                    {
                      'id': 'res_change',
                      'status': 'CONFIRMED',
                      'createdAt': '2026-03-12T09:00:00.000Z',
                      'requestedStartAt': '2026-03-13T10:00:00.000Z',
                      'customerUser': {'fullName': 'Amina Hasanli'},
                      'service': {
                        'id': 'classic-haircut',
                        'name': 'Classic haircut',
                        'price': 28,
                        'addressLine': '14 Fountain Sq',
                        'approvalMode': 'MANUAL',
                        'brand': {'id': 'studio-north', 'name': 'Studio North'},
                        'owner': {
                          'id': 'rauf-mammadov',
                          'fullName': 'Rauf Mammadov',
                        },
                      },
                      'changeRequests': [
                        {
                          'id': 'chg_1',
                          'status': 'PENDING',
                          'requestedBy': 'CUSTOMER',
                          'proposedStartAt': '2026-03-13T11:00:00.000Z',
                          'createdAt': '2026-03-12T09:05:00.000Z',
                          'reason': 'Need a later slot.',
                        },
                      ],
                    },
                  ],
                };
              }

              throw StateError('Unexpected GET path $path');
            },
          ),
          discoveryRepository: MockDiscoveryRepository(),
          readSession: _buildProviderSession,
        );

        final reservations = await repository.getProviderReservations(
          'ignored-provider-id',
        );
        final summary = reservations.single;

        expect(summary.status, ReservationStatus.changeRequested);
        expect(summary.latestChangeRequestedBy, ReservationActor.customer);
        expect(
          summary.latestChangeProposedTime,
          DateTime.parse('2026-03-13T11:00:00.000Z'),
        );
        expect(summary.isAwaitingProviderAction, isTrue);
      },
    );

    test(
      'completeReservationViaQr sends the signed payload to backend',
      () async {
        Object? capturedBody;

        final repository = BackendReservationsRepository(
          apiClient: _FakeReservationsApiClient(
            onPost: ({required path, data, queryParameters}) {
              capturedBody = data;
              return <String, dynamic>{};
            },
          ),
          discoveryRepository: MockDiscoveryRepository(),
          readSession: _buildProviderSession,
        );

        await repository.completeReservationViaQr(
          'res_qr',
          payload: 'signed-qr-payload',
        );

        expect(capturedBody, {
          'payload': 'signed-qr-payload',
          'signedPayload': 'signed-qr-payload',
          'qrPayload': 'signed-qr-payload',
        });
      },
    );
  });
}

UserSession _buildProviderSession() {
  return UserSession(
    user: const SessionUser(
      id: 'uso_remote',
      fullName: 'Rauf Mammadov',
      email: 'rauf@reziphay.com',
      phoneNumber: '+994500000333',
      roles: [AppRole.provider],
      status: UserStatus.active,
    ),
    activeRole: AppRole.provider,
    tokens: AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresAt: DateTime(2099),
    ),
  );
}

class _FakeReservationsApiClient extends ApiClient {
  _FakeReservationsApiClient({this.onGet, this.onPost}) : super(Dio());

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
