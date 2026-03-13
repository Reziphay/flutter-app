import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
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
  (ref) => BackendReportsRepository(apiClient: ref.watch(apiClientProvider)),
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

class BackendReportsRepository implements ReportsRepository {
  BackendReportsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  final List<SubmittedReport> _submittedReports = [];

  @override
  Future<List<SubmittedReport>> getSubmittedReports() async {
    return List<SubmittedReport>.unmodifiable(_submittedReports);
  }

  @override
  Future<void> submitReport({
    required ReportTargetSummary target,
    required ReportReason reason,
    required String details,
    required String reportedBy,
  }) async {
    final trimmedDetails = details.trim();
    if (reason == ReportReason.other && trimmedDetails.isEmpty) {
      throw const AppException(
        'Add a short explanation when submitting an "Other" report.',
      );
    }

    final targetType = _backendTargetType(target.type);
    if (targetType == null) {
      throw const AppException(
        'This report target is not supported by the backend yet.',
        type: AppExceptionType.validation,
      );
    }

    final payload = await _apiClient.post<dynamic>(
      '/reports',
      data: {
        'targetType': targetType,
        'targetId': target.id,
        'reason': _buildReasonText(
          target: target,
          reason: reason,
          details: trimmedDetails,
        ),
      },
      mapper: (data) => data,
    );

    final report = payload is Map
        ? _extractEntity(asJsonMap(payload), ['report', 'item'])
        : const <String, dynamic>{};
    _submittedReports.insert(
      0,
      SubmittedReport(
        id:
            _readString(report, ['id']) ??
            'report_${DateTime.now().microsecondsSinceEpoch}',
        target: target,
        reason: reason,
        details: trimmedDetails,
        reportedBy: reportedBy,
        createdAt:
            _readDateTime(report, ['createdAt'])?.toLocal() ?? DateTime.now(),
      ),
    );
  }

  String? _backendTargetType(ReportTargetType type) {
    return switch (type) {
      ReportTargetType.service => 'SERVICE',
      ReportTargetType.provider => 'USER',
      ReportTargetType.brand => 'BRAND',
      ReportTargetType.reservation => null,
    };
  }

  String _buildReasonText({
    required ReportTargetSummary target,
    required ReportReason reason,
    required String details,
  }) {
    final buffer = StringBuffer(reason.label);
    if (details.isNotEmpty) {
      buffer.write(': $details');
    } else if (target.subtitle != null && target.subtitle!.trim().isNotEmpty) {
      buffer.write(': ${target.subtitle!.trim()}');
    }
    return buffer.toString();
  }

  JsonMap _extractEntity(JsonMap payload, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(payload, key);
      if (value is Map) {
        return asJsonMap(value);
      }
    }
    return payload;
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

  DateTime? _readDateTime(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is! String || value.trim().isEmpty) {
        continue;
      }
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
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
