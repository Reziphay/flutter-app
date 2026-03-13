enum ReportTargetType { service, provider, brand, reservation }

extension ReportTargetTypeX on ReportTargetType {
  String get label => switch (this) {
    ReportTargetType.service => 'Service',
    ReportTargetType.provider => 'Provider',
    ReportTargetType.brand => 'Brand',
    ReportTargetType.reservation => 'Reservation issue',
  };
}

enum ReportReason {
  spamOrFake,
  misleadingInfo,
  abusiveBehavior,
  safetyConcern,
  unavailableOrWrongPrice,
  other,
}

extension ReportReasonX on ReportReason {
  String get label => switch (this) {
    ReportReason.spamOrFake => 'Spam or fake',
    ReportReason.misleadingInfo => 'Misleading information',
    ReportReason.abusiveBehavior => 'Abusive behavior',
    ReportReason.safetyConcern => 'Safety concern',
    ReportReason.unavailableOrWrongPrice => 'Availability or price issue',
    ReportReason.other => 'Other',
  };

  String get description => switch (this) {
    ReportReason.spamOrFake =>
      'The listing or issue looks fraudulent, duplicated, or fake.',
    ReportReason.misleadingInfo =>
      'Photos, details, or claims do not match the real service.',
    ReportReason.abusiveBehavior =>
      'The behavior described is abusive, insulting, or inappropriate.',
    ReportReason.safetyConcern =>
      'There is a trust, safety, or hygiene concern that needs review.',
    ReportReason.unavailableOrWrongPrice =>
      'The advertised time, availability, or price appears inaccurate.',
    ReportReason.other =>
      'Use this when the issue does not fit the standard reasons above.',
  };
}

class ReportTargetSummary {
  const ReportTargetSummary({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
  });

  final ReportTargetType type;
  final String id;
  final String title;
  final String? subtitle;
}

class ReportSubmissionDraft {
  const ReportSubmissionDraft({required this.reason, required this.details});

  final ReportReason reason;
  final String details;
}

class SubmittedReport {
  const SubmittedReport({
    required this.id,
    required this.target,
    required this.reason,
    required this.details,
    required this.reportedBy,
    required this.createdAt,
  });

  final String id;
  final ReportTargetSummary target;
  final ReportReason reason;
  final String details;
  final String reportedBy;
  final DateTime createdAt;
}
