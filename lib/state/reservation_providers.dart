// reservation_providers.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reservation.dart';
import '../services/reservation_service.dart';
import 'app_state.dart';

// ── My Reservations (refreshable notifier) ─────────────────────────────────

class MyReservationsNotifier extends AsyncNotifier<List<ReservationItem>> {
  @override
  Future<List<ReservationItem>> build() async {
    // Re-build whenever the authenticated user changes (login / logout).
    // This prevents stale error state being shown after re-authentication.
    final authStatus = ref.watch(
      appStateProvider.select((s) => s.authStatus),
    );
    if (authStatus != AuthStatus.authenticated) return [];
    return ReservationService.instance.fetchMyReservations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ReservationService.instance.fetchMyReservations(),
    );
  }
}

final myReservationsProvider =
    AsyncNotifierProvider<MyReservationsNotifier, List<ReservationItem>>(
  MyReservationsNotifier.new,
);

// ── Reservation Detail ──────────────────────────────────────────────────────

final reservationDetailProvider =
    FutureProvider.family<ReservationItem, String>((ref, id) {
  return ReservationService.instance.fetchReservationDetail(id);
});

// ── Active reservation for a specific service (UCR button state) ────────────

/// Returns the most recent ACTIVE reservation for [serviceId], or null if none.
/// Active = PENDING | CONFIRMED | CHANGE_REQUESTED_BY_CUSTOMER | CHANGE_REQUESTED_BY_OWNER
final serviceActiveReservationProvider =
    Provider.family<ReservationItem?, String>((ref, serviceId) {
  final reservations =
      ref.watch(myReservationsProvider).valueOrNull ?? [];
  return reservations
      .where((r) => r.service.id == serviceId && r.status.isActive)
      .lastOrNull;
});
