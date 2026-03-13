import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/reviews/models/review_models.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';

abstract class ReviewsRepository {
  Future<AppReview?> getReservationReview(String reservationId);

  Future<List<AppReview>> getEntityReviews({
    required ReviewTargetType type,
    required String entityId,
  });

  Future<void> createReservationReview({
    required ReservationSummary reservation,
    required String authorName,
    required double rating,
    required String comment,
  });

  Future<void> deleteReview(String reviewId);

  Future<void> replyToReview({
    required String reviewId,
    required String authorName,
    required String message,
  });

  Future<void> reportReview({required String reviewId, required String reason});
}

class ReviewEntityKey {
  const ReviewEntityKey({required this.type, required this.entityId});

  final ReviewTargetType type;
  final String entityId;

  @override
  bool operator ==(Object other) {
    return other is ReviewEntityKey &&
        other.type == type &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(type, entityId);
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => BackendReviewsRepository(apiClient: ref.watch(apiClientProvider)),
);

final reservationReviewProvider = FutureProvider.autoDispose
    .family<AppReview?, String>(
      (ref, reservationId) => ref
          .watch(reviewsRepositoryProvider)
          .getReservationReview(reservationId),
    );

final entityReviewsProvider = FutureProvider.autoDispose
    .family<List<AppReview>, ReviewEntityKey>(
      (ref, key) => ref
          .watch(reviewsRepositoryProvider)
          .getEntityReviews(type: key.type, entityId: key.entityId),
    );

final reviewsActionsProvider = Provider<ReviewsActions>(
  (ref) => ReviewsActions(ref),
);

class ReviewsActions {
  ReviewsActions(this.ref);

  final Ref ref;

  Future<void> createReservationReview({
    required ReservationSummary reservation,
    required double rating,
    required String comment,
  }) async {
    final session = ref.read(sessionControllerProvider).session;
    await ref
        .read(reviewsRepositoryProvider)
        .createReservationReview(
          reservation: reservation,
          authorName: session?.user.fullName ?? 'Reziphay User',
          rating: rating,
          comment: comment,
        );
    _invalidateTargets(reservation);
  }

  Future<void> deleteReview(AppReview review) async {
    await ref.read(reviewsRepositoryProvider).deleteReview(review.id);
    _invalidateReview(review);
  }

  Future<void> replyToReview({
    required AppReview review,
    required String message,
  }) async {
    final session = ref.read(sessionControllerProvider).session;
    await ref
        .read(reviewsRepositoryProvider)
        .replyToReview(
          reviewId: review.id,
          authorName: session?.user.fullName ?? 'Provider',
          message: message,
        );
    _invalidateReview(review);
  }

  Future<void> reportReview({
    required AppReview review,
    required String reason,
  }) async {
    await ref
        .read(reviewsRepositoryProvider)
        .reportReview(reviewId: review.id, reason: reason);
  }

  void _invalidateTargets(ReservationSummary reservation) {
    ref.invalidate(reservationReviewProvider(reservation.id));
    ref.invalidate(
      entityReviewsProvider(
        ReviewEntityKey(
          type: ReviewTargetType.service,
          entityId: reservation.serviceId,
        ),
      ),
    );
    ref.invalidate(
      entityReviewsProvider(
        ReviewEntityKey(
          type: ReviewTargetType.provider,
          entityId: reservation.providerId,
        ),
      ),
    );
    if (reservation.brandId != null) {
      ref.invalidate(
        entityReviewsProvider(
          ReviewEntityKey(
            type: ReviewTargetType.brand,
            entityId: reservation.brandId!,
          ),
        ),
      );
    }
  }

  void _invalidateReview(AppReview review) {
    ref.invalidate(reservationReviewProvider(review.reservationId));
    for (final target in review.targets) {
      ref.invalidate(
        entityReviewsProvider(
          ReviewEntityKey(type: target.type, entityId: target.id),
        ),
      );
    }
  }
}

class BackendReviewsRepository implements ReviewsRepository {
  BackendReviewsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  final Map<String, AppReview> _shadowReviewsById = {};
  final Set<String> _deletedReviewIds = <String>{};

