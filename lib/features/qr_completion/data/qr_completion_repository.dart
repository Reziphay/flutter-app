import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/qr_completion/models/qr_completion_models.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

abstract class QrCompletionRepository {
  Future<ProviderQrSession> getProviderQr({
    required String providerId,
    required String providerName,
  });

  Future<ProviderQrSession> refreshProviderQr({
    required String providerId,
    required String providerName,
  });

  Future<QrCompletionResult> submitScannedPayload({
    required ReservationSummary reservation,
    required String payload,
  });
}

final qrCompletionRepositoryProvider = Provider<QrCompletionRepository>(
  (ref) => BackendQrCompletionRepository(
    apiClient: ref.watch(apiClientProvider),
    reservationsRepository: ref.watch(reservationsRepositoryProvider),
    readSession: () => ref.read(sessionControllerProvider).session,
  ),
);

final providerQrSessionProvider = FutureProvider.autoDispose<ProviderQrSession>(
  (ref) {
    final session = ref.watch(sessionControllerProvider).session;
    final String providerId =
        session?.user.id ?? ref.watch(activeProviderContextProvider);
    final String providerName = session?.user.fullName ?? 'Provider';

    return ref
        .watch(qrCompletionRepositoryProvider)
        .getProviderQr(providerId: providerId, providerName: providerName);
  },
);

class BackendQrCompletionRepository implements QrCompletionRepository {
  BackendQrCompletionRepository({
    required ApiClient apiClient,
    required ReservationsRepository reservationsRepository,
    required UserSession? Function() readSession,
  }) : _apiClient = apiClient,
       _reservationsRepository = reservationsRepository,
       _readSession = readSession;

  final ApiClient _apiClient;
  final ReservationsRepository _reservationsRepository;
  final UserSession? Function() _readSession;

  @override
  Future<ProviderQrSession> getProviderQr({
    required String providerId,
    required String providerName,
  }) {
    return _loadProviderQr(
      providerId: providerId,
      providerName: providerName,
      refresh: false,
    );
  }

  @override
  Future<ProviderQrSession> refreshProviderQr({
    required String providerId,
    required String providerName,
  }) {
    return _loadProviderQr(
      providerId: providerId,
      providerName: providerName,
      refresh: true,
    );
  }

  @override
  Future<QrCompletionResult> submitScannedPayload({
    required ReservationSummary reservation,
    required String payload,
  }) async {
    final signedPayload = payload.trim();
    if (signedPayload.isEmpty) {
      throw const AppException(
        'Paste or scan the signed QR payload before submitting.',
        type: AppExceptionType.validation,
      );
    }

    try {
      await _reservationsRepository.completeReservationViaQr(
        reservation.id,
        payload: signedPayload,
      );

      return QrCompletionResult(
        status: QrCompletionStatus.success,
        reservationId: reservation.id,
        providerId: reservation.providerId,
        providerName: reservation.providerName,
      );
    } on AppException catch (error) {
      final status = _mapQrFailure(error);
      if (status == null) {
        rethrow;
      }

      return QrCompletionResult(
        status: status,
        reservationId: reservation.id,
        providerId: reservation.providerId,
        providerName: reservation.providerName,
      );
    }
  }

  Future<ProviderQrSession> _loadProviderQr({
    required String providerId,
    required String providerName,
    required bool refresh,
  }) async {
    final userId = _readSession()?.user.id ?? providerId;
    final requestedName = _readSession()?.user.fullName ?? providerName;
    final errors = <AppException>[];

    Future<ProviderQrSession> attempt(
      Future<dynamic> Function(String path) request,
      String path,
    ) async {
      final payload = await request(path);
      return _parseProviderQrSession(
        payload,
        fallbackProviderId: userId,
        fallbackProviderName: requestedName,
      );
    }

    final endpoints = refresh
        ? const [
            _ProviderQrEndpoint(
              path: '/reservations/provider-qr',
              usePost: true,
            ),
            _ProviderQrEndpoint(
              path: '/reservations/qr-session',
              usePost: true,
            ),
            _ProviderQrEndpoint(path: '/users/me/provider-qr', usePost: true),
            _ProviderQrEndpoint(path: '/users/me/qr-session', usePost: true),
          ]
        : const [
            _ProviderQrEndpoint(
              path: '/reservations/provider-qr',
              usePost: false,
            ),
            _ProviderQrEndpoint(path: '/qr/provider-session', usePost: false),
            _ProviderQrEndpoint(path: '/users/me/provider-qr', usePost: false),
            _ProviderQrEndpoint(path: '/users/me/qr-session', usePost: false),
            _ProviderQrEndpoint(
              path: '/reservations/provider-qr',
              usePost: true,
            ),
            _ProviderQrEndpoint(
              path: '/reservations/qr-session',
              usePost: true,
            ),
            _ProviderQrEndpoint(path: '/users/me/provider-qr', usePost: true),
            _ProviderQrEndpoint(path: '/users/me/qr-session', usePost: true),
          ];

    for (final endpoint in endpoints) {
      try {
        if (endpoint.usePost) {
          return await attempt(
            (endpoint) => _apiClient.post<dynamic>(
              endpoint,
              data: {
                'providerId': userId,
                'providerName': requestedName,
                'refresh': refresh,
              },
              mapper: (data) => data,
            ),
            endpoint.path,
          );
        }

        return await attempt(
          (endpoint) => _apiClient.get<dynamic>(
            endpoint,
            queryParameters: {
              'providerId': userId,
              'providerName': requestedName,
            },
            mapper: (data) => data,
          ),
          endpoint.path,
        );
      } on AppException catch (error) {
        if (_shouldTryNextProviderQrEndpoint(error)) {
          errors.add(error);
          continue;
        }
        rethrow;
      }
    }

    final lastError = errors.isEmpty ? null : errors.last;
    throw AppException(
      lastError?.statusCode == 404
          ? 'The backend has not exposed a provider QR session endpoint yet.'
          : 'Provider QR is unavailable right now.',
      type: AppExceptionType.server,
      statusCode: lastError?.statusCode,
      code: lastError?.code,
      details: lastError?.details,
      requestId: lastError?.requestId,
    );
  }

