import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

abstract class ReservationsRepository {
  Future<String> createReservation({
    required String serviceId,
    required DateTime scheduledAt,
    required String note,
    required String customerId,
    required String customerName,
  });

  Future<List<ReservationSummary>> getCustomerReservations(String customerId);

  Future<ReservationDetail> getCustomerReservationDetail(
    String reservationId,
    String customerId,
  );

  Future<List<ReservationSummary>> getProviderReservations(String providerId);

  Future<ReservationDetail> getProviderReservationDetail(
    String reservationId,
    String providerId,
  );

  Future<CustomerPenaltySummary> getCustomerPenaltySummary(String customerId);

  Future<ProviderDashboardData> getProviderDashboard(String providerId);

  Future<void> cancelCustomerReservation({
    required String reservationId,
    required String reason,
  });

  Future<void> requestCustomerChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  });

  Future<void> acceptCustomerChange(String reservationId);

  Future<void> acceptProviderReservation(String reservationId);

  Future<void> rejectProviderReservation({
    required String reservationId,
    required String reason,
  });

  Future<void> cancelProviderReservation({
    required String reservationId,
    required String reason,
  });

  Future<void> requestProviderChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  });

  Future<void> declineCustomerChange({
    required String reservationId,
    required String reason,
  });

  Future<void> submitNoShowObjection({
    required String reservationId,
    required String customerId,
    required NoShowObjectionReason reason,
    required String details,
  });

  Future<void> completeReservationViaQr(
    String reservationId, {
    String? payload,
  });

  Future<void> completeProviderReservation(String reservationId);
}

final activeProviderContextProvider = Provider<String>((ref) {
  final session = ref.watch(sessionControllerProvider).session;
  return session?.user.id ?? '';
});

final activeCustomerContextProvider = Provider<String>((ref) {
  final session = ref.watch(sessionControllerProvider).session;
  return session?.user.id ?? '';
});

final reservationsRepositoryProvider = Provider<ReservationsRepository>(
  (ref) => BackendReservationsRepository(
    apiClient: ref.watch(apiClientProvider),
    discoveryRepository: ref.watch(discoveryRepositoryProvider),
    readSession: () => ref.read(sessionControllerProvider).session,
  ),
);

final customerReservationsProvider =
    FutureProvider.autoDispose<List<ReservationSummary>>(
      (ref) => ref
          .watch(reservationsRepositoryProvider)
          .getCustomerReservations(ref.watch(activeCustomerContextProvider)),
    );

final customerReservationDetailProvider = FutureProvider.autoDispose
    .family<ReservationDetail, String>(
      (ref, reservationId) => ref
          .watch(reservationsRepositoryProvider)
          .getCustomerReservationDetail(
            reservationId,
            ref.watch(activeCustomerContextProvider),
          ),
    );

final customerPenaltySummaryProvider =
    FutureProvider.autoDispose<CustomerPenaltySummary>(
      (ref) => ref
          .watch(reservationsRepositoryProvider)
          .getCustomerPenaltySummary(ref.watch(activeCustomerContextProvider)),
    );

final providerReservationsProvider =
    FutureProvider.autoDispose<List<ReservationSummary>>(
      (ref) => ref
          .watch(reservationsRepositoryProvider)
          .getProviderReservations(ref.watch(activeProviderContextProvider)),
    );

final providerReservationDetailProvider = FutureProvider.autoDispose
    .family<ReservationDetail, String>(
      (ref, reservationId) => ref
          .watch(reservationsRepositoryProvider)
          .getProviderReservationDetail(
            reservationId,
            ref.watch(activeProviderContextProvider),
          ),
    );

final providerDashboardProvider =
    FutureProvider.autoDispose<ProviderDashboardData>(
      (ref) => ref
          .watch(reservationsRepositoryProvider)
          .getProviderDashboard(ref.watch(activeProviderContextProvider)),
    );

final reservationsActionsProvider = Provider<ReservationsActions>(
  (ref) => ReservationsActions(ref),
);

class ReservationsActions {
  ReservationsActions(this.ref);

