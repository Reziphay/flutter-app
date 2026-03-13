import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';

enum VisibilityLabel { common, vip, bestOfMonth, sponsored }

extension VisibilityLabelX on VisibilityLabel {
  String get label => switch (this) {
    VisibilityLabel.common => 'Common',
    VisibilityLabel.vip => 'VIP',
    VisibilityLabel.bestOfMonth => 'Best of month',
    VisibilityLabel.sponsored => 'Sponsored',
  };
}

enum ApprovalMode { manual, automatic }

extension ApprovalModeX on ApprovalMode {
  String get label => switch (this) {
    ApprovalMode.manual => 'Pending approval',
    ApprovalMode.automatic => 'Auto confirmation',
  };

  String get detailDescription => switch (this) {
    ApprovalMode.manual =>
      'The provider has 5 minutes to accept or reject this reservation request.',
    ApprovalMode.automatic =>
      'Confirmed times can be accepted immediately when the provider enables automatic approval.',
  };

  String get ctaLabel => switch (this) {
    ApprovalMode.manual => 'Request reservation',
    ApprovalMode.automatic => 'Reserve now',
  };
}

enum SearchSort { proximity, rating, price, popularity, availability }

extension SearchSortX on SearchSort {
  String get label => switch (this) {
    SearchSort.proximity => 'Proximity',
    SearchSort.rating => 'Rating',
    SearchSort.price => 'Price',
    SearchSort.popularity => 'Popularity',
    SearchSort.availability => 'Availability',
  };
}

enum SearchSegment { services, brands, providers }

extension SearchSegmentX on SearchSegment {
  String get label => switch (this) {
    SearchSegment.services => 'Services',
    SearchSegment.brands => 'Brands',
    SearchSegment.providers => 'Providers',
  };
}

class SearchFilters {
  const SearchFilters({
    this.categoryId,
    this.maxPrice,
    this.maxDistanceKm,
    this.minRating,
    this.availableOnly = false,
  });

  static const _unset = Object();

  final String? categoryId;
  final double? maxPrice;
  final double? maxDistanceKm;
  final double? minRating;
  final bool availableOnly;

  int get activeCount {
    var count = 0;
    if (categoryId != null) {
      count += 1;
    }
    if (maxPrice != null) {
      count += 1;
    }
    if (maxDistanceKm != null) {
      count += 1;
    }
    if (minRating != null) {
      count += 1;
    }
    if (availableOnly) {
      count += 1;
    }
    return count;
  }

  bool get hasActiveFilters => activeCount > 0;

  SearchFilters copyWith({
    Object? categoryId = _unset,
    Object? maxPrice = _unset,
    Object? maxDistanceKm = _unset,
    Object? minRating = _unset,
    bool? availableOnly,
  }) {
    return SearchFilters(
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      maxPrice: identical(maxPrice, _unset)
          ? this.maxPrice
          : maxPrice as double?,
      maxDistanceKm: identical(maxDistanceKm, _unset)
          ? this.maxDistanceKm
          : maxDistanceKm as double?,
      minRating: identical(minRating, _unset)
          ? this.minRating
          : minRating as double?,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchFilters &&
        other.categoryId == categoryId &&
        other.maxPrice == maxPrice &&
        other.maxDistanceKm == maxDistanceKm &&
        other.minRating == minRating &&
        other.availableOnly == availableOnly;
  }

  @override
  int get hashCode => Object.hash(
    categoryId,
    maxPrice,
    maxDistanceKm,
    minRating,
    availableOnly,
  );
}

class DiscoverySearchRequest {
  const DiscoverySearchRequest({
    required this.query,
    required this.filters,
    required this.sort,
  });

  final String query;
  final SearchFilters filters;
  final SearchSort sort;

  @override
  bool operator ==(Object other) {
    return other is DiscoverySearchRequest &&
        other.query == query &&
        other.filters == filters &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(query, filters, sort);
}

class DiscoveryCategory {
  const DiscoveryCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

class ReviewPreview {
  const ReviewPreview({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.dateLabel,
    this.reply,
  });

  final String authorName;
  final double rating;
  final String comment;
  final String dateLabel;
  final String? reply;
}

class AvailabilityWindow {
  const AvailabilityWindow({
    required this.startsAt,
    required this.label,
    required this.available,
    this.note,
  });

