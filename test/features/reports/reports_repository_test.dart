import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/reports/data/reports_repository.dart';
import 'package:reziphay_mobile/features/reports/models/report_models.dart';

void main() {
  group('MockReportsRepository', () {
    test('submitReport stores a service report entry', () async {
      final repository = MockReportsRepository();

      await repository.submitReport(
        target: const ReportTargetSummary(
          type: ReportTargetType.service,
          id: 'classic-haircut',
          title: 'Classic haircut',
        ),
        reason: ReportReason.misleadingInfo,
        details: 'Photos suggest a different service setup than the listing.',
        reportedBy: 'Test Reporter',
      );

      final reports = await repository.getSubmittedReports();

      expect(reports, hasLength(1));
      expect(reports.first.target.type, ReportTargetType.service);
      expect(reports.first.reason, ReportReason.misleadingInfo);
    });

    test('other reports require a short explanation', () async {
      final repository = MockReportsRepository();

      expect(
        () => repository.submitReport(
          target: const ReportTargetSummary(
            type: ReportTargetType.provider,
            id: 'rauf-mammadov',
            title: 'Rauf Mammadov',
          ),
          reason: ReportReason.other,
          details: '',
          reportedBy: 'Test Reporter',
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