  final Ref ref;

  Future<String> createReservation({
    required String serviceId,
    required DateTime scheduledAt,
    required String note,
  }) async {
    final session = ref.read(sessionControllerProvider).session;
    final reservationId = await ref
        .read(reservationsRepositoryProvider)
        .createReservation(
          serviceId: serviceId,
          scheduledAt: scheduledAt,
          note: note,
          customerId: ref.read(activeCustomerContextProvider),
          customerName: session?.user.fullName ?? 'Reziphay User',
        );
    _invalidate(reservationId);
    return reservationId;
  }

  Future<void> cancelCustomerReservation({
    required String reservationId,
    required String reason,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .cancelCustomerReservation(
          reservationId: reservationId,
          reason: reason,
        );
    _invalidate(reservationId);
  }

  Future<void> requestCustomerChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .requestCustomerChange(
          reservationId: reservationId,
          proposedTime: proposedTime,
          reason: reason,
        );
    _invalidate(reservationId);
  }

  Future<void> acceptCustomerChange(String reservationId) async {
    await ref
        .read(reservationsRepositoryProvider)
        .acceptCustomerChange(reservationId);
    _invalidate(reservationId);
  }

  Future<void> acceptProviderReservation(String reservationId) async {
    await ref
        .read(reservationsRepositoryProvider)
        .acceptProviderReservation(reservationId);
    _invalidate(reservationId);
  }

