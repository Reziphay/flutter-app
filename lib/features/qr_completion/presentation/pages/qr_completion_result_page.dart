import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/features/qr_completion/models/qr_completion_models.dart';
import 'package:reziphay_mobile/features/qr_completion/presentation/pages/qr_scan_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservation_detail_page.dart';

class QrCompletionResultPage extends ConsumerWidget {
  const QrCompletionResultPage({
    required this.reservationId,
    required this.status,
    super.key,
  });

  static const path = '/customer/reservations/:reservationId/qr/result/:status';

  static String location(String reservationId, String status) =>
      '/customer/reservations/$reservationId/qr/result/$status';

  final String reservationId;
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultStatus = _statusFromPath(status);
    final isSuccess = resultStatus == QrCompletionStatus.success;

    return Scaffold(
      appBar: AppBar(title: const Text('QR result')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: isSuccess
                    ? const Color(0xFFEAF8F1)
                    : const Color(0xFFFDECEC),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isSuccess
                    ? Icons.check_circle_outline
                    : Icons.qr_code_2_outlined,
                size: 40,
                color: isSuccess ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            resultStatus.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            resultStatus.description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            color: AppColors.surfaceSoft,
            child: Text(
              isSuccess
                  ? 'The reservation detail now reflects QR completion and unlocks the review path.'
                  : 'If QR verification cannot complete, the provider can still finish the reservation manually from provider reservation detail.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Open reservation detail',
            onPressed: () => context.go(
              CustomerReservationDetailPage.location(reservationId),
            ),
          ),
          if (!isSuccess) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Try scanning again',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(QrScanPage.location(reservationId)),
            ),
          ],
        ],
      ),
    );
  }

  QrCompletionStatus _statusFromPath(String rawStatus) {
    for (final value in QrCompletionStatus.values) {
      if (value.name == rawStatus) {
        return value;
      }
    }
    return QrCompletionStatus.invalid;
  }
}
