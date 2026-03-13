import 'package:intl/intl.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

enum ReservationStatus {
  pendingApproval,
  confirmed,
  changeRequested,
  cancelled,
  completed,
  noShow,
  rejected,
  expired,
}

extension ReservationStatusX on ReservationStatus {
  String get label => switch (this) {
    ReservationStatus.pendingApproval => 'Pending approval',
    ReservationStatus.confirmed => 'Confirmed',
    ReservationStatus.changeRequested => 'Change requested',
    ReservationStatus.cancelled => 'Cancelled',
    ReservationStatus.completed => 'Completed',
    ReservationStatus.noShow => 'No-show',
    ReservationStatus.rejected => 'Rejected',
    ReservationStatus.expired => 'Expired',
  };

  String get description => switch (this) {
    ReservationStatus.pendingApproval =>
      'Waiting for the provider to respond inside the 5-minute window.',
    ReservationStatus.confirmed => 'The reservation is confirmed and upcoming.',
    ReservationStatus.changeRequested =>
      'A new time was proposed and is awaiting a response.',
    ReservationStatus.cancelled => 'The reservation was cancelled.',
    ReservationStatus.completed =>
      'The reservation was completed successfully.',
    ReservationStatus.noShow =>
      'The reservation ended as a no-show under the waiting-time policy.',
    ReservationStatus.rejected => 'The provider rejected the request.',
    ReservationStatus.expired =>
      'The manual approval window closed without a provider response.',
  };

  bool get isTerminal => switch (this) {
    ReservationStatus.pendingApproval => false,
    ReservationStatus.confirmed => false,
    ReservationStatus.changeRequested => false,
    ReservationStatus.cancelled => true,
    ReservationStatus.completed => true,
    ReservationStatus.noShow => true,
    ReservationStatus.rejected => true,
    ReservationStatus.expired => true,
  };
}

extension ReservationSummaryX on ReservationSummary {
  bool get isAwaitingProviderAction {
    if (effectiveStatus == ReservationStatus.pendingApproval) {
      return true;
    }

    return effectiveStatus == ReservationStatus.changeRequested &&
        latestChangeRequestedBy == ReservationActor.customer;
  }

  bool get isAwaitingCustomerAction {
    return effectiveStatus == ReservationStatus.changeRequested &&
        latestChangeRequestedBy == ReservationActor.provider;
  }

  bool get isActiveToday {
    if (effectiveStatus.isTerminal) {
      return false;
    }

    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }
}

enum ReservationActor { customer, provider }

enum CompletionMethod { qr, manual }

extension CompletionMethodX on CompletionMethod {
  String get label => switch (this) {
    CompletionMethod.qr => 'Completed via QR',
    CompletionMethod.manual => 'Completed manually by provider',
  };
}

class ReservationTimelineEvent {
  const ReservationTimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.actorLabel,
  });

  final String title;
  final String description;
  final DateTime timestamp;
  final String actorLabel;

  String get timestampLabel => DateFormat('MMM d · HH:mm').format(timestamp);
}

class ReservationChangeEntry {
  const ReservationChangeEntry({
    required this.proposedTime,
    required this.reason,
    required this.requestedByLabel,
    required this.statusLabel,
    required this.createdAt,
  });

  final DateTime proposedTime;
  final String reason;
  final String requestedByLabel;
  final String statusLabel;
  final DateTime createdAt;

  String get proposedTimeLabel =>
      DateFormat('EEE, MMM d · HH:mm').format(proposedTime);

  String get createdAtLabel => DateFormat('MMM d · HH:mm').format(createdAt);
}

class ReservationSummary {
  const ReservationSummary({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    required this.providerName,
    required this.customerName,
    required this.addressLine,
    required this.scheduledAt,
    required this.createdAt,
    required this.status,
    required this.approvalMode,
    required this.priceLabel,
    this.latestChangeRequestedBy,
    this.brandId,
    this.brandName,
    this.note,
    this.responseDeadline,
  });

  final String id;
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String providerName;
  final String customerName;
  final String addressLine;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final ReservationStatus status;
  final ApprovalMode approvalMode;
  final String priceLabel;
  final ReservationActor? latestChangeRequestedBy;
  final String? brandId;
  final String? brandName;
  final String? note;
  final DateTime? responseDeadline;

  String get scheduledAtLabel =>
      DateFormat('EEE, MMM d · HH:mm').format(scheduledAt);

  String get createdAtLabel => DateFormat('MMM d · HH:mm').format(createdAt);

  ReservationStatus get effectiveStatus {
    if (status == ReservationStatus.pendingApproval &&
        responseDeadline != null &&
        DateTime.now().isAfter(responseDeadline!)) {
      return ReservationStatus.expired;
    }
    return status;
  }

  Duration? get pendingTimeRemaining {
    if (responseDeadline == null) {
      return null;
    }
    final remaining = responseDeadline!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class ReservationDetail {
  const ReservationDetail({
    required this.summary,
    required this.timeline,
    required this.changeHistory,
    this.cancellationReason,
    this.rejectionReason,
    this.noShowReason,
    this.completionMethod,
  });

  final ReservationSummary summary;
  final List<ReservationTimelineEvent> timeline;
  final List<ReservationChangeEntry> changeHistory;
  final String? cancellationReason;
  final String? rejectionReason;
  final String? noShowReason;
  final CompletionMethod? completionMethod;
}

class ProviderDashboardData {
  const ProviderDashboardData({
    required this.pendingRequests,
    required this.todayReservations,
    required this.pendingCount,
    required this.confirmedTodayCount,
    required this.serviceCount,
    required this.brandCount,
  });

  final List<ReservationSummary> pendingRequests;
  final List<ReservationSummary> todayReservations;
  final int pendingCount;
  final int confirmedTodayCount;
  final int serviceCount;
  final int brandCount;
}

class ReservationChangeDraft {
  const ReservationChangeDraft({
    required this.proposedTime,
    required this.reason,
  });

  final DateTime proposedTime;
  final String reason;
}
