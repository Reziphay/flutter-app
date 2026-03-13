import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/reports/data/reports_repository.dart';
import 'package:reziphay_mobile/features/reports/models/report_models.dart';

void main() {
  group('BackendReportsRepository', () {
    test(
      'submitReport posts backend target mapping and stores the result',
      () async {
        Object? capturedData;
        final repository = BackendReportsRepository(
          apiClient: _FakeReportsApiClient(
            onPost: ({required path, data, queryParameters}) {
              capturedData = data;
              expect(path, '/reports');
              return {
                'report': {
                  'id': 'report_1',
                  'createdAt': '2026-03-13T10:00:00.000Z',
                },
              };
            },
          ),
        );

        await repository.submitReport(
          target: const ReportTargetSummary(
            type: ReportTargetType.provider,
            id: '550e8400-e29b-41d4-a716-446655440010',
            title: 'Rauf Mammadov',
            subtitle: 'Studio North',
          ),
          reason: ReportReason.abusiveBehavior,
          details: 'The conversation became inappropriate.',
          reportedBy: 'Test Reporter',
        );

        final reports = await repository.getSubmittedReports();

        expect(capturedData, {
          'targetType': 'USER',
          'targetId': '550e8400-e29b-41d4-a716-446655440010',
          'reason': 'Abusive behavior: The conversation became inappropriate.',
        });
        expect(reports, hasLength(1));
        expect(reports.single.id, 'report_1');
        expect(reports.single.target.type, ReportTargetType.provider);
      },
    );

    test('other reports require a short explanation', () async {
      final repository = BackendReportsRepository(
        apiClient: _FakeReportsApiClient(),
      );

      expect(
        () => repository.submitReport(
          target: const ReportTargetSummary(
            type: ReportTargetType.service,
            id: '550e8400-e29b-41d4-a716-446655440011',
            title: 'Classic haircut',
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

class _FakeReportsApiClient extends ApiClient {
  _FakeReportsApiClient({this.onPost}) : super(Dio());

  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPost;

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(
      onPost?.call(path: path, data: data, queryParameters: queryParameters) ??
          <String, dynamic>{},
    );
  }
}