  @override
  Future<void> createReservationReview({
    required ReservationSummary reservation,
    required String authorName,
    required double rating,
    required String comment,
  }) async {
    if (reservation.effectiveStatus != ReservationStatus.completed) {
      throw const AppException('Only completed reservations can be reviewed.');
    }

    final trimmedComment = comment.trim();
    if (trimmedComment.isEmpty) {
      throw const AppException(
        'Write a short review comment before submitting.',
      );
    }

    final payload = await _apiClient.post<dynamic>(
      '/reviews',
      data: {
        'reservationId': reservation.id,
        'rating': rating,
        'comment': trimmedComment,
        'targets': _buildTargets(reservation),
      },
      mapper: (data) => data,
    );

    final createdReview =
        _parseReview(
          payload,
          fallbackReservation: reservation,
          fallbackAuthorName: authorName,
          fallbackRating: rating,
          fallbackComment: trimmedComment,
        ) ??
        await _loadReservationReviewRemote(reservation.id) ??
        _buildLocalReview(
          reservation: reservation,
          authorName: authorName,
          rating: rating,
          comment: trimmedComment,
        );

    _upsertReview(createdReview);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _apiClient.delete<void>('/reviews/$reviewId', mapper: (_) {});
    _deletedReviewIds.add(reviewId);
    _shadowReviewsById.remove(reviewId);
  }

  @override
  Future<List<AppReview>> getEntityReviews({
    required ReviewTargetType type,
    required String entityId,
  }) async {
    final remoteReviews = await _loadEntityReviewsRemote(
      type: type,
      entityId: entityId,
    );
    final localReviews = _shadowReviewsById.values.where(
      (review) => review.targets.any(
        (target) => target.type == type && target.id == entityId,
      ),
    );

    return _mergeReviews([...remoteReviews, ...localReviews]);
  }

  @override
  Future<AppReview?> getReservationReview(String reservationId) async {
    final localReview = _findLocalReservationReview(reservationId);
    final remoteReview = await _loadReservationReviewRemote(reservationId);
    final merged = _mergeReviews([remoteReview, localReview].nonNulls);

    return merged.isEmpty ? null : merged.first;
  }

  @override
  Future<void> replyToReview({
    required String reviewId,
    required String authorName,
    required String message,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw const AppException('Write a short reply before submitting.');
    }

    final payload = await _apiClient.post<dynamic>(
      '/reviews/$reviewId/replies',
      data: {'message': trimmedMessage},
      mapper: (data) => data,
    );

    final currentReview = _shadowReviewsById[reviewId];
    final parsedReview =
        _parseReview(payload) ??
        (currentReview == null
            ? null
            : AppReview(
                id: currentReview.id,
                reservationId: currentReview.reservationId,
                authorName: currentReview.authorName,
                rating: currentReview.rating,
                comment: currentReview.comment,
                createdAt: currentReview.createdAt,
                targets: currentReview.targets,
                reply:
                    _parseReply(payload) ??
                    ReviewReply(
                      authorName: authorName,
                      message: trimmedMessage,
                      createdAt: DateTime.now(),
                    ),
              ));

    if (parsedReview != null) {
      _upsertReview(parsedReview);
    }
  }

  @override
  Future<void> reportReview({
    required String reviewId,
    required String reason,
  }) {
    return _apiClient.post<void>(
      '/reviews/$reviewId/report',
      data: {'reason': reason.trim()},
      mapper: (_) {},
    );
  }

  Future<List<AppReview>> _loadEntityReviewsRemote({
    required ReviewTargetType type,
    required String entityId,
  }) async {
    try {
      final payload = await _apiClient.get<dynamic>(
        '/reviews',
        queryParameters: {
          'targetType': type.backendValue,
          'entityType': type.backendValue,
          'targetId': entityId,
          'entityId': entityId,
        },
        mapper: (data) => data,
      );

      return _parseReviewList(payload);
    } on AppException catch (error) {
      if (_canFallbackForReviewsList(error)) {
        return const [];
      }
      rethrow;
    }
  }

