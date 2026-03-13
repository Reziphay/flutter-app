import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';

void main() {
  group('MockDiscoveryRepository', () {
    late MockDiscoveryRepository repository;

    setUp(() {
      repository = MockDiscoveryRepository();
    });

    test('search filters services by category and availability', () async {
      final response = await repository.search(
        const DiscoverySearchRequest(
          query: '',
          filters: SearchFilters(categoryId: 'barber', availableOnly: true),
          sort: SearchSort.proximity,
        ),
      );

      expect(response.services, isNotEmpty);
      expect(
        response.services.every(
          (service) => service.categoryId == 'barber' && service.isAvailable,
        ),
        isTrue,
      );
    });

    test('search query surfaces brand and provider results', () async {
      final response = await repository.search(
        const DiscoverySearchRequest(
          query: 'dental',
          filters: SearchFilters(),
          sort: SearchSort.rating,
        ),
      );

      expect(
        response.services.any((service) => service.id == 'dental-consultation'),
        isTrue,
      );
      expect(response.brands.any((brand) => brand.id == 'luna-dental'), isTrue);
      expect(
        response.providers.any((provider) => provider.id == 'kamala-aliyeva'),
        isTrue,
      );
    });

    test('price sorting orders services from lowest to highest', () async {
      final response = await repository.search(
        const DiscoverySearchRequest(
          query: '',
          filters: SearchFilters(),
          sort: SearchSort.price,
        ),
      );

      final pricedServices = response.services
          .where((service) => service.price != null)
          .toList();

      for (var index = 0; index < pricedServices.length - 1; index += 1) {
        expect(
          pricedServices[index].price!,
          lessThanOrEqualTo(pricedServices[index + 1].price!),
        );
      }
    });

    test(
      'service detail includes linked provider and optional brand',
      () async {
        final detail = await repository.getServiceDetail('classic-haircut');

        expect(detail.summary.name, 'Classic haircut');
        expect(detail.provider.id, 'rauf-mammadov');
        expect(detail.brand?.id, 'studio-north');
        expect(detail.requestableSlots, isNotEmpty);
      },
    );
  });

  group('BackendDiscoveryRepository', () {
    test(
      'customer home maps backend list responses into discovery sections',
      () async {
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            responses: {
              '/categories': {
                'items': [
                  {
                    'id': 'wellness',
                    'name': 'Wellness',
                    'description': 'Recovery and body care',
                  },
                ],
              },
              '/services': {
                'items': [
                  {
                    'id': 'svc_remote',
                    'name': 'Sports massage',
                    'category': {'id': 'wellness', 'name': 'Wellness'},
                    'owner': {'id': 'uso_remote', 'fullName': 'Nigar Rahimova'},
                    'brand': {'id': 'brand_remote', 'name': 'Flow House'},
                    'addressLine': '12 Seaside Ave',
                    'distanceKm': 1.1,
                    'rating': 4.9,
                    'reviewCount': 32,
                    'visibilityLabels': ['VIP'],
                    'approvalMode': 'MANUAL',
                    'isAvailable': true,
                    'popularityScore': 91,
                    'nextAvailabilityLabel': 'Today · 18:00',
                    'price': 45,
                    'description': 'Recovery-focused session',
                    'coverMedia': {
                      'id': 'svc_remote_cover',
                      'label': 'Recovery room',
                      'url': 'https://cdn.reziphay.test/svc_remote_cover.jpg',
                    },
                  },
                ],
              },
              '/brands': {
                'items': [
                  {
                    'id': 'brand_remote',
                    'name': 'Flow House',
                    'headline': 'Bodywork studio',
                    'addressLine': '12 Seaside Ave',
                    'distanceKm': 1.1,
                    'rating': 4.8,
                    'reviewCount': 18,
                    'serviceCount': 1,
                    'memberCount': 1,
                    'categoryIds': ['wellness'],
                    'visibilityLabels': ['COMMON'],
                    'popularityScore': 88,
                    'openNow': true,
                    'logo': {
                      'id': 'brand_remote_logo',
                      'label': 'Flow House mark',
                      'url': 'https://cdn.reziphay.test/brand_remote_logo.png',
                    },
                  },
                ],
              },
              '/service-owners': {
                'items': [
                  {
                    'id': 'uso_remote',
                    'fullName': 'Nigar Rahimova',
                    'headline': 'Sports recovery specialist',
                    'bio': 'Manual recovery sessions.',
                    'distanceKm': 1.1,
                    'rating': 4.9,
                    'reviewCount': 28,
                    'completedReservations': 120,
                    'avgResponseMinutes': 4,
                    'brands': [
                      {'id': 'brand_remote'},
                    ],
                    'categoryIds': ['wellness'],
                    'visibilityLabels': ['VIP'],
                    'popularityScore': 90,
                    'availableNow': true,
                  },
                ],
              },
            },
          ),
        );

        final home = await repository.getCustomerHomeData();

        expect(home.categories.first.id, 'wellness');
        expect(home.nearYou.first.id, 'svc_remote');
        expect(
          home.nearYou.first.coverMedia?.remoteUrl,
          'https://cdn.reziphay.test/svc_remote_cover.jpg',
        );
        expect(home.popularBrands.first.id, 'brand_remote');
        expect(
          home.popularBrands.first.logoMedia?.remoteUrl,
          'https://cdn.reziphay.test/brand_remote_logo.png',
        );
        expect(home.popularProviders.first.id, 'uso_remote');
      },
    );

    test(
      'service detail maps backend payload into the mobile detail model',
      () async {
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            responses: {
              '/services/svc_remote': {
                'id': 'svc_remote',
                'name': 'Sports massage',
                'category': {'id': 'wellness', 'name': 'Wellness'},
                'owner': {
                  'id': 'uso_remote',
                  'fullName': 'Nigar Rahimova',
                  'headline': 'Sports recovery specialist',
                  'bio': 'Manual recovery sessions.',
                  'rating': 4.9,
                  'reviewCount': 28,
                  'completedReservations': 120,
                  'avgResponseMinutes': 4,
                  'brands': [
                    {'id': 'brand_remote'},
                  ],
                  'categoryIds': ['wellness'],
                  'visibilityLabels': ['VIP'],
                  'availableNow': true,
                },
                'brand': {
                  'id': 'brand_remote',
                  'name': 'Flow House',
                  'headline': 'Bodywork studio',
                  'addressLine': '12 Seaside Ave',
                  'rating': 4.8,
                  'reviewCount': 18,
                  'serviceCount': 1,
                  'memberCount': 1,
                  'categoryIds': ['wellness'],
                  'visibilityLabels': ['COMMON'],
                  'openNow': true,
                },
                'addressLine': '12 Seaside Ave',
                'distanceKm': 1.1,
                'rating': 4.9,
                'reviewCount': 32,
                'visibilityLabels': ['VIP'],
                'approvalMode': 'MANUAL',
                'isAvailable': true,
                'popularityScore': 91,
                'nextAvailabilityLabel': 'Today · 18:00',
                'price': 45,
                'description': 'Recovery-focused session',
                'about': 'Deep tissue recovery with manual approval.',
                'waitingTimeMinutes': 15,
                'freeCancellationHours': 6,
                'availabilitySummary': 'Backend availability summary',
                'availability': {
                  'items': [
                    {
                      'startsAt': '2026-03-13T18:00:00.000Z',
                      'label': 'Today · 18:00',
                      'available': true,
                    },
                  ],
                },
                'photos': [
                  {'id': 'photo_1', 'name': 'Room'},
                ],
              },
            },
          ),
        );

        final detail = await repository.getServiceDetail('svc_remote');

        expect(detail.summary.name, 'Sports massage');
        expect(detail.summary.approvalMode, ApprovalMode.manual);
        expect(detail.provider.id, 'uso_remote');
        expect(detail.brand?.id, 'brand_remote');
        expect(detail.requestableSlots, isNotEmpty);
        expect(detail.galleryMedia, isNotEmpty);
      },
    );

    test(
      'provider services and create service use backend-scoped endpoints',
      () async {
        String? capturedPath;
        Object? capturedData;
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/service-owners/me/services') {
                return {
                  'items': [
                    {
                      'id': 'svc_provider_1',
                      'name': 'Executive cleanup',
                      'category': {'id': 'barber', 'name': 'Barber'},
                      'owner': {
                        'id': 'uso_remote',
                        'fullName': 'Rauf Mammadov',
                      },
                      'brand': {'id': 'brand_remote', 'name': 'Studio North'},
                      'addressLine': '42 Central Ave',
                      'distanceKm': 1.2,
                      'rating': 4.8,
                      'reviewCount': 12,
                      'visibilityLabels': ['VIP'],
                      'approvalMode': 'MANUAL',
                      'isAvailable': true,
                      'popularityScore': 91,
                      'nextAvailabilityLabel': 'Tomorrow · 14:00',
                      'price': 55,
                      'descriptionSnippet':
                          'Premium cleanup with manual approval.',
                      'serviceType': 'MULTI',
                      'waitingTimeMinutes': 15,
                      'leadTimeHours': 2,
                      'exceptionNotes': ['Closed on Sundays.'],
                    },
                  ],
                };
              }
              throw StateError('Unexpected GET path $path');
            },
            onPost: ({required path, data, queryParameters}) {
              capturedPath = path;
              capturedData = data;
              if (path == '/service-owners/me/services') {
                return {
                  'service': {
                    'id': 'svc_provider_created',
                    'name': 'Executive cleanup',
                    'category': {'id': 'barber', 'name': 'Barber'},
                    'owner': {'id': 'uso_remote', 'fullName': 'Rauf Mammadov'},
                    'brand': {'id': 'brand_remote', 'name': 'Studio North'},
                    'addressLine': '42 Central Ave',
                    'distanceKm': 1.2,
                    'rating': 4.8,
                    'reviewCount': 0,
                    'visibilityLabels': ['VIP'],
                    'approvalMode': 'MANUAL',
                    'isAvailable': true,
                    'popularityScore': 90,
                    'nextAvailabilityLabel': 'Tomorrow · 14:00',
                    'price': 55,
                    'descriptionSnippet':
                        'Premium cleanup with manual approval.',
                  },
                };
              }
              throw StateError('Unexpected POST path $path');
            },
          ),
        );

        final providerServices = await repository.getProviderServices(
          'uso_remote',
        );
        final createdId = await repository.createProviderService(
          providerId: 'uso_remote',
          draft: ProviderServiceDraft(
            name: 'Executive cleanup',
            categoryId: 'barber',
            categoryName: 'Barber',
            addressLine: '42 Central Ave',
            descriptionSnippet: 'Premium cleanup with manual approval.',
            about: 'Longer session with extra finishing time.',
            approvalMode: ApprovalMode.manual,
            isAvailable: true,
            serviceType: ManagedServiceType.multi,
            waitingTimeMinutes: 15,
            leadTimeHours: 2,
            freeCancellationHours: 4,
            visibilityLabels: const [VisibilityLabel.vip],
            requestableSlots: [
              AvailabilityWindow(
                startsAt: DateTime.parse('2026-03-14T14:00:00.000Z'),
                label: 'Tomorrow · 14:00',
                available: true,
                note: 'Manual approval',
              ),
            ],
            exceptionNotes: const ['Closed on Sundays.'],
            galleryMedia: const [],
            brandId: 'brand_remote',
            brandName: 'Studio North',
            price: 55,
          ),
        );

        expect(providerServices.services.single.summary.id, 'svc_provider_1');
        expect(
          providerServices.services.single.serviceType,
          ManagedServiceType.multi,
        );
        expect(providerServices.services.single.exceptionCount, 1);
        expect(createdId, 'svc_provider_created');
        expect(capturedPath, '/service-owners/me/services');
        expect(capturedData, isA<Map<String, dynamic>>());
        final payload = capturedData! as Map<String, dynamic>;
        expect(payload['approvalMode'], 'MANUAL');
        expect(payload['serviceType'], 'MULTI');
        expect(payload['providerId'], 'uso_remote');
      },
    );

    test(
      'provider brand detail and join request actions use backend endpoints',
      () async {
        String? capturedActionPath;
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/service-owners/me/brands/brand_remote') {
                return {
                  'brand': {
                    'id': 'brand_remote',
                    'name': 'Studio North',
                    'headline': 'Minimal grooming studio',
                    'addressLine': '42 Central Ave',
                    'distanceKm': 1.2,
                    'rating': 4.8,
                    'reviewCount': 18,
                    'serviceCount': 2,
                    'memberCount': 1,
                    'categoryIds': ['barber'],
                    'visibilityLabels': ['VIP'],
                    'popularityScore': 88,
                    'openNow': true,
                    'description': 'Provider-owned premium room.',
                    'mapHint': 'Second floor above the corner cafe.',
                    'members': [
                      {
                        'id': 'uso_remote',
                        'fullName': 'Rauf Mammadov',
                        'headline': 'Lead barber',
                        'bio': 'Provider-owned premium room.',
                        'distanceKm': 1.2,
                        'rating': 4.8,
                        'reviewCount': 18,
                        'completedReservations': 120,
                        'categoryIds': ['barber'],
                        'visibilityLabels': ['VIP'],
                        'availableNow': true,
                      },
                    ],
                    'joinRequests': [
                      {
                        'id': 'jr_1',
                        'applicantName': 'Aysel Karimova',
                        'note': 'Ready to join the brand roster.',
                        'requestedAt': '2026-03-13T09:00:00.000Z',
                      },
                    ],
                    'services': [
                      {
                        'id': 'svc_brand_1',
                        'name': 'Signature trim',
                        'category': {'id': 'barber', 'name': 'Barber'},
                        'owner': {
                          'id': 'uso_remote',
                          'fullName': 'Rauf Mammadov',
                        },
                        'brand': {'id': 'brand_remote', 'name': 'Studio North'},
                        'addressLine': '42 Central Ave',
                        'distanceKm': 1.2,
                        'rating': 4.8,
                        'reviewCount': 10,
                        'visibilityLabels': ['VIP'],
                        'approvalMode': 'MANUAL',
                        'isAvailable': true,
                        'popularityScore': 80,
                      },
                    ],
                  },
                };
              }
              throw StateError('Unexpected GET path $path');
            },
            onPost: ({required path, data, queryParameters}) {
              capturedActionPath = path;
              if (path == '/brands/brand_remote/join-requests/jr_1/accept') {
                return <String, dynamic>{};
              }
              throw StateError('Unexpected POST path $path');
            },
          ),
        );

        final brand = await repository.getProviderBrand(
          brandId: 'brand_remote',
          providerId: 'uso_remote',
        );
        await repository.acceptBrandJoinRequest(
          providerId: 'uso_remote',
          brandId: 'brand_remote',
          requestId: 'jr_1',
        );

        expect(brand.detail.summary.id, 'brand_remote');
        expect(brand.joinRequests.single.applicantName, 'Aysel Karimova');
        expect(brand.detail.services.single.id, 'svc_brand_1');
        expect(
          capturedActionPath,
          '/brands/brand_remote/join-requests/jr_1/accept',
        );
      },
    );

    test(
      'update service falls back from patch to put and archive uses delete',
      () async {
        String? capturedPutPath;
        String? capturedDeletePath;
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            onPatch: ({required path, data, queryParameters}) {
              throw const AppException(
                'Patch not supported.',
                type: AppExceptionType.server,
                statusCode: 405,
              );
            },
            onPut: ({required path, data, queryParameters}) {
              capturedPutPath = path;
              return {
                'service': {
                  'id': 'svc_provider_1',
                  'name': 'Executive cleanup',
                  'category': {'id': 'barber', 'name': 'Barber'},
                  'owner': {'id': 'uso_remote', 'fullName': 'Rauf Mammadov'},
                  'addressLine': '42 Central Ave',
                  'distanceKm': 1.2,
                  'rating': 4.8,
                  'reviewCount': 12,
                  'visibilityLabels': ['VIP'],
                  'approvalMode': 'AUTOMATIC',
                  'isAvailable': true,
                  'popularityScore': 91,
                },
              };
            },
            onDelete: ({required path, data, queryParameters}) {
              capturedDeletePath = path;
              return <String, dynamic>{};
            },
          ),
        );

        await repository.updateProviderService(
          providerId: 'uso_remote',
          serviceId: 'svc_provider_1',
          draft: const ProviderServiceDraft(
            name: 'Executive cleanup',
            categoryId: 'barber',
            categoryName: 'Barber',
            addressLine: '42 Central Ave',
            descriptionSnippet: 'Updated cleanup flow.',
            about: 'Updated notes.',
            approvalMode: ApprovalMode.automatic,
            isAvailable: true,
            serviceType: ManagedServiceType.solo,
            waitingTimeMinutes: 10,
            leadTimeHours: 1,
            freeCancellationHours: 2,
            visibilityLabels: [VisibilityLabel.vip],
            requestableSlots: [],
            exceptionNotes: [],
            galleryMedia: [],
          ),
        );
        await repository.archiveProviderService(
          providerId: 'uso_remote',
          serviceId: 'svc_provider_1',
        );

        expect(capturedPutPath, '/service-owners/me/services/svc_provider_1');
        expect(
          capturedDeletePath,
          '/service-owners/me/services/svc_provider_1',
        );
      },
    );
  });
}

