import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';

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
  });
}