  Future<AppReview?> _loadReservationReviewRemote(String reservationId) async {
    final localReview = _findLocalReservationReview(reservationId);

    try {
      final reservationPayload = await _apiClient.get<dynamic>(
        '/reservations/$reservationId',
        mapper: (data) => data,
      );
      final reservationReview = _parseReviewFromReservationPayload(
        reservationPayload,
      );
      if (reservationReview != null) {
        return _mergeReviews([reservationReview, localReview].nonNulls).first;
      }
    } on AppException {
      rethrow;
    }

    try {
      final reviewsPayload = await _apiClient.get<dynamic>(
        '/reviews',
        queryParameters: {'reservationId': reservationId},
        mapper: (data) => data,
      );
      final remoteReview = _parseReviewList(reviewsPayload).firstOrNull;
      final merged = _mergeReviews([remoteReview, localReview].nonNulls);
      return merged.isEmpty ? null : merged.first;
    } on AppException catch (error) {
      if (_canFallbackForReviewsList(error)) {
        return localReview;
      }
      rethrow;
    }
  }

  AppReview? _parseReviewFromReservationPayload(dynamic payload) {
    if (payload is! Map) {
      return null;
    }

    final entity = _extractEntity(payload, ['reservation', 'item']);
    final review =
        _readMap(entity, ['review', 'latestReview']) ??
        _firstMap(entity, ['reviews', 'reviews.items']);
    if (review == null) {
      return null;
    }

    final summary = _parseReservationReviewSummary(entity);
    return _parseReview(review, fallbackReservation: summary);
  }

  ReservationSummary _parseReservationReviewSummary(JsonMap item) {
    final service = _readMap(item, ['service']) ?? <String, dynamic>{};
    final brand = _readMap(service, ['brand']) ?? <String, dynamic>{};
    final provider =
        _readMap(service, ['owner', 'provider']) ?? <String, dynamic>{};
    final customer =
        _readMap(item, ['customer', 'customerUser']) ?? <String, dynamic>{};

    return ReservationSummary(
      id: _readString(item, ['id']) ?? '',
      serviceId:
          _readString(service, ['id']) ??
          _readString(item, ['serviceId']) ??
          '',
      serviceName:
          _readString(service, ['name', 'title']) ??
          _readString(item, ['serviceName']) ??
          'Service',
      providerId:
          _readString(provider, ['id']) ??
          _readString(item, ['providerId']) ??
          '',
      providerName:
          _readString(provider, ['fullName', 'name']) ??
          _readString(item, ['providerName']) ??
          'Provider',
      customerName:
          _readString(customer, ['fullName', 'name']) ??
          _readString(item, ['customerName']) ??
          'Customer',
      addressLine:
          _readString(service, ['addressLine', 'address.addressLine']) ??
          _readString(item, ['addressLine']) ??
          'Address not specified',
      scheduledAt:
          _readDateTime(item, ['requestedStartAt', 'scheduledAt']) ??
          DateTime.now(),
      createdAt:
          _readDateTime(item, ['createdAt', 'requestedAt']) ?? DateTime.now(),
      status: ReservationStatusX.parse(_readString(item, ['status'])),
      approvalMode: ApprovalMode.manual,
      priceLabel: 'Price on request',
      brandId: _readString(brand, ['id']) ?? _readString(item, ['brandId']),
      brandName:
          _readString(brand, ['name']) ?? _readString(item, ['brandName']),
      note: _readString(item, ['note', 'notes']),
      responseDeadline: _readDateTime(item, ['approvalExpiresAt']),
    );
  }

  List<Map<String, dynamic>> _buildTargets(ReservationSummary reservation) {
    return [
      {
        'type': ReviewTargetType.service.backendValue,
        'id': reservation.serviceId,
      },
      {
        'type': ReviewTargetType.provider.backendValue,
        'id': reservation.providerId,
      },
      if (reservation.brandId != null)
        {
          'type': ReviewTargetType.brand.backendValue,
          'id': reservation.brandId,
        },
    ];
  }

  AppReview _buildLocalReview({
    required ReservationSummary reservation,
    required String authorName,
    required double rating,
    required String comment,
  }) {
    return AppReview(
      id: 'local_${reservation.id}',
      reservationId: reservation.id,
      authorName: authorName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      targets: _targetsFromReservation(reservation),
    );
  }