  final DateTime startsAt;
  final String label;
  final bool available;
  final String? note;
}

class BrandSummary {
  const BrandSummary({
    required this.id,
    required this.name,
    required this.headline,
    required this.addressLine,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.serviceCount,
    required this.memberCount,
    required this.categoryIds,
    required this.visibilityLabels,
    required this.popularityScore,
    required this.openNow,
    this.logoMedia,
  });

  final String id;
  final String name;
  final String headline;
  final String addressLine;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final int serviceCount;
  final int memberCount;
  final List<String> categoryIds;
  final List<VisibilityLabel> visibilityLabels;
  final int popularityScore;
  final bool openNow;
  final AppMediaAsset? logoMedia;
}

class ProviderSummary {
  const ProviderSummary({
    required this.id,
    required this.name,
    required this.headline,
    required this.bio,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.completedReservations,
    required this.responseReliability,
    required this.brandIds,
    required this.categoryIds,
    required this.visibilityLabels,
    required this.popularityScore,
    required this.availableNow,
  });

  final String id;
  final String name;
  final String headline;
  final String bio;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final int completedReservations;
  final String responseReliability;
  final List<String> brandIds;
  final List<String> categoryIds;
  final List<VisibilityLabel> visibilityLabels;
  final int popularityScore;
  final bool availableNow;
}

class ServiceSummary {
  const ServiceSummary({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.providerId,
    required this.providerName,
    required this.addressLine,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.visibilityLabels,
    required this.approvalMode,
    required this.isAvailable,
    required this.popularityScore,
    required this.nextAvailabilityLabel,
    this.brandId,
    this.brandName,
    this.price,
    this.descriptionSnippet,
    this.coverMedia,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String providerId;
  final String providerName;
  final String addressLine;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final List<VisibilityLabel> visibilityLabels;
  final ApprovalMode approvalMode;
  final bool isAvailable;
  final int popularityScore;
  final String nextAvailabilityLabel;
  final String? brandId;
  final String? brandName;
  final double? price;
  final String? descriptionSnippet;
  final AppMediaAsset? coverMedia;

  String get priceLabel =>
      price == null ? 'Price on request' : '${price!.toStringAsFixed(0)} AZN';
}

class ServiceDetail {
  const ServiceDetail({
    required this.summary,
    required this.description,
    required this.about,
    required this.availabilitySummary,
    required this.requestableSlots,
    required this.waitingTimeLabel,
    required this.freeCancellationLabel,
    required this.galleryMedia,
    required this.provider,
    required this.reviews,
    this.brand,
  });

  final ServiceSummary summary;
  final String description;
  final String about;
  final String availabilitySummary;
  final List<AvailabilityWindow> requestableSlots;
  final String waitingTimeLabel;
  final String freeCancellationLabel;
  final List<AppMediaAsset> galleryMedia;
  final ProviderSummary provider;
  final BrandSummary? brand;
  final List<ReviewPreview> reviews;

  List<String> get galleryLabels =>
      galleryMedia.map((asset) => asset.label).toList(growable: false);
}

class BrandDetail {
  const BrandDetail({
    required this.summary,
    required this.description,
    required this.mapHint,
    required this.members,
    required this.services,
    required this.reviews,
  });

  final BrandSummary summary;
  final String description;
  final String mapHint;
  final List<ProviderSummary> members;
  final List<ServiceSummary> services;
  final List<ReviewPreview> reviews;
}

class ProviderDetail {
  const ProviderDetail({
    required this.summary,
    required this.associatedBrands,
    required this.services,
    required this.reviews,
  });

  final ProviderSummary summary;
  final List<BrandSummary> associatedBrands;
  final List<ServiceSummary> services;
  final List<ReviewPreview> reviews;
}

class CustomerHomeData {
  const CustomerHomeData({
    required this.nearYou,
    required this.featured,
    required this.bestOfMonth,
    required this.categories,
    required this.popularBrands,
    required this.popularProviders,
  });

  final List<ServiceSummary> nearYou;
  final List<ServiceSummary> featured;
  final List<ServiceSummary> bestOfMonth;
  final List<DiscoveryCategory> categories;
  final List<BrandSummary> popularBrands;
  final List<ProviderSummary> popularProviders;
}

class DiscoverySearchResponse {
  const DiscoverySearchResponse({
    required this.services,
    required this.brands,
    required this.providers,
  });

  final List<ServiceSummary> services;
  final List<BrandSummary> brands;
  final List<ProviderSummary> providers;
}