  ProviderQrSession _parseProviderQrSession(
    dynamic payload, {
    required String fallbackProviderId,
    required String fallbackProviderName,
  }) {
    final entity = _extractEntity(payload, ['session', 'qrSession', 'item']);
    final provider =
        _readMap(entity, ['provider', 'serviceOwner', 'owner', 'user']) ??
        const <String, dynamic>{};
    final providerId =
        _readString(provider, ['id']) ??
        _readString(entity, ['providerId', 'ownerId']) ??
        fallbackProviderId;
    final providerName =
        _readString(provider, ['fullName', 'name']) ??
        _readString(entity, ['providerName', 'ownerName']) ??
        fallbackProviderName;
    final payloadValue = _readString(entity, [
      'signedPayload',
      'payload',
      'qrPayload',
      'token',
    ]);
    final generatedAt =
        _readDateTime(entity, ['generatedAt', 'issuedAt', 'createdAt']) ??
        DateTime.now();
    final expiresAt = _readDateTime(entity, ['expiresAt', 'validUntil']);

    if (payloadValue == null || expiresAt == null) {
      throw const AppException(
        'The backend returned an incomplete provider QR session.',
        type: AppExceptionType.server,
      );
    }

    return ProviderQrSession(
      providerId: providerId,
      providerName: providerName,
      payload: payloadValue,
      generatedAt: generatedAt,
      expiresAt: expiresAt,
    );
  }

  QrCompletionStatus? _mapQrFailure(AppException error) {
    final normalizedCode = error.code?.trim().toUpperCase();
    final normalizedMessage = error.message.trim().toUpperCase();

    if (normalizedCode != null) {
      if (normalizedCode.contains('INVALID')) {
        return QrCompletionStatus.invalid;
      }
      if (normalizedCode.contains('EXPIRED')) {
        return QrCompletionStatus.expired;
      }
      if (normalizedCode.contains('WRONG_PROVIDER') ||
          normalizedCode.contains('PROVIDER_MISMATCH')) {
        return QrCompletionStatus.wrongProvider;
      }
      if (normalizedCode.contains('ALREADY_COMPLETED')) {
        return QrCompletionStatus.alreadyCompleted;
      }
      if (normalizedCode.contains('MANUAL_FALLBACK') ||
          normalizedCode.contains('NOT_CONFIRMABLE')) {
        return QrCompletionStatus.manualFallback;
      }
    }

    if (normalizedMessage.contains('INVALID')) {
      return QrCompletionStatus.invalid;
    }
    if (normalizedMessage.contains('EXPIRED')) {
      return QrCompletionStatus.expired;
    }
    if (normalizedMessage.contains('WRONG PROVIDER') ||
        normalizedMessage.contains('PROVIDER MISMATCH')) {
      return QrCompletionStatus.wrongProvider;
    }
    if (normalizedMessage.contains('ALREADY COMPLETED')) {
      return QrCompletionStatus.alreadyCompleted;
    }
    if (normalizedMessage.contains('MANUAL COMPLETION') ||
        normalizedMessage.contains('CURRENT RESERVATION STATE')) {
      return QrCompletionStatus.manualFallback;
    }

    return null;
  }

  bool _shouldTryNextProviderQrEndpoint(AppException error) {
    return switch (error.statusCode) {
      404 || 405 || 501 => true,
      _ => false,
    };
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
      'Unexpected QR payload returned by the server.',
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

class _ProviderQrEndpoint {
  const _ProviderQrEndpoint({required this.path, required this.usePost});

  final String path;
  final bool usePost;
}

