import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/qr_completion/models/qr_completion_models.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';

abstract class QrCompletionRepository {
  Future<ProviderQrSession> getProviderQr({
    required String providerId,
    required String providerName,
  });

  Future<ProviderQrSession> refreshProviderQr({
    required String providerId,
    required String providerName,
  });

  Future<QrCompletionResult> submitScannedPayload({
    required ReservationSummary reservation,
    required String payload,
  });
}

final qrCompletionRepositoryProvider = Provider<QrCompletionRepository>(
  (ref) => MockQrCompletionRepository(
    reservationsRepository: ref.watch(reservationsRepositoryProvider),
  ),
);

final providerQrSessionProvider = FutureProvider.autoDispose
    .family<ProviderQrSession, String>((ref, providerId) async {
      final provider = await ref.watch(
        providerDetailProvider(providerId).future,
      );
      return ref
          .watch(qrCompletionRepositoryProvider)
          .getProviderQr(
            providerId: providerId,
            providerName: provider.summary.name,
          );
    });

class MockQrCompletionRepository implements QrCompletionRepository {
  MockQrCompletionRepository({
    required ReservationsRepository reservationsRepository,
    Random? random,
    DateTime Function()? now,
    Duration sessionLifetime = const Duration(minutes: 2),
  }) : _reservationsRepository = reservationsRepository,
       _random = random ?? Random(),
       _now = now ?? DateTime.now,
       _sessionLifetime = sessionLifetime;

  final ReservationsRepository _reservationsRepository;
  final Random _random;
  final DateTime Function() _now;
  final Duration _sessionLifetime;
  final Map<String, ProviderQrSession> _sessionsByProviderId = {};

  @override
  Future<ProviderQrSession> getProviderQr({
    required String providerId,
    required String providerName,
  }) async {
    await _delay();
    final session = _sessionsByProviderId[providerId];
    if (session != null && _now().isBefore(session.expiresAt)) {
      return session;
    }
    return _createSession(providerId: providerId, providerName: providerName);
  }

  @override
  Future<ProviderQrSession> refreshProviderQr({
    required String providerId,
    required String providerName,
  }) async {
    await _delay();
    return _createSession(providerId: providerId, providerName: providerName);
  }

  @override
  Future<QrCompletionResult> submitScannedPayload({
    required ReservationSummary reservation,
    required String payload,
  }) async {
    await _delay();

    ProviderQrSession? session;
    for (final candidate in _sessionsByProviderId.values) {
      if (candidate.payload == payload) {
        session = candidate;
        break;
      }
    }

    if (session == null) {
      return const QrCompletionResult(
        status: QrCompletionStatus.invalid,
        reservationId: '',
        providerId: '',
        providerName: '',
      );
    }

    if (!_now().isBefore(session.expiresAt)) {
      return QrCompletionResult(
        status: QrCompletionStatus.expired,
        reservationId: reservation.id,
        providerId: session.providerId,
        providerName: session.providerName,
      );
    }

    if (session.providerId != reservation.providerId) {
      return QrCompletionResult(
        status: QrCompletionStatus.wrongProvider,
        reservationId: reservation.id,
        providerId: session.providerId,
        providerName: session.providerName,
      );
    }

    if (reservation.effectiveStatus == ReservationStatus.completed) {
      return QrCompletionResult(
        status: QrCompletionStatus.alreadyCompleted,
        reservationId: reservation.id,
        providerId: session.providerId,
        providerName: session.providerName,
      );
    }

    if (reservation.effectiveStatus != ReservationStatus.confirmed) {
      return QrCompletionResult(
        status: QrCompletionStatus.manualFallback,
        reservationId: reservation.id,
        providerId: session.providerId,
        providerName: session.providerName,
      );
    }

    await _reservationsRepository.completeReservationViaQr(reservation.id);

    return QrCompletionResult(
      status: QrCompletionStatus.success,
      reservationId: reservation.id,
      providerId: session.providerId,
      providerName: session.providerName,
    );
  }

  ProviderQrSession _createSession({
    required String providerId,
    required String providerName,
  }) {
    final now = _now();
    final session = ProviderQrSession(
      providerId: providerId,
      providerName: providerName,
      payload:
          'rzp:$providerId:${now.microsecondsSinceEpoch}:${_random.nextInt(9999999)}',
      generatedAt: now,
      expiresAt: now.add(_sessionLifetime),
    );
    _sessionsByProviderId[providerId] = session;
    return session;
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 140));
}
