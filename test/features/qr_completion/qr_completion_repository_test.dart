import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/qr_completion/data/qr_completion_repository.dart';
import 'package:reziphay_mobile/features/qr_completion/models/qr_completion_models.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import '../../helpers/mock_discovery_repository.dart';
import '../../helpers/mock_qr_completion_repository.dart';
import '../../helpers/mock_reservations_repository.dart';

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

  group('BackendQrCompletionRepository', () {
    test(
      'submitScannedPayload forwards the signed payload to reservations backend',
      () async {
        final reservationsRepository = _FakeReservationsRepository();
        final repository = BackendQrCompletionRepository(
          apiClient: _FakeQrApiClient(),
          reservationsRepository: reservationsRepository,
          readSession: () => null,
        );
        final reservation = _buildReservationSummary();

        final result = await repository.submitScannedPayload(
          reservation: reservation,
          payload: 'signed-backend-payload',
        );

        expect(result.status, QrCompletionStatus.success);
        expect(
          reservationsRepository.completedViaQrReservationId,
          reservation.id,
        );
        expect(
          reservationsRepository.completedViaQrPayload,
          'signed-backend-payload',
        );
      },
    );

    test('submitScannedPayload maps backend QR expiration errors', () async {
      final reservationsRepository = _FakeReservationsRepository(
        completeViaQrError: const AppException(
          'QR session expired.',
          type: AppExceptionType.conflict,
          code: 'QR_EXPIRED',
          statusCode: 409,
        ),
      );
      final repository = BackendQrCompletionRepository(
        apiClient: _FakeQrApiClient(),
        reservationsRepository: reservationsRepository,
        readSession: () => null,
      );

      final result = await repository.submitScannedPayload(
        reservation: _buildReservationSummary(),
        payload: 'expired-payload',
      );

      expect(result.status, QrCompletionStatus.expired);
    });

    test(
      'getProviderQr loads and parses the backend provider QR session',
      () async {
        final repository = BackendQrCompletionRepository(
          apiClient: _FakeQrApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/reservations/provider-qr') {
                throw const AppException(
                  'Not found',
                  type: AppExceptionType.unknown,
                  statusCode: 404,
                );
              }
              if (path == '/qr/provider-session') {
                return {
                  'session': {
                    'provider': {
                      'id': 'uso_remote',
                      'fullName': 'Rauf Mammadov',
                    },
                    'signedPayload': 'signed-provider-payload',
                    'generatedAt': '2026-03-13T10:00:00.000Z',
                    'expiresAt': '2026-03-13T10:02:00.000Z',
                  },
                };
              }
              throw StateError('Unexpected GET path $path');
            },
          ),
          reservationsRepository: _FakeReservationsRepository(),
          readSession: () => null,
        );

        final session = await repository.getProviderQr(
          providerId: 'uso_remote',
          providerName: 'Rauf Mammadov',
        );

        expect(session.providerId, 'uso_remote');
        expect(session.providerName, 'Rauf Mammadov');
        expect(session.payload, 'signed-provider-payload');
        expect(session.expiresAt, DateTime.parse('2026-03-13T10:02:00.000Z'));
      },
    );
  });
}

ReservationSummary _buildReservationSummary() {
  return ReservationSummary(
    id: 'res_qr',
    serviceId: 'classic-haircut',
    serviceName: 'Classic haircut',
    providerId: 'rauf-mammadov',
    providerName: 'Rauf Mammadov',
    customerName: 'Test Customer',
    addressLine: '14 Fountain Sq',
    scheduledAt: DateTime(2026, 3, 14, 15),
    createdAt: DateTime(2026, 3, 13, 10),
    status: ReservationStatus.confirmed,
    approvalMode: ApprovalMode.manual,
    priceLabel: '28 AZN',
  );
}

class _FakeQrApiClient extends ApiClient {
  _FakeQrApiClient({this.onGet}) : super(Dio());

  final dynamic Function({
    required String path,
    Map<String, dynamic>? queryParameters,
  })?
  onGet;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    final response =
        onGet?.call(path: path, queryParameters: queryParameters) ??
        <String, dynamic>{};
    return mapper(response);
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
    return mapper(<String, dynamic>{});
  }
}

class _FakeReservationsRepository implements ReservationsRepository {
  _FakeReservationsRepository({this.completeViaQrError});

  final AppException? completeViaQrError;
  String? completedViaQrReservationId;
  String? completedViaQrPayload;

  @override
  Future<void> completeReservationViaQr(
    String reservationId, {
    String? payload,
  }) async {
    if (completeViaQrError != null) {
      throw completeViaQrError!;
    }

    completedViaQrReservationId = reservationId;
    completedViaQrPayload = payload;
  }

  @override
  Future<void> acceptCustomerChange(String reservationId) => _unsupported();

  @override
  Future<void> acceptProviderReservation(String reservationId) =>
      _unsupported();

  @override
  Future<void> cancelCustomerReservation({
    required String reservationId,
    required String reason,
  }) => _unsupported();

  @override
  Future<void> cancelProviderReservation({
    required String reservationId,
    required String reason,
  }) => _unsupported();

  @override
  Future<void> completeProviderReservation(String reservationId) =>
      _unsupported();

  @override
  Future<String> createReservation({
    required String serviceId,
    required DateTime scheduledAt,
    required String note,
    required String customerId,
    required String customerName,
  }) => _unsupported();

  @override
  Future<void> declineCustomerChange({
    required String reservationId,
    required String reason,
  }) => _unsupported();

  @override
  Future<CustomerPenaltySummary> getCustomerPenaltySummary(String customerId) =>
      _unsupported();

  @override
  Future<ReservationDetail> getCustomerReservationDetail(
    String reservationId,
    String customerId,
  ) => _unsupported();

  @override
  Future<List<ReservationSummary>> getCustomerReservations(String customerId) =>
      _unsupported();

  @override
  Future<ProviderDashboardData> getProviderDashboard(String providerId) =>
      _unsupported();

  @override
  Future<ReservationDetail> getProviderReservationDetail(
    String reservationId,
    String providerId,
  ) => _unsupported();

  @override
  Future<List<ReservationSummary>> getProviderReservations(String providerId) =>
      _unsupported();

  @override
  Future<void> rejectProviderReservation({
    required String reservationId,
    required String reason,
  }) => _unsupported();

  @override
  Future<void> requestCustomerChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) => _unsupported();

  @override
  Future<void> requestProviderChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) => _unsupported();

  @override
  Future<void> submitNoShowObjection({
    required String reservationId,
    required String customerId,
    required NoShowObjectionReason reason,
    required String details,
  }) => _unsupported();

  Future<T> _unsupported<T>() {
    throw UnimplementedError();
  }
}