  AppReview? _findLocalReservationReview(String reservationId) {
    for (final review in _shadowReviewsById.values) {
      if (review.reservationId == reservationId &&
          !_deletedReviewIds.contains(review.id)) {
        return review;
      }
    }
    return null;
  }

  void _upsertReview(AppReview review) {
    _deletedReviewIds.remove(review.id);
    _shadowReviewsById[review.id] = review;
  }

  List<AppReview> _mergeReviews(Iterable<AppReview> reviews) {
    final byId = <String, AppReview>{};
    for (final review in reviews) {
      if (_deletedReviewIds.contains(review.id)) {
        continue;
      }
      byId[review.id] = review;
    }

    final merged = byId.values.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return merged;
  }

  List<AppReview> _parseReviewList(dynamic payload) {
    final items = _extractItems(payload, ['items', 'reviews']);
    return items
        .map((item) => _parseReview(item))
        .whereType<AppReview>()
        .toList(growable: false);
  }

  AppReview? _parseReview(
    dynamic payload, {
    ReservationSummary? fallbackReservation,
    String? fallbackAuthorName,
    double? fallbackRating,
    String? fallbackComment,
  }) {
    if (payload is! Map) {
      return null;
    }

    final entity = _extractEntity(payload, ['review', 'item']);
    final id =
        _readString(entity, ['id']) ??
        'local_${DateTime.now().microsecondsSinceEpoch}';
    final reservationId =
        _readString(entity, ['reservationId', 'reservation.id']) ??
        fallbackReservation?.id ??
        '';
    if (reservationId.isEmpty) {
      return null;
    }

    final targets =
        _parseTargets(entity) ??
        (fallbackReservation == null
            ? const <ReviewTarget>[]
            : _targetsFromReservation(fallbackReservation));

    return AppReview(
      id: id,
      reservationId: reservationId,
      authorName:
          _readString(entity, [
            'author.fullName',
            'authorName',
            'user.fullName',
          ]) ??
          fallbackAuthorName ??
          'Reziphay User',
      rating: _readDouble(entity, ['rating', 'stars']) ?? fallbackRating ?? 5,
      comment:
          _readString(entity, ['comment', 'message', 'body']) ??
          fallbackComment ??
          '',
      createdAt:
          _readDateTime(entity, ['createdAt', 'submittedAt']) ?? DateTime.now(),
      targets: targets,
      reply: _parseReply(entity),
    );
  }

  List<ReviewTarget>? _parseTargets(JsonMap entity) {
    final rawTargets = _readList(entity, ['targets']);
    if (rawTargets == null || rawTargets.isEmpty) {
      return null;
    }

    final targets = <ReviewTarget>[];
    for (final rawTarget in rawTargets) {
      if (rawTarget is! Map) {
        continue;
      }
      final target = asJsonMap(rawTarget);
      final type = ReviewTargetTypeX.parse(
        _readString(target, ['type', 'entityType']),
      );
      final id = _readString(target, ['id', 'entityId']);
      if (type == null || id == null) {
        continue;
      }
      targets.add(
        ReviewTarget(
          type: type,
          id: id,
          name: _readString(target, ['name', 'entityName']) ?? type.label,
        ),
      );
    }

    return targets.isEmpty ? null : targets;
  }

  ReviewReply? _parseReply(dynamic payload) {
    if (payload is! Map) {
      return null;
    }

    final entity = asJsonMap(payload);
    final reply =
        _readMap(entity, ['reply', 'latestReply']) ??
        _firstMap(entity, ['replies', 'responses']);
    if (reply == null) {
      return null;
    }

    final createdAt = _readDateTime(reply, ['createdAt', 'submittedAt']);
    if (createdAt == null) {
      return null;
    }

    return ReviewReply(
      authorName:
          _readString(reply, [
            'author.fullName',
            'authorName',
            'user.fullName',
          ]) ??
          'Provider',
      message:
          _readString(reply, ['message', 'comment', 'body']) ??
          'Provider replied.',
      createdAt: createdAt,
    );
  }

  List<ReviewTarget> _targetsFromReservation(ReservationSummary reservation) {
    return [
      ReviewTarget(
        type: ReviewTargetType.service,
        id: reservation.serviceId,
        name: reservation.serviceName,
      ),
      ReviewTarget(
        type: ReviewTargetType.provider,
        id: reservation.providerId,
        name: reservation.providerName,
      ),
      if (reservation.brandId != null && reservation.brandName != null)
        ReviewTarget(
          type: ReviewTargetType.brand,
          id: reservation.brandId!,
          name: reservation.brandName!,
        ),
    ];
  }

