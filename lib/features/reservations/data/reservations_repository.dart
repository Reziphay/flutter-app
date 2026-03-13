import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

const _activeProviderContextId = 'rauf-mammadov';
const _activeCustomerContextId = 'current-user';

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

final activeProviderContextProvider = Provider<String>(
  (ref) => _activeProviderContextId,
);

final activeCustomerContextProvider = Provider<String>(
  (ref) => _activeCustomerContextId,
);

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

class MockReservationsRepository implements ReservationsRepository {
  MockReservationsRepository({required DiscoveryRepository discoveryRepository})
    : _discoveryRepository = discoveryRepository;

  final DiscoveryRepository _discoveryRepository;

  final List<_ReservationRecord> _records = [
    _ReservationRecord(
      id: 'r_1001',
      serviceId: 'classic-haircut',
      customerId: _activeCustomerContextId,
      customerName: 'You',
      scheduledAt: _dateAt(1, 14, 0),
      status: ReservationStatus.pendingApproval,
      approvalMode: ApprovalMode.manual,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      responseDeadline: DateTime.now().add(const Duration(minutes: 3)),
      note: 'If possible, I prefer a sharper side fade.',
      timeline: [
        ReservationTimelineEvent(
          title: 'Reservation requested',
          description: 'A manual-approval request was sent to the provider.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          actorLabel: 'You',
        ),
      ],
      changeHistory: [],
    ),
    _ReservationRecord(
      id: 'r_1002',
      serviceId: 'precision-beard-trim',
      customerId: _activeCustomerContextId,
      customerName: 'You',
      scheduledAt: _dateAt(2, 16, 30),
      status: ReservationStatus.confirmed,
      approvalMode: ApprovalMode.automatic,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      note: '',
      timeline: [
        ReservationTimelineEvent(
          title: 'Reservation created',
          description: 'The service was auto-confirmed instantly.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          actorLabel: 'System',
        ),
      ],
      changeHistory: [],
    ),
    _ReservationRecord(
      id: 'r_1003',
      serviceId: 'dental-consultation',
      customerId: _activeCustomerContextId,
      customerName: 'You',
      scheduledAt: _dateAt(-6, 11, 0),
      status: ReservationStatus.completed,
      approvalMode: ApprovalMode.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      timeline: [
        ReservationTimelineEvent(
          title: 'Reservation completed',
          description: 'The clinic completed the reservation manually.',
          timestamp: DateTime.now().subtract(const Duration(days: 6)),
          actorLabel: 'Kamala Aliyeva',
        ),
      ],
      completionMethod: CompletionMethod.manual,
      changeHistory: [],
    ),
    _ReservationRecord(
      id: 'r_1004',
      serviceId: 'signature-skin-reset',
      customerId: _activeCustomerContextId,
      customerName: 'You',
      scheduledAt: _dateAt(-1, 13, 0),
      status: ReservationStatus.cancelled,
      approvalMode: ApprovalMode.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      cancellationReason: 'Schedule conflict on my side.',
      timeline: [
        ReservationTimelineEvent(
          title: 'Reservation cancelled',
          description: 'The customer cancelled before the appointment.',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          actorLabel: 'You',
        ),
      ],
      changeHistory: [],
    ),
    _ReservationRecord(
      id: 'r_1005',
      serviceId: 'strategy-session',
      customerId: _activeCustomerContextId,
      customerName: 'You',
      scheduledAt: _dateAt(-10, 18, 0),
      status: ReservationStatus.noShow,
      approvalMode: ApprovalMode.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      noShowReason: 'Marked as no-show after the waiting-time window ended.',
      timeline: [
        ReservationTimelineEvent(
          title: 'No-show recorded',
          description:
              'The provider recorded a no-show after the waiting-time tolerance.',
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
          actorLabel: 'Emin Jafarov',
        ),
      ],
      changeHistory: [],
    ),
    _ReservationRecord(
      id: 'r_1006',
      serviceId: 'classic-haircut',
      customerId: 'amina-hasanli',
      customerName: 'Amina Hasanli',
      scheduledAt: _dateAt(0, 15, 30),
      status: ReservationStatus.pendingApproval,
      approvalMode: ApprovalMode.manual,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      responseDeadline: DateTime.now().add(const Duration(minutes: 4)),
      note: 'Need a quick cleanup before an evening event.',
      timeline: [
        ReservationTimelineEvent(
          title: 'Reservation requested',
          description: 'Awaiting provider response.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          actorLabel: 'Amina Hasanli',
        ),
      ],
      changeHistory: [],
    ),
    _ReservationRecord(
      id: 'r_1007',
      serviceId: 'precision-beard-trim',
      customerId: 'farid-qasimov',
      customerName: 'Farid Qasimov',
      scheduledAt: _dateAt(0, 18, 0),
      status: ReservationStatus.confirmed,
      approvalMode: ApprovalMode.automatic,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      timeline: [
        ReservationTimelineEvent(
          title: 'Reservation confirmed',
          description: 'The slot confirmed automatically.',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          actorLabel: 'System',
        ),
      ],
      changeHistory: [],
    ),
    _ReservationRecord(
      id: 'r_1008',
      serviceId: 'classic-haircut',
      customerId: 'leyla-mammadova',
      customerName: 'Leyla Mammadova',
      scheduledAt: _dateAt(2, 12, 0),
      status: ReservationStatus.changeRequested,
      approvalMode: ApprovalMode.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      timeline: [
        ReservationTimelineEvent(
          title: 'Change requested',
          description: 'The customer proposed a new time.',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          actorLabel: 'Leyla Mammadova',
        ),
      ],
      changeHistory: [
        ReservationChangeEntry(
          proposedTime: _dateAt(2, 12, 0),
          reason: 'Running late at work tomorrow morning.',
          requestedByLabel: 'Customer',
          statusLabel: 'Awaiting provider response',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    ),
    _ReservationRecord(
      id: 'r_1009',
      serviceId: 'classic-haircut',
      customerId: 'nigar-safarli',
      customerName: 'Nigar Safarli',
      scheduledAt: _dateAt(-2, 17, 0),
      status: ReservationStatus.completed,
      approvalMode: ApprovalMode.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      timeline: [
        ReservationTimelineEvent(
          title: 'Reservation completed via QR',
          description: 'The customer scanned the provider QR successfully.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          actorLabel: 'System',
        ),
      ],
      completionMethod: CompletionMethod.qr,
      changeHistory: [],
    ),
  ];

  int _idSeed = 2000;

  @override
  Future<void> acceptProviderReservation(String reservationId) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);

    final latestChange = _latestChange(record);
    if (record.status == ReservationStatus.changeRequested &&
        latestChange != null &&
        latestChange.requestedByLabel == 'Customer') {
      record.scheduledAt = latestChange.proposedTime;
      _updateLatestChangeStatus(record, 'Accepted by provider');
      record.timeline.insert(
        0,
        ReservationTimelineEvent(
          title: 'Change accepted',
          description: 'The provider accepted the customer\'s proposed time.',
          timestamp: DateTime.now(),
          actorLabel: 'Provider',
        ),
      );
    } else {
      record.timeline.insert(
        0,
        ReservationTimelineEvent(
          title: 'Reservation confirmed',
          description: 'The provider accepted the reservation request.',
          timestamp: DateTime.now(),
          actorLabel: 'Provider',
        ),
      );
    }

    record.status = ReservationStatus.confirmed;
    record.responseDeadline = null;
  }

