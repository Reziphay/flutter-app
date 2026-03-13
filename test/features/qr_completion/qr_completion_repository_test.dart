import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/qr_completion/data/qr_completion_repository.dart';
import 'package:reziphay_mobile/features/qr_completion/models/qr_completion_models.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';

void main() {
  group('MockQrCompletionRepository', () {
    late MockReservationsRepository reservationsRepository;
    late MockQrCompletionRepository qrRepository;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 3, 13, 10);
      reservationsRepository = MockReservationsRepository(
        discoveryRepository: MockDiscoveryRepository(),
      );
      qrRepository = MockQrCompletionRepository(
        reservationsRepository: reservationsRepository,
        random: Random(1),
        now: () => now,
      );
    });

    test('successful scan completes a confirmed reservation via QR', () async {
      final reservationId = await reservationsRepository.createReservation(
        serviceId: 'classic-haircut',
        scheduledAt: now.add(const Duration(days: 1)),
        note: '',
        customerId: 'current-user',
        customerName: 'Test Customer',
      );
      await reservationsRepository.acceptProviderReservation(reservationId);

      final summary =
          (await reservationsRepository.getCustomerReservationDetail(
            reservationId,
            'current-user',
          )).summary;
      final session = await qrRepository.refreshProviderQr(
        providerId: summary.providerId,
        providerName: summary.providerName,
      );

      final result = await qrRepository.submitScannedPayload(
        reservation: summary,
        payload: session.payload,
      );
      final detail = await reservationsRepository.getCustomerReservationDetail(
        reservationId,
        'current-user',
      );

      expect(result.status, QrCompletionStatus.success);
      expect(detail.summary.effectiveStatus, ReservationStatus.completed);
      expect(detail.completionMethod, CompletionMethod.qr);
    });

    test('scan rejects QR payloads from a different provider', () async {
      final reservationId = await reservationsRepository.createReservation(
        serviceId: 'dental-consultation',
        scheduledAt: now.add(const Duration(days: 2)),
        note: '',
        customerId: 'current-user',
        customerName: 'Test Customer',
      );
      await reservationsRepository.acceptProviderReservation(reservationId);

      final summary =
          (await reservationsRepository.getCustomerReservationDetail(
            reservationId,
            'current-user',
          )).summary;
      final session = await qrRepository.refreshProviderQr(
        providerId: 'rauf-mammadov',
        providerName: 'Rauf Mammadov',
      );

      final result = await qrRepository.submitScannedPayload(
        reservation: summary,
        payload: session.payload,
      );

      expect(result.status, QrCompletionStatus.wrongProvider);
    });

    test('expired QR sessions are rejected', () async {
      final reservationId = await reservationsRepository.createReservation(
        serviceId: 'classic-haircut',
        scheduledAt: now.add(const Duration(days: 1)),
        note: '',
        customerId: 'current-user',
        customerName: 'Test Customer',
      );
      await reservationsRepository.acceptProviderReservation(reservationId);

      final summary =
          (await reservationsRepository.getCustomerReservationDetail(
            reservationId,
            'current-user',
          )).summary;
      final session = await qrRepository.refreshProviderQr(
        providerId: summary.providerId,
        providerName: summary.providerName,
      );
      now = now.add(const Duration(minutes: 3));

      final result = await qrRepository.submitScannedPayload(
        reservation: summary,
        payload: session.payload,
      );

      expect(result.status, QrCompletionStatus.expired);
    });
  });
}
