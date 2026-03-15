// discovery.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

// MARK: - Shared sub-models

class AddressItem {
  const AddressItem({
    required this.id,
    this.label,
    required this.fullAddress,
    required this.country,
    required this.city,
    this.lat,
    this.lng,
  });

  final String id;
  final String? label;
  final String fullAddress;
  final String country;
  final String city;
  final double? lat;
  final double? lng;

  factory AddressItem.fromJson(Map<String, dynamic> json) {
    return AddressItem(
      id:          json['id']          as String? ?? '',
      label:       json['label']       as String?,
      fullAddress: json['fullAddress'] as String? ?? '',
      country:     json['country']     as String? ?? '',
      city:        json['city']        as String? ?? '',
      lat:         (json['lat'] as num?)?.toDouble(),
      lng:         (json['lng'] as num?)?.toDouble(),
    );
  }
}

class RatingStats {
  const RatingStats({required this.avgRating, required this.reviewCount});

  final double avgRating;
  final int reviewCount;

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      avgRating:   (json['avgRating']   as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt()    ?? 0,
    );
  }

  static const zero = RatingStats(avgRating: 0, reviewCount: 0);
}

class DiscoveryOwner {
  const DiscoveryOwner({
    required this.id,
    required this.fullName,
    this.ratingStats,
  });

  final String id;
  final String fullName;
  final RatingStats? ratingStats;