  @override
  Future<void> acceptCustomerChange(String reservationId) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);

    final latestChange = _latestChange(record);
    if (record.status != ReservationStatus.changeRequested ||
        latestChange == null ||
        latestChange.requestedByLabel != 'Provider') {
      throw const AppException(
        'No provider change request is waiting for a customer response.',
      );
    }

    record.scheduledAt = latestChange.proposedTime;
    record.status = ReservationStatus.confirmed;
    _updateLatestChangeStatus(record, 'Accepted by customer');
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Change accepted',
        description: 'The customer accepted the provider\'s proposed time.',
        timestamp: DateTime.now(),
        actorLabel: 'Customer',
      ),
    );
  }

  @override
  Future<void> cancelCustomerReservation({
    required String reservationId,
    required String reason,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);
    record.status = ReservationStatus.cancelled;
    record.responseDeadline = null;
    record.cancellationReason = _safeReason(
      reason,
      fallback: 'Cancelled by customer before the appointment time.',
    );
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Reservation cancelled',
        description: record.cancellationReason!,
        timestamp: DateTime.now(),
        actorLabel: 'Customer',
      ),
    );
  }

  @override
  Future<void> cancelProviderReservation({
    required String reservationId,
    required String reason,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);
    record.status = ReservationStatus.cancelled;
    record.responseDeadline = null;
    record.cancellationReason = _safeReason(
      reason,
      fallback:
          'Cancelled by provider because the slot can no longer be served.',
    );
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Reservation cancelled by provider',
        description: record.cancellationReason!,
        timestamp: DateTime.now(),
        actorLabel: 'Provider',
      ),
    );
  }

  @override
  Future<void> declineCustomerChange({
    required String reservationId,
    required String reason,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);

    final latestChange = _latestChange(record);
    if (record.status != ReservationStatus.changeRequested ||
        latestChange == null ||
        latestChange.requestedByLabel != 'Customer') {
      throw const AppException(
        'No customer change request is waiting for a provider response.',
      );
    }

    record.status = ReservationStatus.confirmed;
    record.responseDeadline = null;
    _updateLatestChangeStatus(record, 'Declined by provider');
    final declineReason = _safeReason(
      reason,
      fallback: 'The original reservation time still works best.',
    );
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Original time kept',
        description:
            'The provider kept the original time. Reason: $declineReason',
        timestamp: DateTime.now(),
        actorLabel: 'Provider',
      ),
    );
  }

  @override
  Future<void> completeProviderReservation(String reservationId) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    if (record.status != ReservationStatus.confirmed) {
      throw const AppException('Only confirmed reservations can be completed.');
    }
    record.status = ReservationStatus.completed;
    record.responseDeadline = null;
    record.completionMethod = CompletionMethod.manual;
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Reservation completed',
        description: 'The provider completed the reservation manually.',
        timestamp: DateTime.now(),
        actorLabel: 'Provider',
      ),
    );
  }

  @override
  Future<void> completeReservationViaQr(
    String reservationId, {
    String? payload,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    if (record.status == ReservationStatus.completed &&
        record.completionMethod == CompletionMethod.qr) {
      return;
    }
    if (record.status != ReservationStatus.confirmed) {
      throw const AppException('Only confirmed reservations can be completed.');
    }
    record.status = ReservationStatus.completed;
    record.responseDeadline = null;
    record.completionMethod = CompletionMethod.qr;
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Reservation completed via QR',
        description:
            'The customer scanned the provider QR and the reservation was verified.',
        timestamp: DateTime.now(),
        actorLabel: 'System',
      ),
    );
  }

  @override
  Future<String> createReservation({
    required String serviceId,
    required DateTime scheduledAt,
    required String note,
    required String customerId,
    required String customerName,
  }) async {
    await _delay();
    final service = _discoveryRepository.serviceSummaryById(serviceId);
    if (service == null) {
      throw const AppException('Service not found.');
    }

    final reservationId = 'r_${_idSeed++}';
    final status = service.approvalMode == ApprovalMode.manual
        ? ReservationStatus.pendingApproval
        : ReservationStatus.confirmed;

    final record = _ReservationRecord(
      id: reservationId,
      serviceId: serviceId,
      customerId: customerId,
      customerName: customerName,
      scheduledAt: scheduledAt,
      status: status,
      approvalMode: service.approvalMode,
      createdAt: DateTime.now(),
      responseDeadline: service.approvalMode == ApprovalMode.manual
          ? DateTime.now().add(const Duration(minutes: 5))
          : null,
      note: note,
      timeline: [
        ReservationTimelineEvent(
          title: service.approvalMode == ApprovalMode.manual
              ? 'Reservation requested'
              : 'Reservation confirmed',
          description: service.approvalMode == ApprovalMode.manual
              ? 'The provider has 5 minutes to respond.'
              : 'The reservation confirmed instantly.',
          timestamp: DateTime.now(),
          actorLabel: service.approvalMode == ApprovalMode.manual
              ? customerName
              : 'System',
        ),
      ],
      changeHistory: [],
    );

    _records.insert(0, record);
    return reservationId;
  }

  @override
  Future<ReservationDetail> getCustomerReservationDetail(
    String reservationId,
    String customerId,
  ) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureCustomerOwns(record, customerId);
    return _buildDetail(record);
  }

  @override
  Future<CustomerPenaltySummary> getCustomerPenaltySummary(
    String customerId,
  ) async {
    await _delay();
    _syncExpirations();

    final customerRecords = _records
        .where((record) => record.customerId == customerId)
        .toList();
    final noShows = customerRecords
        .where((record) => record.status == ReservationStatus.noShow)
        .toList();
    final objectionsUnderReview = noShows
        .where(
          (record) =>
              record.noShowObjection?.status ==
              NoShowObjectionStatus.underReview,
        )
        .length;

    DateTime? latestPenaltyAt;
    for (final record in noShows) {
      if (latestPenaltyAt == null ||
          record.scheduledAt.isAfter(latestPenaltyAt)) {
        latestPenaltyAt = record.scheduledAt;
      }
    }

    return CustomerPenaltySummary(
      activePenaltyPoints: noShows.length,
      noShowCount: noShows.length,
      objectionsUnderReview: objectionsUnderReview,
      latestPenaltyAt: latestPenaltyAt,
    );
  }

  @override
  Future<List<ReservationSummary>> getCustomerReservations(
    String customerId,
  ) async {
    await _delay();
    _syncExpirations();
    return _records
        .where((record) => record.customerId == customerId)
        .map(_buildSummary)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ProviderDashboardData> getProviderDashboard(String providerId) async {
    await _delay();
    _syncExpirations();

    final providerReservations = _records.where((record) {
      final service = _discoveryRepository.serviceSummaryById(record.serviceId);
      return service?.providerId == providerId;
    }).toList();

    final pending =
        providerReservations
            .where(_requiresProviderAttention)
            .map(_buildSummary)
            .toList()
          ..sort(_compareProviderAttention);
    final today =
        providerReservations
            .where(_isOperationalToday)
            .map(_buildSummary)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final providerProfile = await _discoveryRepository.getProviderDetail(
      providerId,
    );

    return ProviderDashboardData(
      pendingRequests: pending,
      todayReservations: today,
      pendingCount: pending.length,
      confirmedTodayCount: today
          .where(
            (reservation) => reservation.status == ReservationStatus.confirmed,
          )
          .length,
      serviceCount: providerProfile.services.length,
      brandCount: providerProfile.associatedBrands.length,
    );
  }

  @override
  Future<ReservationDetail> getProviderReservationDetail(
    String reservationId,
    String providerId,
  ) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    final service = _discoveryRepository.serviceSummaryById(record.serviceId);
    if (service == null || service.providerId != providerId) {
      throw const AppException('Reservation not found for this provider.');
    }
    return _buildDetail(record);
  }

  @override
  Future<List<ReservationSummary>> getProviderReservations(
    String providerId,
  ) async {
    await _delay();
    _syncExpirations();
    return _records
        .where((record) {
          final service = _discoveryRepository.serviceSummaryById(
            record.serviceId,
          );
          return service?.providerId == providerId;
        })
        .map(_buildSummary)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  @override
  Future<void> rejectProviderReservation({
    required String reservationId,
    required String reason,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);
    record.status = ReservationStatus.rejected;
    record.rejectionReason = _safeReason(
      reason,
      fallback: 'The provider declined this request.',
    );
    record.responseDeadline = null;
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Reservation rejected',
        description: record.rejectionReason!,
        timestamp: DateTime.now(),
        actorLabel: 'Provider',
      ),
    );
  }

  @override
  Future<void> requestCustomerChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);
    record.status = ReservationStatus.changeRequested;
    record.responseDeadline = null;
    record.changeHistory.insert(
      0,
      ReservationChangeEntry(
        proposedTime: proposedTime,
        reason: _safeReason(
          reason,
          fallback: 'Customer requested a different time.',
        ),
        requestedByLabel: 'Customer',
        statusLabel: 'Awaiting provider response',
        createdAt: DateTime.now(),
      ),
    );
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Change requested',
        description: record.changeHistory.first.reason,
        timestamp: DateTime.now(),
        actorLabel: 'Customer',
      ),
    );
  }

  @override
  Future<void> requestProviderChange({
    required String reservationId,
    required DateTime proposedTime,
    required String reason,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureActionable(record);
    record.status = ReservationStatus.changeRequested;
    record.responseDeadline = null;
    record.changeHistory.insert(
      0,
      ReservationChangeEntry(
        proposedTime: proposedTime,
        reason: _safeReason(
          reason,
          fallback: 'Provider suggested a different time.',
        ),
        requestedByLabel: 'Provider',
        statusLabel: 'Awaiting customer response',
        createdAt: DateTime.now(),
      ),
    );
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'Provider proposed a new time',
        description: record.changeHistory.first.reason,
        timestamp: DateTime.now(),
        actorLabel: 'Provider',
      ),
    );
  }

  @override
  Future<void> submitNoShowObjection({
    required String reservationId,
    required String customerId,
    required NoShowObjectionReason reason,
    required String details,
  }) async {
    await _delay();
    _syncExpirations();
    final record = _findRecord(reservationId);
    _ensureCustomerOwns(record, customerId);

    if (record.status != ReservationStatus.noShow) {
      throw const AppException(
        'Only no-show reservations can receive an objection.',
      );
    }

    if (record.noShowObjection != null) {
      throw const AppException('An objection was already submitted.');
    }

    final objection = NoShowObjection(
      reason: reason,
      details: _safeReason(
        details,
        fallback:
            'The customer disputes the no-show outcome and requested a manual review.',
      ),
      status: NoShowObjectionStatus.underReview,
      submittedAt: DateTime.now(),
    );

    record.noShowObjection = objection;
    record.timeline.insert(
      0,
      ReservationTimelineEvent(
        title: 'No-show objection submitted',
        description: objection.details,
        timestamp: objection.submittedAt,
        actorLabel: 'Customer',
      ),
    );
  }

  ReservationDetail _buildDetail(_ReservationRecord record) {
    return ReservationDetail(
      summary: _buildSummary(record),
      timeline: List<ReservationTimelineEvent>.of(record.timeline),
      changeHistory: List<ReservationChangeEntry>.of(record.changeHistory),
      cancellationReason: record.cancellationReason,
      rejectionReason: record.rejectionReason,
      noShowReason: record.noShowReason,
      noShowObjection: record.noShowObjection,
      completionMethod: record.completionMethod,
    );
  }

  ReservationSummary _buildSummary(_ReservationRecord record) {
    final service = _discoveryRepository.serviceSummaryById(record.serviceId);
    if (service == null) {
      throw const AppException('Reservation references a missing service.');
    }

    return ReservationSummary(
      id: record.id,
      serviceId: service.id,
      serviceName: service.name,
      providerId: service.providerId,
      providerName: service.providerName,
      brandId: service.brandId,
      brandName: service.brandName,
      customerName: record.customerName,
      addressLine: service.addressLine,
      scheduledAt: record.scheduledAt,
      createdAt: record.createdAt,
      status: record.status,
      approvalMode: record.approvalMode,
      priceLabel: service.priceLabel,
      latestChangeRequestedBy: _latestChange(record) == null
          ? null
          : _actorFromLabel(_latestChange(record)!.requestedByLabel),
      latestChangeProposedTime: _latestChange(record)?.proposedTime,
      note: record.note,
      responseDeadline: record.responseDeadline,
    );
  }

  void _ensureActionable(_ReservationRecord record) {
    if (record.status.isTerminal) {
      throw const AppException('This reservation can no longer be changed.');
    }
  }

  void _ensureCustomerOwns(_ReservationRecord record, String customerId) {
    if (record.customerId != customerId) {
      throw const AppException('Reservation not found for this customer.');
    }
  }

  ReservationChangeEntry? _latestChange(_ReservationRecord record) {
    if (record.changeHistory.isEmpty) {
      return null;
    }
    return record.changeHistory.first;
  }

  void _updateLatestChangeStatus(
    _ReservationRecord record,
    String statusLabel,
  ) {
    if (record.changeHistory.isEmpty) {
      return;
    }

    final latestChange = record.changeHistory.first;
    record.changeHistory[0] = ReservationChangeEntry(
      proposedTime: latestChange.proposedTime,
      reason: latestChange.reason,
      requestedByLabel: latestChange.requestedByLabel,
      statusLabel: statusLabel,
      createdAt: latestChange.createdAt,
    );
  }

  String _safeReason(String input, {required String fallback}) {
    final trimmed = input.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  _ReservationRecord _findRecord(String reservationId) {
    for (final record in _records) {
      if (record.id == reservationId) {
        return record;
      }
    }
    throw const AppException('Reservation not found.');
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool _isOperationalToday(_ReservationRecord record) {
    return _isToday(record.scheduledAt) && !record.status.isTerminal;
  }

  bool _requiresProviderAttention(_ReservationRecord record) {
    if (record.status == ReservationStatus.pendingApproval) {
      return true;
    }

    return record.status == ReservationStatus.changeRequested &&
        _actorFromLabel(_latestChange(record)?.requestedByLabel) ==
            ReservationActor.customer;
  }

  int _compareProviderAttention(
    ReservationSummary left,
    ReservationSummary right,
  ) {
    final leftPriority = left.isPendingManualApproval ? 0 : 1;
    final rightPriority = right.isPendingManualApproval ? 0 : 1;

    if (leftPriority != rightPriority) {
      return leftPriority.compareTo(rightPriority);
    }

    if (left.isPendingManualApproval &&
        right.isPendingManualApproval &&
        left.responseDeadline != null &&
        right.responseDeadline != null) {
      return left.responseDeadline!.compareTo(right.responseDeadline!);
    }

    return left.scheduledAt.compareTo(right.scheduledAt);
  }

  ReservationActor? _actorFromLabel(String? label) {
    return switch (label) {
      'Customer' => ReservationActor.customer,
      'Provider' => ReservationActor.provider,
      _ => null,
    };
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 180));

  void _syncExpirations() {
    final now = DateTime.now();
    for (final record in _records) {
      if (record.status == ReservationStatus.pendingApproval &&
          record.responseDeadline != null &&
          now.isAfter(record.responseDeadline!)) {
        final expiredAt = record.responseDeadline!;
        record.status = ReservationStatus.expired;
        record.responseDeadline = null;
        record.timeline.insert(
          0,
          ReservationTimelineEvent(
            title: 'Request expired',
            description:
                'The provider did not respond inside the 5-minute manual approval window.',
            timestamp: expiredAt,
            actorLabel: 'System',
          ),
        );
      }
    }
  }
}

class _ReservationRecord {
  _ReservationRecord({
    required this.id,
    required this.serviceId,
    required this.customerId,
    required this.customerName,
    required this.scheduledAt,
    required this.status,
    required this.approvalMode,
    required this.createdAt,
    required this.timeline,
    required this.changeHistory,
    this.note,
    this.responseDeadline,
    this.cancellationReason,
    this.noShowReason,
    this.completionMethod,
  });

  final String id;
  final String serviceId;
  final String customerId;
  final String customerName;
  DateTime scheduledAt;
  ReservationStatus status;
  final ApprovalMode approvalMode;
  final DateTime createdAt;
  final String? note;
  DateTime? responseDeadline;
  final List<ReservationTimelineEvent> timeline;
  final List<ReservationChangeEntry> changeHistory;
  String? cancellationReason;
  String? rejectionReason;
  String? noShowReason;
  NoShowObjection? noShowObjection;
  CompletionMethod? completionMethod;
}

DateTime _dateAt(int dayOffset, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
}
