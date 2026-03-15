// reservation_service.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../models/reservation.dart';

class ReservationService {
  ReservationService._();
  static final ReservationService instance = ReservationService._();

  final _client = ApiClient.instance;

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<ReservationItem> createReservation(CreateReservationDto dto) =>
      _client.post(
        Endpoints.reservations,
        data: dto.toJson(),
        fromJson: (json) => ReservationItem.fromJson(json),
      );

  // ── List my reservations ───────────────────────────────────────────────────

  Future<List<ReservationItem>> fetchMyReservations({
    ReservationStatus? status,
  }) async {
    final Map<String, dynamic> params = {};
    if (status != null) params['status'] = status.name.toUpperCase();

    return _client.get(
      Endpoints.myReservations,
      queryParameters: params.isEmpty ? null : params,
      fromJson: (json) {
        final items = json['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => ReservationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ── Detail ─────────────────────────────────────────────────────────────────

  Future<ReservationItem> fetchReservationDetail(String id) =>
      _client.get(
        Endpoints.reservationById(id),
        fromJson: (json) => ReservationItem.fromJson(json),
      );

  // ── Cancel (UCR) ──────────────────────────────────────────────────────────

  Future<ReservationItem> cancelReservation(String id, String reason) =>
      _client.post(
        Endpoints.cancelReservation(id),
        data: {'reason': reason},
        fromJson: (json) => ReservationItem.fromJson(json),
      );

  // ── USO — Incoming reservations ────────────────────────────────────────

  Future<List<ReservationItem>> fetchIncomingReservations({
    ReservationStatus? status,
  }) async {
    final Map<String, dynamic> params = {};
    if (status != null) params['status'] = status.name.toUpperCase();

    return _client.get(
      Endpoints.incomingReservations,
      queryParameters: params.isEmpty ? null : params,
      fromJson: (json) {
        final items = json['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => ReservationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<Map<String, int>> fetchIncomingStats() =>
      _client.get(
        Endpoints.incomingReservationStats,
        fromJson: (json) => Map<String, int>.from(
          (json).map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ),
        ),
      );

  // ── USO — Accept / Reject / Complete ───────────────────────────────────

  Future<ReservationItem> acceptReservation(String id) =>
      _client.post(
        Endpoints.acceptReservation(id),
        fromJson: (json) => ReservationItem.fromJson(json),
      );

  Future<ReservationItem> rejectReservation(String id, String reason) =>
      _client.post(
        Endpoints.rejectReservation(id),
        data: {'reason': reason},
        fromJson: (json) => ReservationItem.fromJson(json),
      );

  Future<ReservationItem> cancelByOwner(String id, String reason) =>
      _client.post(
        Endpoints.cancelByOwner(id),
        data: {'reason': reason},
        fromJson: (json) => ReservationItem.fromJson(json),
      );

  Future<ReservationItem> completeManually(String id) =>
      _client.post(
        Endpoints.completeManually(id),
        fromJson: (json) => ReservationItem.fromJson(json),
      );
}
