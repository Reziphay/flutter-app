import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/reviews/data/reviews_repository.dart';
import 'package:reziphay_mobile/features/reviews/models/review_models.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import '../../helpers/mock_discovery_repository.dart';
import '../../helpers/mock_reservations_repository.dart';
import '../../helpers/mock_reviews_repository.dart';

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

  group('BackendReviewsRepository', () {
    test(
      'createReservationReview sends backend payload and keeps the review visible locally',
      () async {
        Object? capturedBody;
        final repository = BackendReviewsRepository(
          apiClient: _FakeReviewsApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/reservations/res_completed') {
                return {
                  'reservation': {'id': 'res_completed', 'status': 'COMPLETED'},
                };
              }
              if (path == '/reviews') {
                throw const AppException(
                  'Not found',
                  type: AppExceptionType.unknown,
                  statusCode: 404,
                );
              }
              throw StateError('Unexpected GET path $path');
            },
            onPost: ({required path, data, queryParameters}) {
              if (path == '/reviews') {
                capturedBody = data;
                return {
                  'review': {
                    'id': 'rev_backend',
                    'reservationId': 'res_completed',
                    'authorName': 'Test Customer',
                    'rating': 4.5,
                    'comment': 'Reliable service and clear communication.',
                    'createdAt': '2026-03-13T09:00:00.000Z',
                    'targets': [
                      {
                        'type': 'SERVICE',
                        'id': 'classic-haircut',
                        'name': 'Classic haircut',
                      },
                      {
                        'type': 'PROVIDER',
                        'id': 'rauf-mammadov',
                        'name': 'Rauf Mammadov',
                      },
                      {
                        'type': 'BRAND',
                        'id': 'studio-north',
                        'name': 'Studio North',
                      },
                    ],
                  },
                };
              }
              throw StateError('Unexpected POST path $path');
            },
          ),
        );

        await repository.createReservationReview(
          reservation: _buildCompletedReservationSummary(),
          authorName: 'Test Customer',
          rating: 4.5,
          comment: 'Reliable service and clear communication.',
        );

        final review = await repository.getReservationReview('res_completed');

        expect(capturedBody, isA<Map<String, dynamic>>());
        expect(
          (capturedBody as Map<String, dynamic>)['reservationId'],
          'res_completed',
        );
        expect(review, isNotNull);
        expect(review!.comment, 'Reliable service and clear communication.');
      },
    );

    test('deleteReview removes a locally cached backend review', () async {
      final repository = BackendReviewsRepository(
        apiClient: _FakeReviewsApiClient(
          onGet: ({required path, queryParameters}) {
            if (path == '/reservations/res_completed') {
              return {
                'reservation': {'id': 'res_completed', 'status': 'COMPLETED'},
              };
            }
            if (path == '/reviews') {
              throw const AppException(
                'Not found',
                type: AppExceptionType.unknown,
                statusCode: 404,
              );
            }
            throw StateError('Unexpected GET path $path');
          },
          onPost: ({required path, data, queryParameters}) {
            if (path == '/reviews') {
              return {
                'review': {
                  'id': 'rev_backend',
                  'reservationId': 'res_completed',
                  'authorName': 'Test Customer',
                  'rating': 4,
                  'comment': 'Will remove this review.',
                  'createdAt': '2026-03-13T09:00:00.000Z',
                },
              };
            }
            throw StateError('Unexpected POST path $path');
          },
        ),
      );

      await repository.createReservationReview(
        reservation: _buildCompletedReservationSummary(),
        authorName: 'Test Customer',
        rating: 4,
        comment: 'Will remove this review.',
      );

      await repository.deleteReview('rev_backend');

      expect(await repository.getReservationReview('res_completed'), isNull);
    });

    test(
      'replyToReview stores the backend reply on the cached review',
      () async {
        final repository = BackendReviewsRepository(
          apiClient: _FakeReviewsApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/reservations/res_completed') {
                return {
                  'reservation': {'id': 'res_completed', 'status': 'COMPLETED'},
                };
              }
              if (path == '/reviews') {
                throw const AppException(
                  'Not found',
                  type: AppExceptionType.unknown,
                  statusCode: 404,
                );
              }
              throw StateError('Unexpected GET path $path');
            },
            onPost: ({required path, data, queryParameters}) {
              if (path == '/reviews') {
                return {
                  'review': {
                    'id': 'rev_backend',
                    'reservationId': 'res_completed',
                    'authorName': 'Test Customer',
                    'rating': 4.8,
                    'comment': 'Strong experience.',
                    'createdAt': '2026-03-13T09:00:00.000Z',
                  },
                };
              }
              if (path == '/reviews/rev_backend/replies') {
                return {
                  'reply': {
                    'authorName': 'Rauf Mammadov',
                    'message': 'Thanks for the detailed feedback.',
                    'createdAt': '2026-03-13T10:00:00.000Z',
                  },
                };
              }
              throw StateError('Unexpected POST path $path');
            },
          ),
        );

        await repository.createReservationReview(
          reservation: _buildCompletedReservationSummary(),
          authorName: 'Test Customer',
          rating: 4.8,
          comment: 'Strong experience.',
        );

        await repository.replyToReview(
          reviewId: 'rev_backend',
          authorName: 'Rauf Mammadov',
          message: 'Thanks for the detailed feedback.',
        );

        final updated = await repository.getReservationReview('res_completed');

        expect(updated, isNotNull);
        expect(updated!.reply, isNotNull);
        expect(updated.reply!.message, 'Thanks for the detailed feedback.');
      },
    );

    test('getEntityReviews maps backend review list payloads', () async {
      final repository = BackendReviewsRepository(
        apiClient: _FakeReviewsApiClient(
          onGet: ({required path, queryParameters}) {
            if (path == '/reviews') {
              return {
                'items': [
                  {
                    'id': 'rev_list_1',
                    'reservationId': 'res_completed',
                    'authorName': 'Test Customer',
                    'rating': 5,
                    'comment': 'Excellent finish.',
                    'createdAt': '2026-03-13T09:00:00.000Z',
                    'targets': [
                      {
                        'type': 'SERVICE',
                        'id': 'classic-haircut',
                        'name': 'Classic haircut',
                      },
                    ],
                  },
                ],
              };
            }
            throw StateError('Unexpected GET path $path');
          },
        ),
      );

      final reviews = await repository.getEntityReviews(
        type: ReviewTargetType.service,
        entityId: 'classic-haircut',
      );

      expect(reviews, hasLength(1));
      expect(reviews.single.id, 'rev_list_1');
      expect(reviews.single.targets.single.type, ReviewTargetType.service);
    });
  });
}

ReservationSummary _buildCompletedReservationSummary() {
  return ReservationSummary(
    id: 'res_completed',
    serviceId: 'classic-haircut',
    serviceName: 'Classic haircut',
    providerId: 'rauf-mammadov',
    providerName: 'Rauf Mammadov',
    customerName: 'Test Customer',
    addressLine: '14 Fountain Sq',
    scheduledAt: DateTime(2026, 3, 13, 15),
    createdAt: DateTime(2026, 3, 12, 12),
    status: ReservationStatus.completed,
    approvalMode: ApprovalMode.manual,
    priceLabel: '28 AZN',
    brandId: 'studio-north',
    brandName: 'Studio North',
  );
}

class _FakeReviewsApiClient extends ApiClient {
  _FakeReviewsApiClient({this.onGet, this.onPost}) : super(Dio());

  final dynamic Function({
    required String path,
    Map<String, dynamic>? queryParameters,
  })?
  onGet;
  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPost;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(
      onGet?.call(path: path, queryParameters: queryParameters) ??
          <String, dynamic>{},
    );
  }

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

  @override
  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(<String, dynamic>{});
  }
}
