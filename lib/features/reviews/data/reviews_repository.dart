import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
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
  (ref) => MockReviewsRepository(),
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
