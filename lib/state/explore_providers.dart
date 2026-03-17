// explore_providers.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/category.dart';
import '../models/discovery.dart';
import '../services/discovery_service.dart';

// MARK: - Location

final locationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 10),
    ),
  );
});

// MARK: - Categories

final categoriesProvider = FutureProvider<List<CategoryItem>>((ref) async {
  return DiscoveryService.instance.fetchCategories();
});

// MARK: - Selected Category Filter

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// MARK: - Services Pool (all active services — MVP, no geo filter)

final servicesPoolProvider = FutureProvider<ServiceListResult>((ref) async {
  return DiscoveryService.instance.fetchAllServices();
});

// MARK: - Nearby Services (geo-filtered, used when location is available)

final nearbyServicesProvider = FutureProvider<ServiceListResult>((ref) async {
  final location = await ref.watch(locationProvider.future);
  if (location == null) return const ServiceListResult();

  return DiscoveryService.instance.fetchNearbyServices(
    lat: location.latitude,
    lng: location.longitude,
    radiusKm: 20,
    limit: 10,
  );
});

// MARK: - Popular Brands

final popularBrandsProvider = FutureProvider<BrandListResult>((ref) async {
  return DiscoveryService.instance.fetchPopularBrands(limit: 10);
});

// MARK: - Search

class SearchQuery {
  const SearchQuery({
    this.query = '',
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'RELEVANCE',
    this.lat,
    this.lng,
    this.radiusKm,
    this.showAll = false,
  });

  final String query;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final bool showAll;

  SearchQuery copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    String? sortBy,
    double? lat,
    double? lng,
    double? radiusKm,
    bool clearRadius = false,
    bool? showAll,
  }) {
    return SearchQuery(
      query:      query      ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice:   clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice:   clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sortBy:     sortBy ?? this.sortBy,
      lat:        lat    ?? this.lat,
      lng:        lng    ?? this.lng,
      radiusKm:   clearRadius ? null : (radiusKm ?? this.radiusKm),
      showAll:    showAll ?? this.showAll,
    );
  }

  bool get isEmpty => query.isEmpty && !showAll && categoryId == null && minPrice == null && maxPrice == null;
  bool get hasFilters => categoryId != null || minPrice != null || maxPrice != null || radiusKm != null;
}

final searchQueryProvider = StateProvider<SearchQuery>((ref) => const SearchQuery());

final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.isEmpty) return const SearchResults();

  return DiscoveryService.instance.search(
    query:      q.query.isEmpty ? null : q.query,
    categoryId: q.categoryId,
    lat:        q.lat,
    lng:        q.lng,
    radiusKm:   q.radiusKm,
    sortBy:     q.sortBy,
    limit:      25,
  );
});

// MARK: - Service Detail

final serviceDetailProvider = FutureProvider.family<ServiceItem, String>((ref, id) async {
  return DiscoveryService.instance.fetchServiceDetail(id);
});

// MARK: - Brand Detail

final brandDetailProvider = FutureProvider.family<BrandItem, String>((ref, id) async {
  return DiscoveryService.instance.fetchBrandDetail(id);
});

final brandServicesProvider = FutureProvider.family<ServiceListResult, String>((ref, brandId) async {
  return DiscoveryService.instance.fetchBrandServices(brandId);
});

// MARK: - Provider Services

final providerServicesProvider = FutureProvider.family<ServiceListResult, String>((ref, ownerId) async {
  return DiscoveryService.instance.fetchProviderServices(ownerId);
});
