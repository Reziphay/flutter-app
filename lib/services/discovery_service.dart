// discovery_service.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../models/category.dart';
import '../models/discovery.dart';

class DiscoveryService {
  DiscoveryService._();
  static final DiscoveryService instance = DiscoveryService._();

  final _client = ApiClient.instance;

  // MARK: - Categories

  Future<List<CategoryItem>> fetchCategories() async {
    final result = await _client.get(
      Endpoints.categories,
      fromJson: (json) => json,
    );
    final items = result['items'] as List<dynamic>? ?? [];
    return items
        .map((c) => CategoryItem.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // MARK: - Search (unified)

  Future<SearchResults> search({
    String? query,
    String? categoryId,
    String? brandId,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (categoryId != null) 'categoryId': categoryId,
      if (brandId != null) 'brandId': brandId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (sortBy != null) 'sortBy': sortBy,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };

    return _client.get(
      Endpoints.search,
      queryParameters: params,
      fromJson: SearchResults.fromJson,
    );
  }

  // MARK: - Nearby Services

  Future<ServiceListResult> fetchNearbyServices({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      'sortBy': 'PROXIMITY',
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };

    return _client.get(
      Endpoints.nearbyServices,
      queryParameters: params,
      fromJson: ServiceListResult.fromJson,
    );
  }

  // MARK: - Featured Services (top rated)

  Future<ServiceListResult> fetchFeaturedServices({
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, dynamic>{
      'sortBy': 'RATING',
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };

    return _client.get(
      Endpoints.search,
      queryParameters: params,
      fromJson: (json) => ServiceListResult(
        items: (json['services'] as List<dynamic>?)
                ?.map((s) => ServiceItem.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        pageInfo: json['servicesPageInfo'] != null
            ? PageInfo.fromJson(json['servicesPageInfo'] as Map<String, dynamic>)
            : null,
      ),
    );
  }

  // MARK: - Popular Brands

  Future<BrandListResult> fetchPopularBrands({
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, dynamic>{
      'sortBy': 'RATING',
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };

    return _client.get(
      Endpoints.search,
      queryParameters: params,
      fromJson: (json) => BrandListResult(
        items: (json['brands'] as List<dynamic>?)
                ?.map((b) => BrandItem.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        pageInfo: json['brandsPageInfo'] != null
            ? PageInfo.fromJson(json['brandsPageInfo'] as Map<String, dynamic>)
            : null,
      ),
    );
  }

  // MARK: - Service Detail

  Future<ServiceItem> fetchServiceDetail(String id) async {
    final result = await _client.get(
      Endpoints.serviceById(id),
      fromJson: (json) => json,
    );
    // Detail endpoint returns { service: {...} }
    final serviceJson = result['service'] as Map<String, dynamic>? ?? result;
    return ServiceItem.fromJson(serviceJson);
  }

  // MARK: - Brand Detail

  Future<BrandItem> fetchBrandDetail(String id) async {
    final result = await _client.get(
      Endpoints.brandById(id),
      fromJson: (json) => json,
    );
    final brandJson = result['brand'] as Map<String, dynamic>? ?? result;
    return BrandItem.fromJson(brandJson);
  }

  // MARK: - Brand Services

  Future<ServiceListResult> fetchBrandServices(String brandId, {int limit = 10}) async {
    return _client.get(
      Endpoints.services,
      queryParameters: {'brandId': brandId, 'limit': limit},
      fromJson: ServiceListResult.fromJson,
    );
  }
}
