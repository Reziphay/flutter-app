import 'package:intl/intl.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

enum ReviewTargetType { service, provider, brand }

extension ReviewTargetTypeX on ReviewTargetType {
  static ReviewTargetType? parse(String? rawValue) {
    switch (rawValue?.trim().toUpperCase()) {
      case 'SERVICE':
        return ReviewTargetType.service;
      case 'PROVIDER':
      case 'OWNER':
      case 'SERVICE_OWNER':
      case 'USO':
        return ReviewTargetType.provider;
      case 'BRAND':
        return ReviewTargetType.brand;
      default:
        return null;
    }
  }

  String get label => switch (this) {
    ReviewTargetType.service => 'Service',
    ReviewTargetType.provider => 'Provider',
    ReviewTargetType.brand => 'Brand',
  };

  String get backendValue => switch (this) {
    ReviewTargetType.service => 'SERVICE',
    ReviewTargetType.provider => 'PROVIDER',
    ReviewTargetType.brand => 'BRAND',
  };
}

class ReviewTarget {
  const ReviewTarget({
    required this.type,
    required this.id,
    required this.name,
  });

  final ReviewTargetType type;
  final String id;
  final String name;
}

class ReviewReply {
  const ReviewReply({
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  final String authorName;
  final String message;
  final DateTime createdAt;

  String get createdAtLabel => DateFormat('MMM d · HH:mm').format(createdAt);
}

class AppReview {
  const AppReview({
    required this.id,
    required this.reservationId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.targets,
    this.reply,
  });

  final String id;
  final String reservationId;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<ReviewTarget> targets;
  final ReviewReply? reply;

  String get createdAtLabel => DateFormat('MMM d').format(createdAt);

  ReviewPreview toPreview() {
    return ReviewPreview(
      authorName: authorName,
      rating: rating,
      comment: comment,
      dateLabel: createdAtLabel,
      reply: reply == null ? null : '${reply!.authorName}: ${reply!.message}',
    );
  }
}