  Future<void> rejectProviderReservation({
    required String reservationId,
    required String reason,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .rejectProviderReservation(
          reservationId: reservationId,
          reason: reason,
        );
    _invalidate(reservationId);
  }

  Future<void> cancelProviderReservation({
    required String reservationId,
    required String reason,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .cancelProviderReservation(
          reservationId: reservationId,
          reason: reason,
        );
    _invalidate(reservationId);
  }

  Future<void> requestProviderChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .requestProviderChange(
          reservationId: reservationId,
          proposedTime: proposedTime,
          reason: reason,
        );
    _invalidate(reservationId);
  }

  Future<void> declineCustomerChange({
    required String reservationId,
    required String reason,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .declineCustomerChange(reservationId: reservationId, reason: reason);
    _invalidate(reservationId);
  }

  Future<void> submitNoShowObjection({
    required String reservationId,
    required NoShowObjectionReason reason,
    required String details,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .submitNoShowObjection(
          reservationId: reservationId,
          customerId: ref.read(activeCustomerContextProvider),
          reason: reason,
          details: details,
        );
    _invalidate(reservationId);
  }

  Future<void> completeProviderReservation(String reservationId) async {
    await ref
        .read(reservationsRepositoryProvider)
        .completeProviderReservation(reservationId);
    _invalidate(reservationId);
  }

  Future<void> completeReservationViaQr(
    String reservationId, {
    String? payload,
  }) async {
    await ref
        .read(reservationsRepositoryProvider)
        .completeReservationViaQr(reservationId, payload: payload);
    _invalidate(reservationId);
  }

  void _invalidate(String reservationId) {
    ref.invalidate(customerReservationsProvider);
    ref.invalidate(customerPenaltySummaryProvider);
    ref.invalidate(providerReservationsProvider);
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(customerReservationDetailProvider(reservationId));
    ref.invalidate(providerReservationDetailProvider(reservationId));
  }
}

class BackendReservationsRepository implements ReservationsRepository {
  BackendReservationsRepository({
    required ApiClient apiClient,
    required DiscoveryRepository discoveryRepository,
    required UserSession? Function() readSession,
  }) : _apiClient = apiClient,
       _discoveryRepository = discoveryRepository,
       _readSession = readSession;

  final ApiClient _apiClient;
  final DiscoveryRepository _discoveryRepository;
  final UserSession? Function() _readSession;

  @override
  Future<String> createReservation({
    required String serviceId,
    required DateTime scheduledAt,
    required String note,
    required String customerId,
    required String customerName,
  }) async {
    final payload = await _apiClient.post<dynamic>(
      '/reservations',
      data: {
        'serviceId': serviceId,
        'requestedStartAt': scheduledAt.toIso8601String(),
        'scheduledAt': scheduledAt.toIso8601String(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
      mapper: (data) => data,
    );

    final entity = _extractEntity(payload, ['reservation', 'item']);
    final id = _readString(entity, ['id']);
    if (id == null || id.isEmpty) {
      throw const AppException(
        'The reservation was created, but the server response was incomplete.',
        type: AppExceptionType.server,
      );
    }

    return id;
  }

  @override
  Future<List<ReservationSummary>> getCustomerReservations(
    String customerId,
  ) async {
    final payload = await _apiClient.get<dynamic>(
      '/reservations/my',
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'reservations']);
    return items
        .map(
          (item) => _parseReservationSummary(
            item,
            latestPendingChange: _extractLatestPendingChange(item),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<ReservationDetail> getCustomerReservationDetail(
    String reservationId,
    String customerId,
  ) async {
    return (await _fetchReservationSnapshot(reservationId)).detail;
  }

  @override
  Future<List<ReservationSummary>> getProviderReservations(
    String providerId,
  ) async {
    final payload = await _apiClient.get<dynamic>(
      '/reservations/incoming',
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'reservations']);
    return items
        .map(
          (item) => _parseReservationSummary(
            item,
            latestPendingChange: _extractLatestPendingChange(item),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<ReservationDetail> getProviderReservationDetail(
    String reservationId,
    String providerId,
  ) async {
    return (await _fetchReservationSnapshot(reservationId)).detail;
  }

  @override
  Future<CustomerPenaltySummary> getCustomerPenaltySummary(
    String customerId,
  ) async {
    final payload = await _apiClient.get<dynamic>(
      '/penalties/me',
      mapper: (data) => data,
    );
    final entity = payload is Map ? asJsonMap(payload) : <String, dynamic>{};
    final penaltyItems = _extractItems(entity, ['items', 'penalties']);
    final activePoints =
        _readInt(entity, [
          'activePenaltyPoints',
          'activePoints',
          'summary.activePoints',
        ]) ??
        penaltyItems
            .where(
              (item) =>
                  _readBool(item, ['isActive', 'active']) ??
                  _readString(item, ['status'])?.toUpperCase() == 'ACTIVE',
            )
            .length;
    final objectionsUnderReview =
        _readInt(entity, [
          'objectionsUnderReview',
          'summary.objectionsUnderReview',
        ]) ??
        penaltyItems
            .where(
              (item) =>
                  _readString(item, ['objection.status'])?.toUpperCase() ==
                  'UNDER_REVIEW',
            )
            .length;

    return CustomerPenaltySummary(
      activePenaltyPoints: activePoints,
      noShowCount:
          _readInt(entity, ['noShowCount', 'summary.noShowCount']) ??
          penaltyItems.length,
      objectionsUnderReview: objectionsUnderReview,
      latestPenaltyAt: _readDateTime(entity, [
        'latestPenaltyAt',
        'summary.latestPenaltyAt',
      ]),
    );
  }

  @override
  Future<ProviderDashboardData> getProviderDashboard(String providerId) async {
    final reservations = await getProviderReservations(providerId);
    final pendingRequests =
        reservations
            .where((reservation) => reservation.isAwaitingProviderAction)
            .toList(growable: false)
          ..sort((left, right) {
            final leftRemaining =
                left.pendingTimeRemaining?.inSeconds ?? 1 << 30;
            final rightRemaining =
                right.pendingTimeRemaining?.inSeconds ?? 1 << 30;
            return leftRemaining.compareTo(rightRemaining);
          });
    final todayReservations =
        reservations
            .where((reservation) => reservation.isActiveToday)
            .toList(growable: false)
          ..sort(
            (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
          );

    var serviceCount = 0;
    var brandCount = 0;
    final session = _readSession();
    final userId = session?.user.id;
    if (userId != null && userId.isNotEmpty) {
      try {
        final providerDetail = await _discoveryRepository.getProviderDetail(
          userId,
        );
        serviceCount = providerDetail.services.length;
        brandCount = providerDetail.associatedBrands.length;
      } catch (_) {
        serviceCount = 0;
        brandCount = 0;
      }
    }

    return ProviderDashboardData(
      pendingRequests: pendingRequests,
      todayReservations: todayReservations,
      pendingCount: pendingRequests.length,
      confirmedTodayCount: todayReservations
          .where(
            (reservation) =>
                reservation.effectiveStatus == ReservationStatus.confirmed,
          )
          .length,
      serviceCount: serviceCount,
      brandCount: brandCount,
    );
  }

  @override
  Future<void> cancelCustomerReservation({
    required String reservationId,
    required String reason,
  }) {
    return _apiClient.post<void>(
      '/reservations/$reservationId/cancel-by-customer',
      data: {'reason': reason.trim()},
      mapper: (_) {},
    );
  }

  @override
  Future<void> requestCustomerChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) {
    return _submitChangeRequest(
      reservationId: reservationId,
      proposedTime: proposedTime,
      reason: reason,
    );
  }

  @override
  Future<void> acceptCustomerChange(String reservationId) async {
    final snapshot = await _fetchReservationSnapshot(reservationId);
    final changeRequestId = snapshot.pendingChangeRequestId;
    if (changeRequestId == null ||
        snapshot.pendingChangeRequestedBy != ReservationActor.provider) {
      throw const AppException(
        'There is no provider-proposed change waiting for the customer.',
        type: AppExceptionType.conflict,
      );
    }

    await _apiClient.post<void>(
      '/reservations/change-requests/$changeRequestId/accept',
      mapper: (_) {},
    );
  }

  @override
  Future<void> acceptProviderReservation(String reservationId) async {
    final snapshot = await _fetchReservationSnapshot(reservationId);
    final changeRequestId = snapshot.pendingChangeRequestId;
    if (changeRequestId != null &&
        snapshot.pendingChangeRequestedBy == ReservationActor.customer) {
      await _apiClient.post<void>(
        '/reservations/change-requests/$changeRequestId/accept',
        mapper: (_) {},
      );
      return;
    }

    await _apiClient.post<void>(
      '/reservations/$reservationId/accept',
      mapper: (_) {},
    );
  }

  @override
  Future<void> rejectProviderReservation({
    required String reservationId,
    required String reason,
  }) async {
    final snapshot = await _fetchReservationSnapshot(reservationId);
    final changeRequestId = snapshot.pendingChangeRequestId;
    if (changeRequestId != null &&
        snapshot.pendingChangeRequestedBy == ReservationActor.customer) {
      await _apiClient.post<void>(
        '/reservations/change-requests/$changeRequestId/reject',
        data: {'reason': reason.trim()},
        mapper: (_) {},
      );
      return;
    }

    await _apiClient.post<void>(
      '/reservations/$reservationId/reject',
      data: {'reason': reason.trim()},
      mapper: (_) {},
    );
  }

  @override
  Future<void> cancelProviderReservation({
    required String reservationId,
    required String reason,
  }) {
    return _apiClient.post<void>(
      '/reservations/$reservationId/cancel-by-owner',
      data: {'reason': reason.trim()},
      mapper: (_) {},
    );
  }

  @override
  Future<void> requestProviderChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) {
    return _submitChangeRequest(
      reservationId: reservationId,
      proposedTime: proposedTime,
      reason: reason,
    );
  }

  @override
  Future<void> declineCustomerChange({
    required String reservationId,
    required String reason,
  }) async {
    final snapshot = await _fetchReservationSnapshot(reservationId);
    final changeRequestId = snapshot.pendingChangeRequestId;
    if (changeRequestId == null ||
        snapshot.pendingChangeRequestedBy != ReservationActor.customer) {
      throw const AppException(
        'There is no customer-proposed change waiting for the provider.',
        type: AppExceptionType.conflict,
      );
    }

    await _apiClient.post<void>(
      '/reservations/change-requests/$changeRequestId/reject',
      data: {'reason': reason.trim()},
      mapper: (_) {},
    );
  }

  @override
  Future<void> submitNoShowObjection({
    required String reservationId,
    required String customerId,
    required NoShowObjectionReason reason,
    required String details,
  }) {
    return _apiClient.post<void>(
      '/reservations/$reservationId/objections',
      data: {
        'reason': _backendObjectionReason(reason),
        'details': details.trim(),
      },
      mapper: (_) {},
    );
  }

  @override
  Future<void> completeReservationViaQr(
    String reservationId, {
    String? payload,
  }) async {
    final signedPayload = payload?.trim() ?? '';
    if (signedPayload.isEmpty) {
      throw const AppException(
        'A signed QR payload is required for backend verification.',
        type: AppExceptionType.validation,
      );
    }

    await _apiClient.post<void>(
      '/reservations/$reservationId/complete-by-qr',
      data: {
        'payload': signedPayload,
        'signedPayload': signedPayload,
        'qrPayload': signedPayload,
      },
      mapper: (_) {},
    );
  }

  @override
  Future<void> completeProviderReservation(String reservationId) {
    return _apiClient.post<void>(
      '/reservations/$reservationId/complete-manually',
      mapper: (_) {},
    );
  }

  Future<void> _submitChangeRequest({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) {
    return _apiClient.post<void>(
      '/reservations/$reservationId/change-requests',
      data: {
        'proposedStartAt': proposedTime.toIso8601String(),
        'proposedTime': proposedTime.toIso8601String(),
        'reason': reason.trim(),
      },
      mapper: (_) {},
    );
  }

  Future<_BackendReservationSnapshot> _fetchReservationSnapshot(
    String reservationId,
  ) async {
    final payload = await _apiClient.get<dynamic>(
      '/reservations/$reservationId',
      mapper: (data) => data,
    );
    final entity = _extractEntity(payload, ['reservation', 'item']);
    return _parseReservationDetail(entity);
  }

  _BackendReservationSnapshot _parseReservationDetail(JsonMap item) {
    final latestPendingChange = _extractLatestPendingChange(item);
    final allChanges = _parseChangeHistory(item);
    final summary = _parseReservationSummary(
      item,
      latestPendingChange: latestPendingChange,
    );
    final timeline = _parseTimeline(item, summary);
    final cancellationReason =
        _readString(item, ['cancellationReason', 'cancelReason']) ??
        _historyReasonForStatus(
          _readList(item, ['statusHistory', 'timeline']),
          'CANCELLED',
        );
    final rejectionReason =
        _readString(item, ['rejectionReason', 'rejectReason']) ??
        _historyReasonForStatus(
          _readList(item, ['statusHistory', 'timeline']),
          'REJECTED',
        );
    final noShowReason =
        _readString(item, ['noShowReason']) ??
        _historyReasonForStatus(
          _readList(item, ['statusHistory', 'timeline']),
          'NO_SHOW',
        );

    return _BackendReservationSnapshot(
      detail: ReservationDetail(
        summary: summary,
        timeline: timeline,
        changeHistory: allChanges,
        cancellationReason: cancellationReason,
        rejectionReason: rejectionReason,
        noShowReason: noShowReason,
        noShowObjection: _parseNoShowObjection(item),
        completionMethod: CompletionMethodX.parse(
          _readString(item, [
            'completion.method',
            'completionMethod',
            'completedBy',
          ]),
        ),
      ),
      pendingChangeRequestId: latestPendingChange?.id,
      pendingChangeRequestedBy: latestPendingChange?.requestedBy,
    );
  }

  ReservationSummary _parseReservationSummary(
    JsonMap item, {
    _BackendChangeRequest? latestPendingChange,
  }) {
    final service = _readMap(item, ['service']) ?? <String, dynamic>{};
    final brand = _readMap(service, ['brand']) ?? <String, dynamic>{};
    final provider =
        _readMap(service, ['owner', 'provider']) ?? <String, dynamic>{};
    final customer =
        _readMap(item, ['customer', 'customerUser']) ?? <String, dynamic>{};
    final scheduledAt =
        _readDateTime(item, ['requestedStartAt', 'scheduledAt', 'startsAt']) ??
        DateTime.now();
    final createdAt =
        _readDateTime(item, ['createdAt', 'requestedAt']) ?? DateTime.now();
    final baseStatus = ReservationStatusX.parse(_readString(item, ['status']));
    final status = latestPendingChange == null
        ? baseStatus
        : ReservationStatus.changeRequested;
    final serviceName =
        _readString(service, ['name', 'title']) ??
        _readString(item, ['serviceName']) ??
        'Service';
    final providerId =
        _readString(provider, ['id']) ??
        _readString(item, ['providerId']) ??
        '';
    final providerName =
        _readString(provider, ['fullName', 'name']) ??
        _readString(item, ['providerName']) ??
        'Provider';
    final customerName =
        _readString(customer, ['fullName', 'name']) ??
        _readString(item, ['customerName']) ??
        'Customer';
    final price = _readDouble(service, ['price', 'price.amount']);

    return ReservationSummary(
      id: _readString(item, ['id']) ?? '',
      serviceId:
          _readString(service, ['id']) ??
          _readString(item, ['serviceId']) ??
          '',
      serviceName: serviceName,
      providerId: providerId,
      providerName: providerName,
      customerName: customerName,
      addressLine:
          _readString(service, [
            'addressLine',
            'address.addressLine',
            'serviceAddress.addressLine',
          ]) ??
          _readString(item, ['addressLine']) ??
          'Address not specified',
      scheduledAt: scheduledAt,
      createdAt: createdAt,
      status: status,
      approvalMode: _parseApprovalMode(service, item),
      priceLabel: price == null
          ? 'Price on request'
          : '${price.toStringAsFixed(0)} AZN',
      latestChangeRequestedBy: latestPendingChange?.requestedBy,
      latestChangeProposedTime: latestPendingChange?.proposedTime,
      brandId: _readString(brand, ['id']) ?? _readString(item, ['brandId']),
      brandName:
          _readString(brand, ['name']) ?? _readString(item, ['brandName']),
      note: _readString(item, ['notes', 'note']),
      responseDeadline: _readDateTime(item, [
        'approvalExpiresAt',
        'responseDeadline',
        'approvalDeadline',
      ]),
    );
  }

  List<ReservationTimelineEvent> _parseTimeline(
    JsonMap item,
    ReservationSummary summary,
  ) {
    final history = _readList(item, ['statusHistory', 'timeline']);
    final events = <ReservationTimelineEvent>[];

    if (history != null) {
      for (final rawEvent in history) {
        if (rawEvent is! Map) {
          continue;
        }
        final event = asJsonMap(rawEvent);
        final status = _readString(event, ['status', 'toStatus']);
        final action = _readString(event, ['action', 'type']);
        final timestamp =
            _readDateTime(event, ['createdAt', 'timestamp']) ??
            summary.createdAt;
        final actor =
            _readString(event, ['actorLabel', 'actorType', 'actor']) ??
            'System';
        final reason =
            _readString(event, ['reason', 'message', 'note']) ??
            ReservationStatusX.parse(status).description;

        events.add(
          ReservationTimelineEvent(
            title: _timelineTitle(status: status, action: action),
            description: reason,
            timestamp: timestamp,
            actorLabel: actor,
          ),
        );
      }
    }

    if (events.isEmpty) {
      events.add(
        ReservationTimelineEvent(
          title: 'Reservation created',
          description: summary.status.description,
          timestamp: summary.createdAt,
          actorLabel: 'System',
        ),
      );
    }

    events.sort((left, right) => right.timestamp.compareTo(left.timestamp));
    return events;
  }

  List<ReservationChangeEntry> _parseChangeHistory(JsonMap item) {
    final rawChanges = _readList(item, ['changeRequests', 'changes']);
    if (rawChanges == null) {
      return const [];
    }

    final changes = <ReservationChangeEntry>[];
    for (final rawChange in rawChanges) {
      if (rawChange is! Map) {
        continue;
      }
      final change = asJsonMap(rawChange);
      final proposedTime = _readDateTime(change, [
        'proposedStartAt',
        'proposedTime',
      ]);
      if (proposedTime == null) {
        continue;
      }

      final actor =
          ReservationActorX.parse(
            _readString(change, ['requestedBy', 'requestedByRole', 'actor']),
          ) ??
          ReservationActor.customer;
      final status = _readString(change, ['status'])?.trim().toUpperCase();
      changes.add(
        ReservationChangeEntry(
          proposedTime: proposedTime,
          reason:
              _readString(change, ['reason', 'note']) ?? 'No reason provided.',
          requestedByLabel: actor.label,
          statusLabel: _changeStatusLabel(actor, status),
          createdAt: _readDateTime(change, ['createdAt']) ?? DateTime.now(),
        ),
      );
    }

    changes.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return changes;
  }

  _BackendChangeRequest? _extractLatestPendingChange(JsonMap item) {
    final rawChanges = _readList(item, ['changeRequests', 'changes']);
    if (rawChanges == null) {
      return null;
    }

    final pending = <_BackendChangeRequest>[];
    for (final rawChange in rawChanges) {
      if (rawChange is! Map) {
        continue;
      }

      final change = asJsonMap(rawChange);
      final status = _readString(change, ['status'])?.trim().toUpperCase();
      if (status != null && status != 'PENDING' && status != 'REQUESTED') {
        continue;
      }

      final proposedTime = _readDateTime(change, [
        'proposedStartAt',
        'proposedTime',
      ]);
      final id = _readString(change, ['id']);
      final actor = ReservationActorX.parse(
        _readString(change, ['requestedBy', 'requestedByRole', 'actor']),
      );
      if (id == null || proposedTime == null || actor == null) {
        continue;
      }

      pending.add(
        _BackendChangeRequest(
          id: id,
          requestedBy: actor,
          proposedTime: proposedTime,
          createdAt: _readDateTime(change, ['createdAt']) ?? DateTime.now(),
        ),
      );
    }

    if (pending.isEmpty) {
      return null;
    }

    pending.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return pending.first;
  }

  NoShowObjection? _parseNoShowObjection(JsonMap item) {
    final objection = _readMap(item, ['objection', 'latestObjection']);
    if (objection == null) {
      return null;
    }

    final submittedAt = _readDateTime(objection, ['createdAt', 'submittedAt']);
    if (submittedAt == null) {
      return null;
    }

    return NoShowObjection(
      reason: NoShowObjectionReasonX.parse(_readString(objection, ['reason'])),
      details:
          _readString(objection, ['details', 'message']) ??
          'No details provided.',
      status: NoShowObjectionStatusX.parse(_readString(objection, ['status'])),
      submittedAt: submittedAt,
      resolutionNote: _readString(objection, ['resolutionNote', 'note']),
    );
  }

  String? _historyReasonForStatus(List<dynamic>? history, String status) {
    if (history == null) {
      return null;
    }

    for (final rawEvent in history) {
      if (rawEvent is! Map) {
        continue;
      }
      final event = asJsonMap(rawEvent);
      final eventStatus = _readString(event, [
        'status',
        'toStatus',
      ])?.trim().toUpperCase();
      if (eventStatus == status) {
        return _readString(event, ['reason', 'message', 'note']);
      }
    }

    return null;
  }

  String _timelineTitle({String? status, String? action}) {
    final normalizedStatus = status?.trim().toUpperCase();
    switch (normalizedStatus) {
      case 'PENDING':
      case 'PENDING_APPROVAL':
        return 'Reservation requested';
      case 'CONFIRMED':
        return 'Reservation confirmed';
      case 'CANCELLED':
        return 'Reservation cancelled';
      case 'COMPLETED':
        return 'Reservation completed';
      case 'NO_SHOW':
        return 'No-show recorded';
      case 'REJECTED':
        return 'Reservation rejected';
      case 'EXPIRED':
        return 'Reservation expired';
    }

    if (action != null && action.trim().isNotEmpty) {
      return action.trim();
    }

    return 'Reservation updated';
  }

  String _changeStatusLabel(ReservationActor actor, String? status) {
    switch (status) {
      case 'ACCEPTED':
        return actor == ReservationActor.customer
            ? 'Accepted by provider'
            : 'Accepted by customer';
      case 'REJECTED':
        return actor == ReservationActor.customer
            ? 'Declined by provider'
            : 'Declined by customer';
      case 'PENDING':
      case 'REQUESTED':
      default:
        return actor == ReservationActor.customer
            ? 'Pending provider response'
            : 'Pending customer response';
    }
  }

  String _backendObjectionReason(NoShowObjectionReason reason) {
    return switch (reason) {
      NoShowObjectionReason.arrivedOnTime => 'ARRIVED_ON_TIME',
      NoShowObjectionReason.communicationIssue => 'COMMUNICATION_ISSUE',
      NoShowObjectionReason.providerIssue => 'PROVIDER_ISSUE',
      NoShowObjectionReason.other => 'OTHER',
    };
  }

  ApprovalMode _parseApprovalMode(JsonMap service, JsonMap item) {
    final explicit = _readString(service, [
      'approvalMode',
      'approval_mode',
      'approvalType',
    ]);
    if (explicit != null) {
      final normalized = explicit.toLowerCase();
      if (normalized.contains('manual')) {
        return ApprovalMode.manual;
      }
      if (normalized.contains('auto')) {
        return ApprovalMode.automatic;
      }
    }

    final manual =
        _readBool(service, [
          'manualApproval',
          'requiresManualApproval',
          'isManualApproval',
        ]) ??
        _readBool(item, ['manualApproval']);
    return manual == true ? ApprovalMode.manual : ApprovalMode.automatic;
  }

  List<JsonMap> _extractItems(dynamic payload, List<String> keys) {
    if (payload is List) {
      return asJsonMapList(payload);
    }
    if (payload is Map) {
      final map = asJsonMap(payload);
      for (final key in keys) {
        final value = _readPath(map, key);
        if (value is List) {
          return asJsonMapList(value);
        }
      }
    }
    return const [];
  }
  
  void testParseCustomerReservations(dynamic payload) {
      final items = _extractItems(payload, ['items', 'reservations']);
      print('Items parsed: ${items.length}');
      
      for (var item in items) {
           _parseReservationSummary(asJsonMap(item));
      }
  }

  JsonMap _extractEntity(dynamic payload, List<String> keys) {
    if (payload is Map) {
      final map = asJsonMap(payload);
      for (final key in keys) {
        final value = _readPath(map, key);
        if (value is Map) {
          return asJsonMap(value);
        }
      }
      return map;
    }

    throw const AppException(
      'Unexpected reservation payload returned by the server.',
      type: AppExceptionType.server,
    );
  }

  JsonMap? _readMap(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is Map) {
        return asJsonMap(value);
      }
    }
    return null;
  }

  List<dynamic>? _readList(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is List) {
        return value;
      }
    }
    return null;
  }

  String? _readString(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  bool? _readBool(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }
    return null;
  }

  int? _readInt(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  double? _readDouble(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  DateTime? _readDateTime(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  dynamic _readPath(dynamic source, String path) {
    final segments = path.split('.');
    dynamic current = source;
    for (final segment in segments) {
      if (current is Map) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}

class _BackendReservationSnapshot {
  const _BackendReservationSnapshot({
    required this.detail,
    required this.pendingChangeRequestId,
    required this.pendingChangeRequestedBy,
  });

  final ReservationDetail detail;
  final String? pendingChangeRequestId;
  final ReservationActor? pendingChangeRequestedBy;
}

class _BackendChangeRequest {
  const _BackendChangeRequest({
    required this.id,
    required this.requestedBy,
    required this.proposedTime,
    required this.createdAt,
  });

  final String id;
  final ReservationActor requestedBy;
  final DateTime proposedTime;
  final DateTime createdAt;
}

