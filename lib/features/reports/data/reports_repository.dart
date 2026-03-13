import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/reports/models/report_models.dart';

abstract class ReportsRepository {
  Future<void> submitReport({
    required ReportTargetSummary target,
    required ReportReason reason,
    required String details,
    required String reportedBy,
  });

  Future<List<SubmittedReport>> getSubmittedReports();
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => MockReportsRepository(),
);

final reportsActionsProvider = Provider<ReportsActions>(
  (ref) => ReportsActions(ref),
);

class ReportsActions {
  ReportsActions(this.ref);

  final Ref ref;

  Future<void> submitReport({
    required ReportTargetSummary target,
    required ReportReason reason,
    required String details,
  }) async {
    final reporterName = ref
        .read(sessionControllerProvider)
        .session
        ?.user
        .fullName;
    await ref
        .read(reportsRepositoryProvider)
        .submitReport(
          target: target,
          reason: reason,
          details: details,
          reportedBy: reporterName ?? 'Reziphay User',
        );
  }
}

class MockReportsRepository implements ReportsRepository {
  final List<SubmittedReport> _reports = [];
  var _seed = 5000;

  @override
  Future<List<SubmittedReport>> getSubmittedReports() async {
    await _delay();
    return List<SubmittedReport>.of(_reports)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<void> submitReport({
    required ReportTargetSummary target,
    required ReportReason reason,
    required String details,
    required String reportedBy,
  }) async {
    await _delay();
    final trimmedDetails = details.trim();
    if (reason == ReportReason.other && trimmedDetails.isEmpty) {
      throw const AppException(
        'Add a short explanation when submitting an "Other" report.',
      );
    }

    _reports.add(
      SubmittedReport(
        id: 'report_${_seed++}',
        target: target,
        reason: reason,
        details: trimmedDetails,
        reportedBy: reportedBy,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 120));
}
