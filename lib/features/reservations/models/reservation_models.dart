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
  static ReservationStatus parse(String? rawValue) {
    switch (rawValue?.trim().toUpperCase()) {
      case 'PENDING':
      case 'PENDING_APPROVAL':
        return ReservationStatus.pendingApproval;
      case 'CONFIRMED':
        return ReservationStatus.confirmed;
      case 'CHANGE_REQUESTED':
      case 'RESCHEDULE_REQUESTED':
        return ReservationStatus.changeRequested;
      case 'CANCELLED':
        return ReservationStatus.cancelled;
      case 'COMPLETED':
        return ReservationStatus.completed;
      case 'NO_SHOW':
      case 'NOSHOW':
        return ReservationStatus.noShow;
      case 'REJECTED':
        return ReservationStatus.rejected;
      case 'EXPIRED':
        return ReservationStatus.expired;
      default:
        return ReservationStatus.pendingApproval;
    }
  }

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
  bool get isPendingManualApproval {
    return effectiveStatus == ReservationStatus.pendingApproval;
  }

  bool get isCustomerChangeRequest {
    return effectiveStatus == ReservationStatus.changeRequested &&
        latestChangeRequestedBy == ReservationActor.customer;
  }

  bool get isUrgentPendingWindow {
    final remaining = pendingTimeRemaining;
    if (remaining == null) {
      return false;
    }

    return remaining.inSeconds <= 120;
  }

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

extension ReservationActorX on ReservationActor {
  static ReservationActor? parse(String? rawValue) {
    switch (rawValue?.trim().toUpperCase()) {
      case 'CUSTOMER':
      case 'UCR':
        return ReservationActor.customer;
      case 'PROVIDER':
      case 'OWNER':
      case 'USO':
        return ReservationActor.provider;
      default:
        return null;
    }
  }

  String get label => switch (this) {
    ReservationActor.customer => 'Customer',
    ReservationActor.provider => 'Provider',
  };
}

enum CompletionMethod { qr, manual }

extension CompletionMethodX on CompletionMethod {
  static CompletionMethod? parse(String? rawValue) {
    switch (rawValue?.trim().toUpperCase()) {
      case 'QR':
      case 'COMPLETE_BY_QR':
        return CompletionMethod.qr;
      case 'MANUAL':
      case 'COMPLETE_MANUALLY':
        return CompletionMethod.manual;
      default:
        return null;
    }
  }

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
    this.latestChangeProposedTime,
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
  final DateTime? latestChangeProposedTime;
  final String? brandId;
  final String? brandName;
  final String? note;
  final DateTime? responseDeadline;

  String get scheduledAtLabel =>
      DateFormat('EEE, MMM d · HH:mm').format(scheduledAt);

  String get createdAtLabel => DateFormat('MMM d · HH:mm').format(createdAt);

  String? get latestChangeProposedTimeLabel => latestChangeProposedTime == null
      ? null
      : DateFormat('EEE, MMM d · HH:mm').format(latestChangeProposedTime!);

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
    this.noShowObjection,
    this.completionMethod,
  });

  final ReservationSummary summary;
  final List<ReservationTimelineEvent> timeline;
  final List<ReservationChangeEntry> changeHistory;
  final String? cancellationReason;
  final String? rejectionReason;
  final String? noShowReason;
  final NoShowObjection? noShowObjection;
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

enum NoShowObjectionReason {
  arrivedOnTime,
  communicationIssue,
  providerIssue,
  other,
}

extension NoShowObjectionReasonX on NoShowObjectionReason {
  static NoShowObjectionReason parse(String? rawValue) {
    switch (rawValue?.trim().toUpperCase()) {
      case 'ARRIVED_ON_TIME':
        return NoShowObjectionReason.arrivedOnTime;
      case 'COMMUNICATION_ISSUE':
        return NoShowObjectionReason.communicationIssue;
      case 'PROVIDER_ISSUE':
        return NoShowObjectionReason.providerIssue;
      case 'OTHER':
      default:
        return NoShowObjectionReason.other;
    }
  }

  String get label => switch (this) {
    NoShowObjectionReason.arrivedOnTime => 'I arrived on time',
    NoShowObjectionReason.communicationIssue =>
      'Communication or check-in issue',
    NoShowObjectionReason.providerIssue => 'Provider-side issue',
    NoShowObjectionReason.other => 'Other',
  };
}

enum NoShowObjectionStatus { underReview, accepted, rejected }

extension NoShowObjectionStatusX on NoShowObjectionStatus {
  static NoShowObjectionStatus parse(String? rawValue) {
    switch (rawValue?.trim().toUpperCase()) {
      case 'ACCEPTED':
        return NoShowObjectionStatus.accepted;
      case 'REJECTED':
        return NoShowObjectionStatus.rejected;
      case 'UNDER_REVIEW':
      case 'PENDING':
      default:
        return NoShowObjectionStatus.underReview;
    }
  }

  String get label => switch (this) {
    NoShowObjectionStatus.underReview => 'Under review',
    NoShowObjectionStatus.accepted => 'Accepted',
    NoShowObjectionStatus.rejected => 'Rejected',
  };

  String get description => switch (this) {
    NoShowObjectionStatus.underReview =>
      'The support team is reviewing the no-show dispute and timeline evidence.',
    NoShowObjectionStatus.accepted =>
      'The objection was accepted and the no-show penalty should be removed.',
    NoShowObjectionStatus.rejected =>
      'The dispute was reviewed but the no-show record remains in place.',
  };
}

class NoShowObjection {
  const NoShowObjection({
    required this.reason,
    required this.details,
    required this.status,
    required this.submittedAt,
    this.resolutionNote,
  });

  final NoShowObjectionReason reason;
  final String details;
  final NoShowObjectionStatus status;
  final DateTime submittedAt;
  final String? resolutionNote;

  String get submittedAtLabel =>
      DateFormat('MMM d · HH:mm').format(submittedAt);
}

class CustomerPenaltySummary {
  const CustomerPenaltySummary({
    required this.activePenaltyPoints,
    required this.noShowCount,
    required this.objectionsUnderReview,
    this.latestPenaltyAt,
  });

  final int activePenaltyPoints;
  final int noShowCount;
  final int objectionsUnderReview;
  final DateTime? latestPenaltyAt;

  String get summaryLabel {
    if (activePenaltyPoints == 0) {
      return 'No active penalties';
    }

    if (activePenaltyPoints == 1) {
      return '1 penalty point active';
    }

    return '$activePenaltyPoints penalty points active';
  }

  String get riskDescription {
    if (activePenaltyPoints >= 10) {
      return 'Account closure threshold reached.';
    }
    if (activePenaltyPoints >= 5) {
      return 'Suspension threshold reached.';
    }
    if (activePenaltyPoints == 0) {
      return 'Your reservation history has no active no-show penalties.';
    }

    return 'Penalty rules escalate at 5 points for suspension and 10 points for account closure.';
  }
}

class NoShowObjectionDraft {
  const NoShowObjectionDraft({required this.reason, required this.details});

  final NoShowObjectionReason reason;
  final String details;
}

class ReservationChangeDraft {
  const ReservationChangeDraft({
    required this.proposedTime,
    required this.reason,
  });

  final DateTime proposedTime;
  final String reason;
}
