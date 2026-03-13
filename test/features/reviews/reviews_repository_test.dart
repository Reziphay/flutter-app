import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/reviews/data/reviews_repository.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';

void main() {
  group('MockReviewsRepository', () {
    late MockReservationsRepository reservationsRepository;
    late MockReviewsRepository reviewsRepository;

    setUp(() {
      reservationsRepository = MockReservationsRepository(
        discoveryRepository: MockDiscoveryRepository(),
      );
      reviewsRepository = MockReviewsRepository();
    });

    test('reviews can only be created for completed reservations', () async {
      final reservationId = await reservationsRepository.createReservation(
        serviceId: 'classic-haircut',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        note: '',
        customerId: 'current-user',
        customerName: 'Test Customer',
      );
      await reservationsRepository.acceptProviderReservation(reservationId);

      final confirmedSummary =
          (await reservationsRepository.getCustomerReservationDetail(
            reservationId,
            'current-user',
          )).summary;

      await expectLater(
        reviewsRepository.createReservationReview(
          reservation: confirmedSummary,
          authorName: 'Test Customer',
          rating: 5,
          comment: 'Trying to review too early.',
        ),
        throwsA(isA<AppException>()),
      );

      await reservationsRepository.completeProviderReservation(reservationId);

      final completedSummary =
          (await reservationsRepository.getCustomerReservationDetail(
            reservationId,
            'current-user',
          )).summary;

      await reviewsRepository.createReservationReview(
        reservation: completedSummary,
        authorName: 'Test Customer',
        rating: 4.5,
        comment: 'Reliable service and clear communication.',
      );

      final review = await reviewsRepository.getReservationReview(
        reservationId,
      );

      expect(review, isNotNull);
      expect(review!.comment, 'Reliable service and clear communication.');
    });

    test('deleteReview removes a saved reservation review', () async {
      final reservationId = await reservationsRepository.createReservation(
        serviceId: 'classic-haircut',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        note: '',
        customerId: 'current-user',
        customerName: 'Test Customer',
      );
      await reservationsRepository.acceptProviderReservation(reservationId);
      await reservationsRepository.completeProviderReservation(reservationId);

      final summary =
          (await reservationsRepository.getCustomerReservationDetail(
            reservationId,
            'current-user',
          )).summary;

      await reviewsRepository.createReservationReview(
        reservation: summary,
        authorName: 'Test Customer',
        rating: 4,
        comment: 'Will remove this review.',
      );

      final review = await reviewsRepository.getReservationReview(
        reservationId,
      );
      await reviewsRepository.deleteReview(review!.id);

      expect(
        await reviewsRepository.getReservationReview(reservationId),
        isNull,
      );
    });

    test('replyToReview attaches a provider reply', () async {
      final review = await reviewsRepository.getReservationReview('r_1009');

      expect(review, isNotNull);

      await reviewsRepository.replyToReview(
        reviewId: review!.id,
        authorName: 'Rauf Mammadov',
        message: 'Thanks for the detailed feedback.',
      );

      final updated = await reviewsRepository.getReservationReview('r_1009');

      expect(updated!.reply, isNotNull);
      expect(updated.reply!.message, 'Thanks for the detailed feedback.');
    });
  });
}
