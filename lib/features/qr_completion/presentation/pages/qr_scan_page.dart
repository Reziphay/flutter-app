import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/features/qr_completion/data/qr_completion_repository.dart';
import 'package:reziphay_mobile/features/qr_completion/presentation/pages/qr_completion_result_page.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/features/reservations/presentation/widgets/reservation_widgets.dart';

class QrScanPage extends ConsumerStatefulWidget {
  const QrScanPage({required this.reservationId, super.key});

  static const path = '/customer/reservations/:reservationId/qr/scan';

  static String location(String reservationId) =>
      '/customer/reservations/$reservationId/qr/scan';

  final String reservationId;

  @override
  ConsumerState<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends ConsumerState<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _manualCodeController = TextEditingController();
  var _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      customerReservationDetailProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Scan provider QR')),
      body: detailAsync.when(
        data: (detail) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.summary.serviceName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    detail.summary.providerName,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_isSubmitting) {
                      return;
                    }

                    final payload = capture.barcodes.firstOrNull?.rawValue;
                    if (payload == null || payload.isEmpty) {
                      return;
                    }

                    _submit(detail.summary, payload);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Point the camera at the provider QR. Verification still goes through the QR completion repository, not local parsing in the widget.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              color: AppColors.surfaceSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual entry fallback',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _manualCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Signed QR payload',
                      hintText:
                          'Paste a provider QR payload if camera scan fails.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Submit scanned payload',
                    variant: AppButtonVariant.secondary,
                    isLoading: _isSubmitting,
                    onPressed: () => _submit(
                      detail.summary,
                      _manualCodeController.text.trim(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not open QR scan',
            description: error.toString(),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(ReservationSummary summary, String payload) async {
    if (payload.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ref
          .read(qrCompletionRepositoryProvider)
          .submitScannedPayload(reservation: summary, payload: payload);

      _refreshReservations();

      if (!mounted) {
        return;
      }

      context.go(
        QrCompletionResultPage.location(
          widget.reservationId,
          result.status.name,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      await showReservationMessageSheet(
        context,
        title: 'QR submission failed',
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _refreshReservations() {
    ref.invalidate(customerReservationsProvider);
    ref.invalidate(providerReservationsProvider);
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(customerReservationDetailProvider(widget.reservationId));
    ref.invalidate(providerReservationDetailProvider(widget.reservationId));
  }
}
