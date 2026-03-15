// reservation.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ReservationStatus {
  pending,
  confirmed,
  rejected,
  cancelledByCustomer,
  cancelledByOwner,
  changeRequestedByCustomer,
  changeRequestedByOwner,
  completed,
  noShow,
  expired;

  static ReservationStatus fromString(String s) => switch (s) {
        'PENDING'                       => pending,
        'CONFIRMED'                     => confirmed,
        'REJECTED'                      => rejected,
        'CANCELLED_BY_CUSTOMER'         => cancelledByCustomer,
        'CANCELLED_BY_OWNER'            => cancelledByOwner,
        'CHANGE_REQUESTED_BY_CUSTOMER'  => changeRequestedByCustomer,
        'CHANGE_REQUESTED_BY_OWNER'     => changeRequestedByOwner,
        'COMPLETED'                     => completed,
        'NO_SHOW'                       => noShow,
        'EXPIRED'                       => expired,
        _                               => pending,
      };

  bool get isActive => this == pending || this == confirmed ||
      this == changeRequestedByCustomer || this == changeRequestedByOwner;

  bool get isCancellable => this == pending || this == confirmed ||
      this == changeRequestedByCustomer || this == changeRequestedByOwner;

  bool get isFinished => this == completed || this == cancelledByCustomer ||
      this == cancelledByOwner || this == rejected ||
      this == noShow || this == expired;
}

// ── Nested models ──────────────────────────────────────────────────────────────

class ReservationServiceRef {
  const ReservationServiceRef({
    required this.id,
    required this.name,
    required this.approvalMode,
    this.priceAmount,
    this.priceCurrency,
    this.waitingTimeMinutes,
    this.freeCancellationDeadlineMinutes,
  });

  final String id;
  final String name;
  final String approvalMode; // AUTO | MANUAL
  final double? priceAmount;
  final String? priceCurrency;
  final int? waitingTimeMinutes;
  final int? freeCancellationDeadlineMinutes;

  String get priceDisplay {
    if (priceAmount == null) return 'Free';
    if (priceAmount == 0) return 'Free';
    final amount = priceAmount!.truncateToDouble() == priceAmount!
        ? priceAmount!.toInt().toString()
        : priceAmount!.toStringAsFixed(2);
    return '${priceCurrency ?? ''} $amount'.trim();
  }

  factory ReservationServiceRef.fromJson(Map<String, dynamic> json) =>
      ReservationServiceRef(
        id: json['id'] as String,
        name: json['name'] as String,
        approvalMode: json['approvalMode'] as String? ?? 'MANUAL',
        priceAmount: (json['priceAmount'] as num?)?.toDouble(),
        priceCurrency: json['priceCurrency'] as String?,
        waitingTimeMinutes: json['waitingTimeMinutes'] as int?,
        freeCancellationDeadlineMinutes:
            json['freeCancellationDeadlineMinutes'] as int?,
      );
}

class ReservationBrandRef {
  const ReservationBrandRef({required this.id, required this.name});

  final String id;
  final String name;

  factory ReservationBrandRef.fromJson(Map<String, dynamic> json) =>
      ReservationBrandRef(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class ReservationUserRef {
  const ReservationUserRef({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String phone;

  factory ReservationUserRef.fromJson(Map<String, dynamic> json) =>
      ReservationUserRef(
        id: json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}

// ── Main model ─────────────────────────────────────────────────────────────────

class ReservationItem {
  const ReservationItem({
    required this.id,
    required this.status,
    required this.requestedStartAt,
    this.requestedEndAt,
    this.approvalExpiresAt,
    this.customerNote,
    this.rejectionReason,
    this.cancellationReason,
    this.freeCancellationEligible,
    this.cancelledAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.service,
    this.brand,
    required this.customer,
    required this.owner,
    this.completionQrPayload,
  });

  final String id;
  final ReservationStatus status;
  final DateTime requestedStartAt;
  final DateTime? requestedEndAt;
  final DateTime? approvalExpiresAt;
  final String? customerNote;
  final String? rejectionReason;
  final String? cancellationReason;
  final bool? freeCancellationEligible;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReservationServiceRef service;
  final ReservationBrandRef? brand;
  final ReservationUserRef customer;
  final ReservationUserRef owner;
  final String? completionQrPayload;

  factory ReservationItem.fromJson(Map<String, dynamic> json) =>
      ReservationItem(
        id: json['id'] as String,
        status: ReservationStatus.fromString(json['status'] as String? ?? ''),
        requestedStartAt: DateTime.parse(json['requestedStartAt'] as String),
        requestedEndAt: json['requestedEndAt'] != null
            ? DateTime.parse(json['requestedEndAt'] as String)
            : null,
        approvalExpiresAt: json['approvalExpiresAt'] != null
            ? DateTime.parse(json['approvalExpiresAt'] as String)
            : null,
        customerNote: json['customerNote'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        cancellationReason: json['cancellationReason'] as String?,
        freeCancellationEligible:
            json['freeCancellationEligibleAtCancellation'] as bool?,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        service: ReservationServiceRef.fromJson(
            json['service'] as Map<String, dynamic>),
        brand: json['brand'] != null
            ? ReservationBrandRef.fromJson(
                json['brand'] as Map<String, dynamic>)
            : null,
        customer: ReservationUserRef.fromJson(
            json['customer'] as Map<String, dynamic>),
        owner: ReservationUserRef.fromJson(
            json['owner'] as Map<String, dynamic>),
        completionQrPayload: json['completionQrPayload'] as String?,
      );
}

// ── Create DTO ─────────────────────────────────────────────────────────────────

class CreateReservationDto {
  const CreateReservationDto({
    required this.serviceId,
    required this.requestedStartAt,
    this.requestedEndAt,
    this.customerNote,
  });

  final String serviceId;
  final DateTime requestedStartAt;
  final DateTime? requestedEndAt;
  final String? customerNote;

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'requestedStartAt': requestedStartAt.toUtc().toIso8601String(),
        if (requestedEndAt != null)
          'requestedEndAt': requestedEndAt!.toUtc().toIso8601String(),
        if (customerNote != null && customerNote!.isNotEmpty)
          'customerNote': customerNote,
      };
}
