import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';
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
                    'id': '550e8400-e29b-41d4-a716-446655440001',
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
                    'category': {
                      'id': '550e8400-e29b-41d4-a716-446655440001',
                      'name': 'Wellness',
                    },
                    'owner': {'id': 'uso_remote', 'fullName': 'Nigar Rahimova'},
                    'brand': {'id': 'brand_remote', 'name': 'Flow House'},
                    'address': {'fullAddress': '12 Seaside Ave, Baku'},
                    'distanceKm': 1.1,
                    'ratingStats': {'avgRating': 4.9, 'reviewCount': 32},
                    'visibilityLabels': ['VIP'],
                    'approvalMode': 'MANUAL',
                    'isAvailable': true,
                    'popularityScore': 91,
                    'nextAvailabilityLabel': 'Today · 18:00',
                    'priceAmount': 45,
                    'description': 'Recovery-focused session',
                  },
                ],
              },
              '/brands': {
                'items': [
                  {
                    'id': 'brand_remote',
                    'name': 'Flow House',
                    'description': 'Bodywork studio',
                    'primaryAddress': {'fullAddress': '12 Seaside Ave, Baku'},
                    'ratingStats': {'avgRating': 4.8, 'reviewCount': 18},
                    'visibilityLabels': ['COMMON'],
                  },
                ],
              },
              '/service-owners': {
                'items': [
                  {
                    'id': 'uso_remote',
                    'fullName': 'Nigar Rahimova',
                    'description': 'Sports recovery specialist',
                    'ratingStats': {'avgRating': 4.9, 'reviewCount': 28},
                    'brands': [
                      {'id': 'brand_remote'},
                    ],
                    'visibilityLabels': ['VIP'],
                    'popularityScore': 90,
                  },
                ],
              },
            },
          ),
        );

        final home = await repository.getCustomerHomeData();

        expect(home.categories.first.name, 'Wellness');
        expect(home.nearYou.first.id, 'svc_remote');
        expect(home.nearYou.first.price, 45);
        expect(home.popularBrands.first.id, 'brand_remote');
        expect(home.popularProviders.first.id, 'uso_remote');
      },
    );

    test(
      'search uses backend search endpoint and preserves sort/filter mapping',
      () async {
        Map<String, dynamic>? capturedQuery;
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/search') {
                capturedQuery = queryParameters;
                return {
                  'services': [
                    {
                      'id': 'svc_search',
                      'name': 'Sports massage',
                      'category': {
                        'id': '550e8400-e29b-41d4-a716-446655440001',
                        'name': 'Wellness',
                      },
                      'owner': {
                        'id': 'uso_remote',
                        'fullName': 'Nigar Rahimova',
                      },
                      'address': {'fullAddress': '12 Seaside Ave, Baku'},
                      'ratingStats': {'avgRating': 4.9, 'reviewCount': 28},
                      'approvalMode': 'MANUAL',
                      'isAvailable': true,
                      'priceAmount': 55,
                      'description': 'Deep tissue recovery',
                    },
                  ],
                  'brands': [
                    {
                      'id': 'brand_remote',
                      'name': 'Flow House',
                      'description': 'Bodywork studio',
                      'primaryAddress': {'fullAddress': '12 Seaside Ave, Baku'},
                      'categoryIds': ['550e8400-e29b-41d4-a716-446655440001'],
                      'openNow': true,
                    },
                  ],
                  'providers': [
                    {
                      'id': 'uso_remote',
                      'fullName': 'Nigar Rahimova',
                      'description': 'Sports recovery specialist',
                      'categoryIds': ['550e8400-e29b-41d4-a716-446655440001'],
                      'availableNow': true,
                      'brands': [
                        {'id': 'brand_remote'},
                      ],
                    },
                  ],
                };
              }
              throw StateError('Unexpected GET path $path');
            },
          ),
        );

        final response = await repository.search(
          const DiscoverySearchRequest(
            query: 'massage',
            filters: SearchFilters(
              categoryId: '550e8400-e29b-41d4-a716-446655440001',
              maxPrice: 60,
              maxDistanceKm: 5,
              availableOnly: true,
            ),
            sort: SearchSort.price,
          ),
        );

        expect(capturedQuery, {
          'q': 'massage',
          'categoryId': '550e8400-e29b-41d4-a716-446655440001',
          'maxPriceAmount': 60.0,
          'radiusKm': 5.0,
          'availableOnly': true,
          'sortBy': 'PRICE_LOW',
          'limit': 25,
        });
        expect(response.services.single.id, 'svc_search');
        expect(response.brands.single.id, 'brand_remote');
        expect(response.providers.single.id, 'uso_remote');
      },
    );

    test(
      'service detail derives requestable slots from backend availability payload',
      () async {
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            responses: {
              '/services/svc_remote': {
                'service': {
                  'id': 'svc_remote',
                  'name': 'Sports massage',
                  'category': {
                    'id': '550e8400-e29b-41d4-a716-446655440001',
                    'name': 'Wellness',
                  },
                  'owner': {
                    'id': 'uso_remote',
                    'fullName': 'Nigar Rahimova',
                    'description': 'Sports recovery specialist',
                  },
                  'brand': {
                    'id': 'brand_remote',
                    'name': 'Flow House',
                    'description': 'Bodywork studio',
                    'primaryAddress': {'fullAddress': '12 Seaside Ave, Baku'},
                  },
                  'address': {'fullAddress': '12 Seaside Ave, Baku'},
                  'ratingStats': {'avgRating': 4.9, 'reviewCount': 32},
                  'approvalMode': 'MANUAL',
                  'waitingTimeMinutes': 15,
                  'freeCancellationDeadlineMinutes': 360,
                  'description':
                      'Recovery-focused session\n\nDeep tissue recovery with manual approval.',
                  'photos': [
                    {
                      'id': 'photo_1',
                      'file': {'id': 'file_1', 'originalFilename': 'room.jpg'},
                    },
                  ],
                },
              },
              '/services/svc_remote/availability': {
                'exceptions': [
                  {
                    'date': '2026-03-20T00:00:00.000Z',
                    'startTime': '18:00',
                    'endTime': '18:59',
                    'note': 'Manual approval',
                  },
                ],
              },
            },
          ),
        );

        final detail = await repository.getServiceDetail('svc_remote');

        expect(detail.summary.name, 'Sports massage');
        expect(detail.requestableSlots, isNotEmpty);
        expect(detail.requestableSlots.first.note, 'Manual approval');
        expect(detail.galleryMedia.single.id, 'photo_1');
        expect(detail.freeCancellationLabel, '6 hours before');
      },
    );

    test('provider service CRUD uses services endpoints and photo sync', () async {
      Object? createPayload;
      Object? updatePayload;
      Object? exceptionPayload;
      final photoDeletePaths = <String>[];
      final photoUploadPaths = <String>[];

      final repository = BackendDiscoveryRepository(
        apiClient: _FakeDiscoveryApiClient(
          onGet: ({required path, queryParameters}) {
            if (path == '/services') {
              final ownerId = queryParameters?['ownerUserId'];
              final brandId = queryParameters?['brandId'];
              if (ownerId == 'uso_remote' && brandId == null) {
                return {
                  'items': [
                    {
                      'id': 'svc_provider_1',
                      'name': 'Executive cleanup',
                      'category': {
                        'id': '550e8400-e29b-41d4-a716-446655440002',
                        'name': 'Barber',
                      },
                      'owner': {
                        'id': 'uso_remote',
                        'fullName': 'Rauf Mammadov',
                      },
                      'brand': {'id': 'brand_remote', 'name': 'Studio North'},
                      'address': {'fullAddress': '42 Central Ave, Baku'},
                      'approvalMode': 'MANUAL',
                      'isAvailable': true,
                      'waitingTimeMinutes': 15,
                      'minAdvanceMinutes': 120,
                      'description':
                          'Premium cleanup\n\nLonger session with extra finishing time.',
                      'photos': [
                        {
                          'id': 'photo_keep',
                          'file': {
                            'id': 'file_keep',
                            'originalFilename': 'keep.jpg',
                          },
                        },
                        {
                          'id': 'photo_remove',
                          'file': {
                            'id': 'file_remove',
                            'originalFilename': 'remove.jpg',
                          },
                        },
                      ],
                    },
                  ],
                };
              }
              throw StateError('Unexpected services query: $queryParameters');
            }
            if (path == '/services/svc_provider_1') {
              return {
                'service': {
                  'id': 'svc_provider_1',
                  'name': 'Executive cleanup',
                  'category': {
                    'id': '550e8400-e29b-41d4-a716-446655440002',
                    'name': 'Barber',
                  },
                  'owner': {'id': 'uso_remote', 'fullName': 'Rauf Mammadov'},
                  'brand': {'id': 'brand_remote', 'name': 'Studio North'},
                  'address': {'fullAddress': '42 Central Ave, Baku'},
                  'approvalMode': 'MANUAL',
                  'isAvailable': true,
                  'waitingTimeMinutes': 15,
                  'minAdvanceMinutes': 120,
                  'description':
                      'Premium cleanup\n\nLonger session with extra finishing time.',
                  'photos': [
                    {
                      'id': 'photo_keep',
                      'file': {
                        'id': 'file_keep',
                        'originalFilename': 'keep.jpg',
                      },
                    },
                    {
                      'id': 'photo_remove',
                      'file': {
                        'id': 'file_remove',
                        'originalFilename': 'remove.jpg',
                      },
                    },
                  ],
                },
              };
            }
            if (path == '/services/svc_provider_1/availability') {
              return {
                'exceptions': [
                  {
                    'date': '2026-03-20T00:00:00.000Z',
                    'startTime': '14:00',
                    'endTime': '14:59',
                  },
                ],
              };
            }
            throw StateError('Unexpected GET path $path');
          },
          onPost: ({required path, data, queryParameters}) {
            if (path == '/services') {
              createPayload = data;
              return {
                'service': {
                  'id': 'svc_created',
                  'name': 'Executive cleanup',
                  'category': {
                    'id': '550e8400-e29b-41d4-a716-446655440002',
                    'name': 'Barber',
                  },
                  'owner': {'id': 'uso_remote', 'fullName': 'Rauf Mammadov'},
                  'address': {'fullAddress': '42 Central Ave, Baku'},
                },
              };
            }
            if (path == '/services/svc_created/photos' ||
                path == '/services/svc_provider_1/photos') {
              photoUploadPaths.add(path);
              return {
                'photo': {'id': 'photo_uploaded'},
              };
            }
            throw StateError('Unexpected POST path $path');
          },
          onPatch: ({required path, data, queryParameters}) {
            updatePayload = data;
            return {
              'service': {
                'id': 'svc_provider_1',
                'name': 'Executive cleanup',
                'category': {
                  'id': '550e8400-e29b-41d4-a716-446655440002',
                  'name': 'Barber',
                },
                'owner': {'id': 'uso_remote', 'fullName': 'Rauf Mammadov'},
                'address': {'fullAddress': '42 Central Ave, Baku'},
              },
            };
          },
          onPut: ({required path, data, queryParameters}) {
            if (path == '/services/svc_provider_1/availability-exceptions') {
              exceptionPayload = data;
              return <String, dynamic>{};
            }
            throw StateError('Unexpected PUT path $path');
          },
          onDelete: ({required path, data, queryParameters}) {
            photoDeletePaths.add(path);
            return <String, dynamic>{};
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
          categoryId: '550e8400-e29b-41d4-a716-446655440002',
          categoryName: 'Barber',
          addressLine: '42 Central Ave, Baku',
          descriptionSnippet: 'Premium cleanup',
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
              startsAt: DateTime.utc(2026, 3, 20, 14),
              label: 'Fri · 14:00',
              available: true,
            ),
          ],
          exceptionNotes: const ['Closed on Sundays.'],
          galleryMedia: [
            AppMediaAsset(
              id: 'picked_1',
              label: 'Premium chair',
              source: AppMediaSource.pickedImage,
              bytes: Uint8List.fromList(const [1, 2, 3]),
            ),
          ],
          brandId: 'brand_remote',
          brandName: 'Studio North',
          price: 55,
        ),
      );

      await repository.updateProviderService(
        providerId: 'uso_remote',
        serviceId: 'svc_provider_1',
        draft: ProviderServiceDraft(
          name: 'Executive cleanup',
          categoryId: '550e8400-e29b-41d4-a716-446655440002',
          categoryName: 'Barber',
          addressLine: '42 Central Ave, Baku',
          descriptionSnippet: 'Premium cleanup',
          about: 'Updated notes.',
          approvalMode: ApprovalMode.automatic,
          isAvailable: true,
          serviceType: ManagedServiceType.solo,
          waitingTimeMinutes: 10,
          leadTimeHours: 1,
          freeCancellationHours: 2,
          visibilityLabels: const [VisibilityLabel.common],
          requestableSlots: [
            AvailabilityWindow(
              startsAt: DateTime.utc(2026, 3, 21, 11),
              label: 'Sat · 11:00',
              available: true,
            ),
          ],
          exceptionNotes: const [],
          galleryMedia: [
            const AppMediaAsset.generated(id: 'photo_keep', label: 'keep.jpg'),
            AppMediaAsset(
              id: 'picked_2',
              label: 'New setup',
              source: AppMediaSource.pickedImage,
              bytes: Uint8List.fromList(const [4, 5, 6]),
            ),
          ],
          brandId: 'brand_remote',
          brandName: 'Studio North',
          price: 60,
        ),
      );

      expect(providerServices.services.single.summary.id, 'svc_provider_1');
      expect(createdId, 'svc_created');
      expect(createPayload, isA<Map<String, dynamic>>());
      final createdMap = createPayload! as Map<String, dynamic>;
      expect(
        createdMap['address'],
        containsPair('fullAddress', '42 Central Ave, Baku'),
      );
      expect(createdMap['priceAmount'], 55.0);
      expect(createdMap['priceCurrency'], 'AZN');
      expect(photoUploadPaths, contains('/services/svc_created/photos'));
      expect(updatePayload, isA<Map<String, dynamic>>());
      expect(exceptionPayload, isA<Map<String, dynamic>>());
      expect(
        photoDeletePaths,
        contains('/services/svc_provider_1/photos/photo_remove'),
      );
      expect(photoUploadPaths, contains('/services/svc_provider_1/photos'));
    });

    test(
      'provider brand detail and brand mutations use brand endpoints',
      () async {
        Object? createPayload;
        Object? updatePayload;
        final postPaths = <String>[];
        final repository = BackendDiscoveryRepository(
          apiClient: _FakeDiscoveryApiClient(
            onGet: ({required path, queryParameters}) {
              if (path == '/service-owners' &&
                  queryParameters?['ownerUserId'] == 'uso_remote') {
                return {
                  'items': [
                    {
                      'id': 'uso_remote',
                      'fullName': 'Rauf Mammadov',
                      'brands': [
                        {'id': 'brand_remote'},
                      ],
                    },
                  ],
                };
              }
              if (path == '/brands/brand_remote') {
                return {
                  'brand': {
                    'id': 'brand_remote',
                    'name': 'Studio North',
                    'description':
                        'Minimal grooming studio\n\nPremium appointment room.\n\nMap note: Second floor above the corner cafe.',
                    'primaryAddress': {'fullAddress': '42 Central Ave, Baku'},
                  },
                };
              }
              if (path == '/brands/brand_remote/members') {
                return {
                  'items': [
                    {'id': 'uso_remote', 'fullName': 'Rauf Mammadov'},
                  ],
                };
              }
              if (path == '/brands/brand_remote/join-requests') {
                return {
                  'items': [
                    {
                      'id': 'jr_1',
                      'applicantName': 'Aysel Karimova',
                      'note': 'Ready to join the brand roster.',
                      'requestedAt': '2026-03-13T09:00:00.000Z',
                    },
                  ],
                };
              }
              if (path == '/services' &&
                  queryParameters?['brandId'] == 'brand_remote') {
                return {'items': const []};
              }
              if (path == '/brands') {
                return {
                  'items': [
                    {
                      'id': 'brand_remote',
                      'name': 'Studio North',
                      'description': 'Minimal grooming studio',
                      'primaryAddress': {'fullAddress': '42 Central Ave, Baku'},
                    },
                  ],
                };
              }
              throw StateError('Unexpected GET path $path');
            },
            onPost: ({required path, data, queryParameters}) {
              postPaths.add(path);
              if (path == '/brands') {
                createPayload = data;
                return {
                  'brand': {'id': 'brand_created', 'name': 'North Atelier'},
                };
              }
              if (path == '/brands/brand_created/logo' ||
                  path == '/brands/brand_remote/logo' ||
                  path == '/brands/brand_remote/join-requests/jr_1/accept') {
                return <String, dynamic>{};
              }
              throw StateError('Unexpected POST path $path');
            },
            onPatch: ({required path, data, queryParameters}) {
              updatePayload = data;
              return {
                'brand': {'id': 'brand_remote', 'name': 'Studio North'},
              };
            },
          ),
        );

        final brand = await repository.getProviderBrand(
          brandId: 'brand_remote',
          providerId: 'uso_remote',
        );
        final createdId = await repository.createProviderBrand(
          providerId: 'uso_remote',
          draft: ProviderBrandDraft(
            name: 'North Atelier',
            headline: 'Small premium grooming room.',
            addressLine: '42 Central Ave, Baku',
            description: 'Provider-owned brand for premium appointment flow.',
            mapHint: 'Second floor above the corner cafe.',
            visibilityLabels: const [VisibilityLabel.vip],
            openNow: true,
            logoMedia: AppMediaAsset(
              id: 'logo_1',
              label: 'NA mark',
              source: AppMediaSource.pickedImage,
              bytes: Uint8List.fromList(const [7, 8, 9]),
            ),
          ),
        );
        await repository.updateProviderBrand(
          providerId: 'uso_remote',
          brandId: 'brand_remote',
          draft: const ProviderBrandDraft(
            name: 'Studio North',
            headline: 'Minimal grooming studio',
            addressLine: '42 Central Ave, Baku',
            description: 'Premium appointment room.',
            mapHint: 'Second floor above the corner cafe.',
            visibilityLabels: [VisibilityLabel.common],
            openNow: true,
          ),
        );
        await repository.acceptBrandJoinRequest(
          providerId: 'uso_remote',
          brandId: 'brand_remote',
          requestId: 'jr_1',
        );

        expect(brand.detail.summary.id, 'brand_remote');
        expect(brand.joinRequests.single.applicantName, 'Aysel Karimova');
        expect(createdId, 'brand_created');
        expect(createPayload, containsPair('name', 'North Atelier'));
        expect(
          createPayload,
          containsPair(
            'primaryAddress',
            containsPair('fullAddress', '42 Central Ave, Baku'),
          ),
        );
        expect(updatePayload, containsPair('name', 'Studio North'));
        expect(postPaths, contains('/brands/brand_created/logo'));
        expect(
          postPaths,
          contains('/brands/brand_remote/join-requests/jr_1/accept'),
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
