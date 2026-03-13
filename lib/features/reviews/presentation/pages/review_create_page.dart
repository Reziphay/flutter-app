import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/features/reviews/data/reviews_repository.dart';
import 'package:reziphay_mobile/features/reviews/presentation/widgets/review_widgets.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservation_detail_page.dart';

class ReviewCreatePage extends ConsumerStatefulWidget {
  const ReviewCreatePage({required this.reservationId, super.key});

  static const path = '/reviews/create/:reservationId';

  static String location(String reservationId) =>
      '/reviews/create/$reservationId';

  final String reservationId;

  @override
  ConsumerState<ReviewCreatePage> createState() => _ReviewCreatePageState();
}

class _ReviewCreatePageState extends ConsumerState<ReviewCreatePage> {
  final _commentController = TextEditingController();
  var _rating = 5;
  var _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      customerReservationDetailProvider(widget.reservationId),
    );
    final reviewAsync = ref.watch(
      reservationReviewProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Leave review')),
      body: detailAsync.when(
        data: (detail) => reviewAsync.when(
          data: (review) {
            if (review != null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: EmptyState(
                  title: 'Review already created',
                  description:
                      'This reservation already has a review, and comments are not editable after submission.',
                ),
              );
            }

            return _buildContent(context, detail.summary);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: EmptyState(
              title: 'Could not load review state',
              description: error.toString(),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load reservation',
            description: error.toString(),
          ),
        ),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (detail) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AppButton(
              label: 'Submit review',
              isLoading: _isSubmitting,
              onPressed:
                  detail.summary.effectiveStatus == ReservationStatus.completed
                  ? () => _submit(detail.summary)
                  : null,
            ),
          ),
        ),
        orElse: SizedBox.shrink,
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReservationSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.serviceName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                [
                  if (summary.brandName != null) summary.brandName!,
                  summary.providerName,
                ].join(' · '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                summary.scheduledAtLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Rate your experience',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        StarRatingInput(
          rating: _rating,
          onChanged: (value) => setState(() => _rating = value),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _commentController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Comment',
            hintText:
                'Share what went well, what felt off, or why you would recommend this reservation.',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          color: AppColors.surfaceSoft,
          child: Text(
            summary.brandName == null
                ? 'This review will inform the service and provider profiles. Comments cannot be edited after submission.'
                : 'This review will inform the service, provider, and brand profiles. Comments cannot be edited after submission.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(ReservationSummary summary) async {
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(reviewsActionsProvider)
          .createReservationReview(
            reservation: summary,
            rating: _rating.toDouble(),
            comment: _commentController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      context.go(CustomerReservationDetailPage.location(summary.id));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