class _FakeDiscoveryApiClient extends ApiClient {
  _FakeDiscoveryApiClient({
    this.responses = const {},
    this.onGet,
    this.onPost,
    this.onPatch,
    this.onPut,
    this.onDelete,
  }) : super(Dio());

  final Map<String, dynamic> responses;
  final dynamic Function({
    required String path,
    Map<String, dynamic>? queryParameters,
  })?
  onGet;
  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPost;
  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPatch;
  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPut;
  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onDelete;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    final direct = onGet?.call(path: path, queryParameters: queryParameters);
    if (direct != null || onGet != null) {
      return mapper(direct);
    }
    final response = responses[path];
    if (!responses.containsKey(path)) {
      throw StateError('Missing fake response for $path');
    }
    return mapper(response);
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    final response = onPost?.call(
      path: path,
      data: data,
      queryParameters: queryParameters,
    );
    if (response == null && onPost == null) {
      throw StateError('Missing fake POST response for $path');
    }
    return mapper(response);
  }

  @override
  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    final response = onPatch?.call(
      path: path,
      data: data,
      queryParameters: queryParameters,
    );
    if (response == null && onPatch == null) {
      throw StateError('Missing fake PATCH response for $path');
    }
    return mapper(response);
  }

  @override
  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    final response = onPut?.call(
      path: path,
      data: data,
      queryParameters: queryParameters,
    );
    if (response == null && onPut == null) {
      throw StateError('Missing fake PUT response for $path');
    }
    return mapper(response);
  }

  @override
  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    final response = onDelete?.call(
      path: path,
      data: data,
      queryParameters: queryParameters,
    );
    if (response == null && onDelete == null) {
      throw StateError('Missing fake DELETE response for $path');
    }
    return mapper(response);
  }
}
