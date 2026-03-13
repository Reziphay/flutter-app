import 'package:intl/intl.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

enum ReviewTargetType { service, provider, brand }

extension ReviewTargetTypeX on ReviewTargetType {
  String get label => switch (this) {
    ReviewTargetType.service => 'Service',
    ReviewTargetType.provider => 'Provider',
    ReviewTargetType.brand => 'Brand',
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
