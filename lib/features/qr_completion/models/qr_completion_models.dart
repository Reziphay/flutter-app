import 'package:intl/intl.dart';

enum QrCompletionStatus {
  success,
  invalid,
  expired,
  wrongProvider,
  alreadyCompleted,
  manualFallback,
}

extension QrCompletionStatusX on QrCompletionStatus {
  String get title => switch (this) {
    QrCompletionStatus.success => 'Reservation completed',
    QrCompletionStatus.invalid => 'QR code is invalid',
    QrCompletionStatus.expired => 'QR code expired',
    QrCompletionStatus.wrongProvider => 'Wrong provider QR',
    QrCompletionStatus.alreadyCompleted => 'Reservation already completed',
    QrCompletionStatus.manualFallback => 'Use manual completion',
  };

  String get description => switch (this) {
    QrCompletionStatus.success =>
      'The scan was verified and the reservation is now completed via QR.',
    QrCompletionStatus.invalid =>
      'The scanned payload was not recognized by the QR verification flow.',
    QrCompletionStatus.expired =>
      'This provider QR rotated out and needs to be refreshed before scanning again.',
    QrCompletionStatus.wrongProvider =>
      'The scanned QR does not belong to the provider attached to this reservation.',
    QrCompletionStatus.alreadyCompleted =>
      'This reservation was already completed, so scanning again changes nothing.',
    QrCompletionStatus.manualFallback =>
      'QR completion is not available for the current reservation state. The provider can still complete it manually.',
  };
}

class ProviderQrSession {
  const ProviderQrSession({
    required this.providerId,
    required this.providerName,
    required this.payload,
    required this.generatedAt,
    required this.expiresAt,
  });

  final String providerId;
  final String providerName;
  final String payload;
  final DateTime generatedAt;
  final DateTime expiresAt;

  String get generatedAtLabel =>
      DateFormat('MMM d · HH:mm').format(generatedAt);

  String get expiresAtLabel => DateFormat('HH:mm:ss').format(expiresAt);
}

class QrCompletionResult {
  const QrCompletionResult({
    required this.status,
    required this.reservationId,
    required this.providerId,
    required this.providerName,
  });

  final QrCompletionStatus status;
  final String reservationId;
  final String providerId;
  final String providerName;
}
