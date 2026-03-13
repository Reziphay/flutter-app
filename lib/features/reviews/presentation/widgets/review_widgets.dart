import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_cards.dart';
import 'package:reziphay_mobile/features/reviews/models/review_models.dart';

class AppReviewCard extends StatelessWidget {
  const AppReviewCard({
    required this.review,
    super.key,
    this.onDelete,
    this.onReply,
    this.onReport,
  });

  final AppReview review;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      review.createdAtLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              RatingRow(rating: review.rating),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            review.comment,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          if (review.reply != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusPill(
                    label: 'Provider reply',
                    tone: StatusPillTone.info,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    review.reply!.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${review.reply!.authorName} · ${review.reply!.createdAtLabel}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
          if (onDelete != null || onReply != null || onReport != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (onReply != null)
                  TextButton.icon(
                    onPressed: onReply,
                    icon: const Icon(Icons.reply_outlined),
                    label: const Text('Reply'),
                  ),
                if (onReport != null)
                  TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report'),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    required this.rating,
    required this.onChanged,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        final star = index + 1;
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: star <= rating ? AppColors.warning : AppColors.textMuted,
            size: 32,
          ),
        );
      }),
    );
  }
}

class EntityReviewsSection extends StatelessWidget {
  const EntityReviewsSection({
    required this.staticReviews,
    required this.dynamicReviewsAsync,
    super.key,
    this.onReport,
    this.emptyTitle = 'No reviews yet',
    this.emptyDescription = 'Completed reservations unlock the review flow.',
  });

  final List<ReviewPreview> staticReviews;
  final AsyncValue<List<AppReview>> dynamicReviewsAsync;
  final ValueChanged<AppReview>? onReport;
  final String emptyTitle;
  final String emptyDescription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        dynamicReviewsAsync.when(
          data: (dynamicReviews) => _ReviewSectionContent(
            staticReviews: staticReviews,
            dynamicReviews: dynamicReviews,
            onReport: onReport,
            emptyTitle: emptyTitle,
            emptyDescription: emptyDescription,
          ),
          loading: () => _ReviewSectionContent(
            staticReviews: staticReviews,
            dynamicReviews: const [],
            onReport: onReport,
            emptyTitle: emptyTitle,
            emptyDescription: emptyDescription,
            isLoading: true,
          ),
          error: (error, stackTrace) => _ReviewSectionContent(
            staticReviews: staticReviews,
            dynamicReviews: const [],
            onReport: onReport,
            emptyTitle: emptyTitle,
            emptyDescription: emptyDescription,
            errorText: error.toString(),
          ),
        ),
      ],
    );
  }
}

class _ReviewSectionContent extends StatelessWidget {
  const _ReviewSectionContent({
    required this.staticReviews,
    required this.dynamicReviews,
    required this.emptyTitle,
    required this.emptyDescription,
    this.onReport,
    this.isLoading = false,
    this.errorText,
  });

  final List<ReviewPreview> staticReviews;
  final List<AppReview> dynamicReviews;
  final ValueChanged<AppReview>? onReport;
  final String emptyTitle;
  final String emptyDescription;
  final bool isLoading;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasAnyReviews = staticReviews.isNotEmpty || dynamicReviews.isNotEmpty;

    if (!hasAnyReviews && !isLoading && errorText == null) {
      return EmptyState(title: emptyTitle, description: emptyDescription);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (staticReviews.isNotEmpty)
          ...staticReviews
              .take(2)
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReviewCard(review: review),
                ),
              ),
        if (dynamicReviews.isNotEmpty) ...[
          if (staticReviews.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Latest completed reservations',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ...dynamicReviews
              .take(3)
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppReviewCard(
                    review: review,
                    onReport: onReport == null ? null : () => onReport!(review),
                  ),
                ),
              ),
        ],
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              errorText!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

Future<String?> showReviewTextSheet(
  BuildContext context, {
  required String title,
  required String labelText,
  required String hintText,
  required String buttonLabel,
}) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: buttonLabel,
                onPressed: () =>
                    Navigator.of(context).pop(controller.text.trim()),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool?> showReviewDeleteConfirmationSheet(
  BuildContext context, {
  required AppReview review,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete review',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Review comments cannot be edited later. Deleting removes this review from its targets.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              AppReviewCard(review: review),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Delete review',
                variant: AppButtonVariant.destructive,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      );
    },
  );
}
