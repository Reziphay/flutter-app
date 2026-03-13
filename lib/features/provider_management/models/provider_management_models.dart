import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

enum ManagedServiceType { solo, multi }

extension ManagedServiceTypeX on ManagedServiceType {
  String get label => switch (this) {
    ManagedServiceType.solo => 'Solo',
    ManagedServiceType.multi => 'Multi',
  };

  String get description => switch (this) {
    ManagedServiceType.solo =>
      'One provider handles the service from request to completion.',
    ManagedServiceType.multi =>
      'The service can be fulfilled through a coordinated team workflow.',
  };
}

class ProviderServiceDraft {
  const ProviderServiceDraft({
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.addressLine,
    required this.descriptionSnippet,
    required this.about,
    required this.approvalMode,
    required this.isAvailable,
    required this.serviceType,
    required this.waitingTimeMinutes,
    required this.leadTimeHours,
    required this.freeCancellationHours,
    required this.visibilityLabels,
    required this.requestableSlots,
    required this.exceptionNotes,
    required this.galleryLabels,
    this.brandId,
    this.brandName,
    this.price,
  });

  final String name;
  final String categoryId;
  final String categoryName;
  final String addressLine;
  final String descriptionSnippet;
  final String about;
  final ApprovalMode approvalMode;
  final bool isAvailable;
  final ManagedServiceType serviceType;
  final int waitingTimeMinutes;
  final int leadTimeHours;
  final int freeCancellationHours;
  final List<VisibilityLabel> visibilityLabels;
  final List<AvailabilityWindow> requestableSlots;
  final List<String> exceptionNotes;
  final List<String> galleryLabels;
  final String? brandId;
  final String? brandName;
  final double? price;

  ProviderServiceDraft copyWith({
    String? name,
    String? categoryId,
    String? categoryName,
    String? addressLine,
    String? descriptionSnippet,
    String? about,
    ApprovalMode? approvalMode,
    bool? isAvailable,
    ManagedServiceType? serviceType,
    int? waitingTimeMinutes,
    int? leadTimeHours,
    int? freeCancellationHours,
    List<VisibilityLabel>? visibilityLabels,
    List<AvailabilityWindow>? requestableSlots,
    List<String>? exceptionNotes,
    List<String>? galleryLabels,
    Object? brandId = _sentinel,
    Object? brandName = _sentinel,
    Object? price = _sentinel,
  }) {
    return ProviderServiceDraft(
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      addressLine: addressLine ?? this.addressLine,
      descriptionSnippet: descriptionSnippet ?? this.descriptionSnippet,
      about: about ?? this.about,
      approvalMode: approvalMode ?? this.approvalMode,
      isAvailable: isAvailable ?? this.isAvailable,
      serviceType: serviceType ?? this.serviceType,
      waitingTimeMinutes: waitingTimeMinutes ?? this.waitingTimeMinutes,
      leadTimeHours: leadTimeHours ?? this.leadTimeHours,
      freeCancellationHours:
          freeCancellationHours ?? this.freeCancellationHours,
      visibilityLabels: visibilityLabels ?? this.visibilityLabels,
      requestableSlots: requestableSlots ?? this.requestableSlots,
      exceptionNotes: exceptionNotes ?? this.exceptionNotes,
      galleryLabels: galleryLabels ?? this.galleryLabels,
      brandId: identical(brandId, _sentinel)
          ? this.brandId
          : brandId as String?,
      brandName: identical(brandName, _sentinel)
          ? this.brandName
          : brandName as String?,
      price: identical(price, _sentinel) ? this.price : price as double?,
    );
  }
}

class ProviderManagedService {
  const ProviderManagedService({
    required this.detail,
    required this.draft,
    required this.canArchive,
  });

  final ServiceDetail detail;
  final ProviderServiceDraft draft;
  final bool canArchive;
}

class ProviderManagedServiceListItem {
  const ProviderManagedServiceListItem({
    required this.summary,
    required this.serviceType,
    required this.waitingTimeMinutes,
    required this.leadTimeHours,
    required this.exceptionCount,
    required this.canArchive,
  });

  final ServiceSummary summary;
  final ManagedServiceType serviceType;
  final int waitingTimeMinutes;
  final int leadTimeHours;
  final int exceptionCount;
  final bool canArchive;
}

class ProviderServicesData {
  const ProviderServicesData({
    required this.services,
    required this.activeCount,
    required this.manualApprovalCount,
    required this.brandLinkedCount,
  });

  final List<ProviderManagedServiceListItem> services;
  final int activeCount;
  final int manualApprovalCount;
  final int brandLinkedCount;
}

class BrandJoinRequest {
  const BrandJoinRequest({
    required this.id,
    required this.applicantName,
    required this.note,
    required this.requestedAtLabel,
  });

  final String id;
  final String applicantName;
  final String note;
  final String requestedAtLabel;
}

class ProviderBrandDraft {
  const ProviderBrandDraft({
    required this.name,
    required this.headline,
    required this.addressLine,
    required this.description,
    required this.mapHint,
    required this.visibilityLabels,
    required this.openNow,
    this.logoLabel,
  });

  final String name;
  final String headline;
  final String addressLine;
  final String description;
  final String mapHint;
  final List<VisibilityLabel> visibilityLabels;
  final bool openNow;
  final String? logoLabel;

  ProviderBrandDraft copyWith({
    String? name,
    String? headline,
    String? addressLine,
    String? description,
    String? mapHint,
    List<VisibilityLabel>? visibilityLabels,
    bool? openNow,
    Object? logoLabel = _sentinel,
  }) {
    return ProviderBrandDraft(
      name: name ?? this.name,
      headline: headline ?? this.headline,
      addressLine: addressLine ?? this.addressLine,
      description: description ?? this.description,
      mapHint: mapHint ?? this.mapHint,
      visibilityLabels: visibilityLabels ?? this.visibilityLabels,
      openNow: openNow ?? this.openNow,
      logoLabel: identical(logoLabel, _sentinel)
          ? this.logoLabel
          : logoLabel as String?,
    );
  }
}

class ProviderManagedBrand {
  const ProviderManagedBrand({
    required this.detail,
    required this.draft,
    required this.joinRequests,
  });

  final BrandDetail detail;
  final ProviderBrandDraft draft;
  final List<BrandJoinRequest> joinRequests;
}

class ProviderManagedBrandListItem {
  const ProviderManagedBrandListItem({
    required this.summary,
    required this.logoLabel,
    required this.joinRequestCount,
  });

  final BrandSummary summary;
  final String? logoLabel;
  final int joinRequestCount;
}

class ProviderBrandsData {
  const ProviderBrandsData({
    required this.brands,
    required this.totalServiceCount,
    required this.pendingJoinRequestCount,
  });

  final List<ProviderManagedBrandListItem> brands;
  final int totalServiceCount;
  final int pendingJoinRequestCount;
}

const _sentinel = Object();