  bool _canFallbackForReviewsList(AppException error) {
    return switch (error.statusCode) {
      404 || 405 || 501 => true,
      _ => false,
    };
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
    return <String, dynamic>{};
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

  JsonMap? _firstMap(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is List && value.isNotEmpty && value.first is Map) {
        return asJsonMap(value.first);
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

class MockReviewsRepository implements ReviewsRepository {
  final List<AppReview> _reviews = [
    AppReview(
      id: 'rev_seed_completed',
      reservationId: 'r_1009',
      authorName: 'Nigar Safarli',
      rating: 4.8,
      comment:
          'Fast finish, clear communication, and the QR completion flow felt reliable.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      targets: const [
        ReviewTarget(
          type: ReviewTargetType.service,
          id: 'classic-haircut',
          name: 'Classic haircut',
        ),
        ReviewTarget(
          type: ReviewTargetType.provider,
          id: 'rauf-mammadov',
          name: 'Rauf Mammadov',
        ),
        ReviewTarget(
          type: ReviewTargetType.brand,
          id: 'studio-north',
          name: 'Studio North',
        ),
      ],
    ),
  ];

  final Map<String, String> _reports = {};
  var _seed = 3000;

  @override
  Future<void> createReservationReview({
    required ReservationSummary reservation,
    required String authorName,
    required double rating,
    required String comment,
  }) async {
    await _delay();

    if (reservation.effectiveStatus != ReservationStatus.completed) {
      throw const AppException('Only completed reservations can be reviewed.');
    }

    if (_reviews.any((review) => review.reservationId == reservation.id)) {
      throw const AppException('This reservation already has a review.');
    }

    final trimmedComment = comment.trim();
    if (trimmedComment.isEmpty) {
      throw const AppException(
        'Write a short review comment before submitting.',
      );
    }

    _reviews.add(
      AppReview(
        id: 'rev_${_seed++}',
        reservationId: reservation.id,
        authorName: authorName,
        rating: rating,
        comment: trimmedComment,
        createdAt: DateTime.now(),
        targets: [
          ReviewTarget(
            type: ReviewTargetType.service,
            id: reservation.serviceId,
            name: reservation.serviceName,
          ),
          ReviewTarget(
            type: ReviewTargetType.provider,
            id: reservation.providerId,
            name: reservation.providerName,
          ),
          if (reservation.brandId != null && reservation.brandName != null)
            ReviewTarget(
              type: ReviewTargetType.brand,
              id: reservation.brandId!,
              name: reservation.brandName!,
            ),
        ],
      ),
    );
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _delay();
    _reviews.removeWhere((review) => review.id == reviewId);
  }

  @override
  Future<List<AppReview>> getEntityReviews({
    required ReviewTargetType type,
    required String entityId,
  }) async {
    await _delay();
    return _reviews
        .where(
          (review) => review.targets.any(
            (target) => target.type == type && target.id == entityId,
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<AppReview?> getReservationReview(String reservationId) async {
    await _delay();
    for (final review in _reviews) {
      if (review.reservationId == reservationId) {
        return review;
      }
    }
    return null;
  }

  @override
  Future<void> replyToReview({
    required String reviewId,
    required String authorName,
    required String message,
  }) async {
    await _delay();
    final index = _reviews.indexWhere((review) => review.id == reviewId);
    if (index < 0) {
      throw const AppException('Review not found.');
    }

    final review = _reviews[index];
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw const AppException('Write a short reply before submitting.');
    }

    _reviews[index] = AppReview(
      id: review.id,
      reservationId: review.reservationId,
      authorName: review.authorName,
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt,
      targets: review.targets,
      reply: ReviewReply(
        authorName: authorName,
        message: trimmedMessage,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> reportReview({
    required String reviewId,
    required String reason,
  }) async {
    await _delay();
    _reports[reviewId] = reason.trim().isEmpty ? 'Reported' : reason.trim();
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 140));
}
