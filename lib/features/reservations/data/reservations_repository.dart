import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';

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

  Future<void> completeReservationViaQr(String reservationId);

  Future<void> completeProviderReservation(String reservationId);
}

final activeProviderContextProvider = Provider<String>(
  (ref) => _activeProviderContextId,
);

final activeCustomerContextProvider = Provider<String>(
  (ref) => _activeCustomerContextId,
);

final reservationsRepositoryProvider = Provider<ReservationsRepository>(
  (ref) => MockReservationsRepository(
    discoveryRepository: ref.watch(discoveryRepositoryProvider),
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

  Future<void> completeProviderReservation(String reservationId) async {
    await ref
        .read(reservationsRepositoryProvider)
        .completeProviderReservation(reservationId);
    _invalidate(reservationId);
  }

  Future<void> completeReservationViaQr(String reservationId) async {
    await ref
        .read(reservationsRepositoryProvider)
        .completeReservationViaQr(reservationId);
    _invalidate(reservationId);
  }

  void _invalidate(String reservationId) {
    ref.invalidate(customerReservationsProvider);
    ref.invalidate(providerReservationsProvider);
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(customerReservationDetailProvider(reservationId));
    ref.invalidate(providerReservationDetailProvider(reservationId));
  }
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
  Future<void> completeReservationViaQr(String reservationId) async {
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

    final pending = providerReservations
        .where(_requiresProviderAttention)
        .map(_buildSummary)
        .toList();
    final today = providerReservations
        .where(_isOperationalToday)
        .map(_buildSummary)
        .toList();

    final serviceIds = <String>{};
    final brandIds = <String>{};
    for (final record in providerReservations) {
      final service = _discoveryRepository.serviceSummaryById(record.serviceId);
      if (service != null) {
        serviceIds.add(service.id);
        if (service.brandId != null) {
          brandIds.add(service.brandId!);
        }
      }
    }

    return ProviderDashboardData(
      pendingRequests: pending,
      todayReservations: today,
      pendingCount: pending.length,
      confirmedTodayCount: today
          .where(
            (reservation) => reservation.status == ReservationStatus.confirmed,
          )
          .length,
      serviceCount: serviceIds.length,
      brandCount: brandIds.length,
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

  ReservationDetail _buildDetail(_ReservationRecord record) {
    return ReservationDetail(
      summary: _buildSummary(record),
      timeline: List<ReservationTimelineEvent>.of(record.timeline),
      changeHistory: List<ReservationChangeEntry>.of(record.changeHistory),
      cancellationReason: record.cancellationReason,
      rejectionReason: record.rejectionReason,
      noShowReason: record.noShowReason,
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
  CompletionMethod? completionMethod;
}

DateTime _dateAt(int dayOffset, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
}