  factory DiscoveryOwner.fromJson(Map<String, dynamic> json) {
    return DiscoveryOwner(
      id:          json['id']       as String? ?? '',
      fullName:    json['fullName'] as String? ?? '',
      ratingStats: json['ratingStats'] != null
          ? RatingStats.fromJson(json['ratingStats'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DiscoveryCategoryRef {
  const DiscoveryCategoryRef({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory DiscoveryCategoryRef.fromJson(Map<String, dynamic> json) {
    return DiscoveryCategoryRef(
      id:   json['id']   as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class DiscoveryBrandRef {
  const DiscoveryBrandRef({
    required this.id,
    required this.name,
    this.status,
    this.ratingStats,
  });

  final String id;
  final String name;
  final String? status;
  final RatingStats? ratingStats;

  factory DiscoveryBrandRef.fromJson(Map<String, dynamic> json) {
    return DiscoveryBrandRef(
      id:     json['id']     as String? ?? '',
      name:   json['name']   as String? ?? '',
      status: json['status'] as String?,
      ratingStats: json['ratingStats'] != null
          ? RatingStats.fromJson(json['ratingStats'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VisibilityLabel {
  const VisibilityLabel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory VisibilityLabel.fromJson(Map<String, dynamic> json) {
    return VisibilityLabel(
      id:   json['id']   as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

// MARK: - Service Item (from /search and /services/nearby)

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.address,
    this.brand,
    this.owner,
    this.priceAmount,
    this.priceCurrency,
    this.serviceType,
    this.approvalMode,
    this.ratingStats,
    this.distanceKm,
    this.visibilityLabels = const [],
    this.visibilityPriority = 0,
  });

  final String id;
  final String name;
  final String? description;
  final DiscoveryCategoryRef? category;
  final AddressItem? address;
  final DiscoveryBrandRef? brand;
  final DiscoveryOwner? owner;
  final double? priceAmount;
  final String? priceCurrency;
  final String? serviceType;
  final String? approvalMode;
  final RatingStats? ratingStats;
  final double? distanceKm;
  final List<VisibilityLabel> visibilityLabels;
  final int visibilityPriority;

  bool get isFree => priceAmount == null || priceAmount == 0;
  bool get isVip  => visibilityLabels.any((l) => l.slug == 'vip');

  String get priceDisplay {
    if (isFree) return 'Free';
    final currency = priceCurrency ?? '';
    final amount = priceAmount!;
    if (amount == amount.truncate()) {
      return '$currency ${amount.truncate()}';
    }
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final labels = (json['visibilityLabels'] as List<dynamic>?)
            ?.map((l) => VisibilityLabel.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [];
    return ServiceItem(
      id:                 json['id']           as String? ?? '',
      name:               json['name']         as String? ?? '',
      description:        json['description']  as String?,
      priceAmount:        (json['priceAmount']  as num?)?.toDouble(),
      priceCurrency:      json['priceCurrency'] as String?,
      serviceType:        json['serviceType']   as String?,
      approvalMode:       json['approvalMode']  as String?,
      distanceKm:         (json['distanceKm'] as num?)?.toDouble(),
      visibilityPriority: (json['visibilityPriority'] as num?)?.toInt() ?? 0,
      visibilityLabels:   labels,
      category: json['category'] != null
          ? DiscoveryCategoryRef.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      address: json['address'] != null
          ? AddressItem.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      brand: json['brand'] != null
          ? DiscoveryBrandRef.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      owner: json['owner'] != null
          ? DiscoveryOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      ratingStats: json['ratingStats'] != null
          ? RatingStats.fromJson(json['ratingStats'] as Map<String, dynamic>)
          : null,
    );
  }
}

// MARK: - Brand Item (from /search)

class BrandItem {
  const BrandItem({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.owner,
    this.ratingStats,
    this.distanceKm,
    this.visibilityLabels = const [],
    this.visibilityPriority = 0,
  });

  final String id;
  final String name;
  final String? description;
  final AddressItem? address;
  final DiscoveryOwner? owner;
  final RatingStats? ratingStats;
  final double? distanceKm;
  final List<VisibilityLabel> visibilityLabels;
  final int visibilityPriority;

  bool get isVip => visibilityLabels.any((l) => l.slug == 'vip');

  factory BrandItem.fromJson(Map<String, dynamic> json) {
    final labels = (json['visibilityLabels'] as List<dynamic>?)
            ?.map((l) => VisibilityLabel.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [];
    return BrandItem(
      id:                 json['id']           as String? ?? '',
      name:               json['name']         as String? ?? '',
      description:        json['description']  as String?,
      distanceKm:         (json['distanceKm'] as num?)?.toDouble(),
      visibilityPriority: (json['visibilityPriority'] as num?)?.toInt() ?? 0,
      visibilityLabels:   labels,
      address: json['address'] != null
          ? AddressItem.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      owner: json['owner'] != null
          ? DiscoveryOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      ratingStats: json['ratingStats'] != null
          ? RatingStats.fromJson(json['ratingStats'] as Map<String, dynamic>)
          : null,
    );
  }
}

// MARK: - Provider Item (from /search and /service-owners)

class FeaturedService {
  const FeaturedService({
    required this.id,
    required this.name,
    this.serviceType,
    this.approvalMode,
    this.address,
  });

  final String id;
  final String name;
  final String? serviceType;
  final String? approvalMode;
  final AddressItem? address;

  factory FeaturedService.fromJson(Map<String, dynamic> json) {
    return FeaturedService(
      id:           json['id']           as String? ?? '',
      name:         json['name']         as String? ?? '',
      serviceType:  json['serviceType']  as String?,
      approvalMode: json['approvalMode'] as String?,
      address: json['address'] != null
          ? AddressItem.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProviderBrandRef {
  const ProviderBrandRef({required this.id, required this.name, this.address});

  final String id;
  final String name;
  final AddressItem? address;

  factory ProviderBrandRef.fromJson(Map<String, dynamic> json) {
    final addr = json['primaryAddress'] ?? (json['addresses'] as List?)?.firstOrNull;
    return ProviderBrandRef(
      id:      json['id']   as String? ?? '',
      name:    json['name'] as String? ?? '',
      address: addr != null ? AddressItem.fromJson(addr as Map<String, dynamic>) : null,
    );
  }
}

class ProviderItem {
  const ProviderItem({
    required this.id,
    required this.name,
    this.ratingStats,
    this.distanceKm,
    this.featuredServices = const [],
    this.brands = const [],
    this.visibilityLabels = const [],
    this.visibilityPriority = 0,
  });

  final String id;
  final String name;
  final RatingStats? ratingStats;
  final double? distanceKm;
  final List<FeaturedService> featuredServices;
  final List<ProviderBrandRef> brands;
  final List<VisibilityLabel> visibilityLabels;
  final int visibilityPriority;

  bool get isVip => visibilityLabels.any((l) => l.slug == 'vip');

  factory ProviderItem.fromJson(Map<String, dynamic> json) {
    final labels = (json['visibilityLabels'] as List<dynamic>?)
            ?.map((l) => VisibilityLabel.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [];
    final services = (json['featuredServices'] as List<dynamic>?)
            ?.map((s) => FeaturedService.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    final brandList = (json['brands'] as List<dynamic>?)
            ?.map((b) => ProviderBrandRef.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [];
    return ProviderItem(
      id:                 json['id']   as String? ?? '',
      name:               json['name'] as String? ?? '',
      distanceKm:         (json['distanceKm'] as num?)?.toDouble(),
      visibilityPriority: (json['visibilityPriority'] as num?)?.toInt() ?? 0,
      visibilityLabels:   labels,
      featuredServices:   services,
      brands:             brandList,
      ratingStats: json['ratingStats'] != null
          ? RatingStats.fromJson(json['ratingStats'] as Map<String, dynamic>)
          : null,
    );
  }
}

// MARK: - Pagination

class PageInfo {
  const PageInfo({
    this.nextCursor,
    required this.hasMore,
    required this.limit,
  });

  final String? nextCursor;
  final bool hasMore;
  final int limit;

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      nextCursor: json['nextCursor'] as String?,
      hasMore:    json['hasMore']    as bool? ?? false,
      limit:      (json['limit'] as num?)?.toInt() ?? 10,
    );
  }
}

// MARK: - Search Results

class SearchResults {
  const SearchResults({
    this.services = const [],
    this.servicesPageInfo,
    this.brands = const [],
    this.brandsPageInfo,
    this.providers = const [],
    this.providersPageInfo,
  });

  final List<ServiceItem> services;
  final PageInfo? servicesPageInfo;
  final List<BrandItem> brands;
  final PageInfo? brandsPageInfo;
  final List<ProviderItem> providers;
  final PageInfo? providersPageInfo;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      services: (json['services'] as List<dynamic>?)
              ?.map((s) => ServiceItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      brandsPageInfo: json['servicesPageInfo'] != null
          ? PageInfo.fromJson(json['servicesPageInfo'] as Map<String, dynamic>)
          : null,
      brands: (json['brands'] as List<dynamic>?)
              ?.map((b) => BrandItem.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      servicesPageInfo: json['brandsPageInfo'] != null
          ? PageInfo.fromJson(json['brandsPageInfo'] as Map<String, dynamic>)
          : null,
      providers: (json['providers'] as List<dynamic>?)
              ?.map((p) => ProviderItem.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      providersPageInfo: json['providersPageInfo'] != null
          ? PageInfo.fromJson(json['providersPageInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ServiceListResult {
  const ServiceListResult({
    this.items = const [],
    this.pageInfo,
  });

  final List<ServiceItem> items;
  final PageInfo? pageInfo;

  factory ServiceListResult.fromJson(Map<String, dynamic> json) {
    return ServiceListResult(
      items: (json['items'] as List<dynamic>?)
              ?.map((s) => ServiceItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      pageInfo: json['pageInfo'] != null
          ? PageInfo.fromJson(json['pageInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BrandListResult {
  const BrandListResult({
    this.items = const [],
    this.pageInfo,
  });

  final List<BrandItem> items;
  final PageInfo? pageInfo;

  factory BrandListResult.fromJson(Map<String, dynamic> json) {
    return BrandListResult(
      items: (json['items'] as List<dynamic>?)
              ?.map((b) => BrandItem.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      pageInfo: json['pageInfo'] != null
          ? PageInfo.fromJson(json['pageInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}
