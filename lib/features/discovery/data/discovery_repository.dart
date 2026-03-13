import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

abstract class DiscoveryRepository {
  List<DiscoveryCategory> get categories;

  DiscoveryCategory? categoryById(String id);

  ServiceSummary? serviceSummaryById(String id);

  Future<CustomerHomeData> getCustomerHomeData();

  Future<DiscoverySearchResponse> search(DiscoverySearchRequest request);

  Future<ServiceDetail> getServiceDetail(String id);

  Future<BrandDetail> getBrandDetail(String id);

  Future<ProviderDetail> getProviderDetail(String id);
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => MockDiscoveryRepository(),
);

final discoveryCategoriesProvider = Provider<List<DiscoveryCategory>>(
  (ref) => ref.watch(discoveryRepositoryProvider).categories,
);

final discoveryCategoryProvider = Provider.family<DiscoveryCategory?, String>(
  (ref, categoryId) =>
      ref.watch(discoveryRepositoryProvider).categoryById(categoryId),
);

final customerHomeProvider = FutureProvider.autoDispose<CustomerHomeData>(
  (ref) => ref.watch(discoveryRepositoryProvider).getCustomerHomeData(),
);

final discoverySearchProvider = FutureProvider.autoDispose
    .family<DiscoverySearchResponse, DiscoverySearchRequest>(
      (ref, request) => ref.watch(discoveryRepositoryProvider).search(request),
    );

final serviceDetailProvider = FutureProvider.autoDispose
    .family<ServiceDetail, String>(
      (ref, serviceId) =>
          ref.watch(discoveryRepositoryProvider).getServiceDetail(serviceId),
    );

final brandDetailProvider = FutureProvider.autoDispose
    .family<BrandDetail, String>(
      (ref, brandId) =>
          ref.watch(discoveryRepositoryProvider).getBrandDetail(brandId),
    );

final providerDetailProvider = FutureProvider.autoDispose
    .family<ProviderDetail, String>(
      (ref, providerId) =>
          ref.watch(discoveryRepositoryProvider).getProviderDetail(providerId),
    );

class MockDiscoveryRepository implements DiscoveryRepository {
  MockDiscoveryRepository();

  @override
  final List<DiscoveryCategory> categories = const [
    DiscoveryCategory(
      id: 'barber',
      name: 'Barber',
      description: 'Haircuts, trims, grooming, and beard care.',
    ),
    DiscoveryCategory(
      id: 'dentist',
      name: 'Dentist',
      description: 'Consultations, hygiene, and long-term oral care.',
    ),
    DiscoveryCategory(
      id: 'beauty',
      name: 'Beauty',
      description: 'Facial care, skincare, and premium beauty sessions.',
    ),
    DiscoveryCategory(
      id: 'consulting',
      name: 'Consulting',
      description: 'Advisory and strategy sessions with flexible scheduling.',
    ),
    DiscoveryCategory(
      id: 'maintenance',
      name: 'Maintenance',
      description: 'On-site help and scheduled repair services.',
    ),
  ];

  final List<BrandSummary> _brands = const [
    BrandSummary(
      id: 'studio-north',
      name: 'Studio North',
      headline: 'Minimal grooming studio with strong response reliability.',
      addressLine: '28 Nizami St, Baku',
      distanceKm: 1.2,
      rating: 4.8,
      reviewCount: 214,
      serviceCount: 2,
      memberCount: 1,
      categoryIds: ['barber'],
      visibilityLabels: [VisibilityLabel.vip, VisibilityLabel.sponsored],
      popularityScore: 94,
      openNow: true,
    ),
    BrandSummary(
      id: 'luna-dental',
      name: 'Luna Dental',
      headline: 'Trusted dental brand with careful review-driven growth.',
      addressLine: '7 Fountain Sq, Baku',
      distanceKm: 2.3,
      rating: 4.9,
      reviewCount: 318,
      serviceCount: 2,
      memberCount: 1,
      categoryIds: ['dentist'],
      visibilityLabels: [VisibilityLabel.bestOfMonth],
      popularityScore: 97,
      openNow: true,
    ),
    BrandSummary(
      id: 'form-and-flare',
      name: 'Form & Flare',
      headline: 'Beauty care with a calm, appointment-first studio rhythm.',
      addressLine: '14 Tabriz St, Baku',
      distanceKm: 3.1,
      rating: 4.7,
      reviewCount: 142,
      serviceCount: 1,
      memberCount: 1,
      categoryIds: ['beauty'],
      visibilityLabels: [VisibilityLabel.common],
      popularityScore: 83,
      openNow: false,
    ),
  ];

  final List<ProviderSummary> _providers = const [
    ProviderSummary(
      id: 'rauf-mammadov',
      name: 'Rauf Mammadov',
      headline: 'Senior barber focused on dependable manual approvals.',
      bio:
          'Rauf works with a flexible calendar and keeps response times visible instead of overpromising instant automation.',
      distanceKm: 1.2,
      rating: 4.8,
      reviewCount: 196,
      completedReservations: 482,
      responseReliability: 'Responds in about 3 minutes',
      brandIds: ['studio-north'],
      categoryIds: ['barber'],
      visibilityLabels: [VisibilityLabel.vip],
      popularityScore: 92,
      availableNow: true,
    ),
    ProviderSummary(
      id: 'kamala-aliyeva',
      name: 'Kamala Aliyeva',
      headline:
          'Dentist with strong trust signals and detailed review history.',
      bio:
          'Kamala uses Reziphay to coordinate consultations and follow-up appointments while keeping her clinic workflow flexible.',
      distanceKm: 2.3,
      rating: 4.9,
      reviewCount: 264,
      completedReservations: 629,
      responseReliability: 'Usually confirms within 5 minutes',
      brandIds: ['luna-dental'],
      categoryIds: ['dentist'],
      visibilityLabels: [VisibilityLabel.bestOfMonth],
      popularityScore: 98,
      availableNow: true,
    ),
    ProviderSummary(
      id: 'aysel-karimova',
      name: 'Aysel Karimova',
      headline: 'Beauty expert with high completion and repeat-customer rates.',
      bio:
          'Aysel runs curated skincare sessions and keeps notes lightweight so reservations stay fast for both sides.',
      distanceKm: 3.1,
      rating: 4.7,
      reviewCount: 121,
      completedReservations: 271,
      responseReliability: 'Reply window usually under 4 minutes',
      brandIds: ['form-and-flare'],
      categoryIds: ['beauty'],
      visibilityLabels: [VisibilityLabel.common],
      popularityScore: 84,
      availableNow: false,
    ),
    ProviderSummary(
      id: 'emin-jafarov',
      name: 'Emin Jafarov',
      headline: 'Independent strategy consultant with self-branded services.',
      bio:
          'Emin offers session-based consulting and intentionally avoids rigid slot builders because most meetings need light negotiation.',
      distanceKm: 4.0,
      rating: 4.6,
      reviewCount: 61,
      completedReservations: 149,
      responseReliability: 'Replies within the same afternoon',
      brandIds: [],
      categoryIds: ['consulting'],
      visibilityLabels: [VisibilityLabel.common],
      popularityScore: 71,
      availableNow: true,
    ),
  ];

  final List<ServiceSummary> _services = const [
    ServiceSummary(
      id: 'classic-haircut',
      name: 'Classic haircut',
      categoryId: 'barber',
      categoryName: 'Barber',
      providerId: 'rauf-mammadov',
      providerName: 'Rauf Mammadov',
      brandId: 'studio-north',
      brandName: 'Studio North',
      addressLine: '28 Nizami St, Baku',
      distanceKm: 1.2,
      rating: 4.8,
      reviewCount: 96,
      visibilityLabels: [VisibilityLabel.vip],
      approvalMode: ApprovalMode.manual,
      isAvailable: true,
      popularityScore: 90,
      nextAvailabilityLabel: 'Today · 14:00',
      price: 38,
      descriptionSnippet:
          'Clean classic cut with a manual approval window for calendar flexibility.',
    ),
    ServiceSummary(
      id: 'precision-beard-trim',
      name: 'Precision beard trim',
      categoryId: 'barber',
      categoryName: 'Barber',
      providerId: 'rauf-mammadov',
      providerName: 'Rauf Mammadov',
      brandId: 'studio-north',
      brandName: 'Studio North',
      addressLine: '28 Nizami St, Baku',
      distanceKm: 1.2,
      rating: 4.7,
      reviewCount: 58,
      visibilityLabels: [VisibilityLabel.sponsored],
      approvalMode: ApprovalMode.automatic,
      isAvailable: true,
      popularityScore: 85,
      nextAvailabilityLabel: 'Today · 16:30',
      price: 22,
      descriptionSnippet:
          'Fast grooming service with automatic confirmation enabled.',
    ),
    ServiceSummary(
      id: 'dental-consultation',
      name: 'Dental consultation',
      categoryId: 'dentist',
      categoryName: 'Dentist',
      providerId: 'kamala-aliyeva',
      providerName: 'Kamala Aliyeva',
      brandId: 'luna-dental',
      brandName: 'Luna Dental',
      addressLine: '7 Fountain Sq, Baku',
      distanceKm: 2.3,
      rating: 4.9,
      reviewCount: 141,
      visibilityLabels: [VisibilityLabel.bestOfMonth],
      approvalMode: ApprovalMode.manual,
      isAvailable: true,
      popularityScore: 96,
      nextAvailabilityLabel: 'Tomorrow · 11:00',
      price: 55,
      descriptionSnippet:
          'Initial examination and treatment planning with manual approval.',
    ),
    ServiceSummary(
      id: 'professional-cleaning',
      name: 'Professional cleaning',
      categoryId: 'dentist',
      categoryName: 'Dentist',
      providerId: 'kamala-aliyeva',
      providerName: 'Kamala Aliyeva',
      brandId: 'luna-dental',
      brandName: 'Luna Dental',
      addressLine: '7 Fountain Sq, Baku',
      distanceKm: 2.3,
      rating: 4.8,
      reviewCount: 103,
      visibilityLabels: [VisibilityLabel.common],
      approvalMode: ApprovalMode.automatic,
      isAvailable: true,
      popularityScore: 88,
      nextAvailabilityLabel: 'Friday · 10:30',
      price: 85,
      descriptionSnippet: 'Routine hygiene care with automatic confirmation.',
    ),
    ServiceSummary(
      id: 'signature-skin-reset',
      name: 'Signature skin reset',
      categoryId: 'beauty',
      categoryName: 'Beauty',
      providerId: 'aysel-karimova',
      providerName: 'Aysel Karimova',
      brandId: 'form-and-flare',
      brandName: 'Form & Flare',
      addressLine: '14 Tabriz St, Baku',
      distanceKm: 3.1,
      rating: 4.7,
      reviewCount: 74,
      visibilityLabels: [VisibilityLabel.common],
      approvalMode: ApprovalMode.manual,
      isAvailable: false,
      popularityScore: 79,
      nextAvailabilityLabel: 'Saturday · 13:00',
      price: 74,
      descriptionSnippet:
          'Longer skincare session with provider-controlled confirmation.',
    ),
    ServiceSummary(
      id: 'strategy-session',
      name: 'Strategy session',
      categoryId: 'consulting',
      categoryName: 'Consulting',
      providerId: 'emin-jafarov',
      providerName: 'Emin Jafarov',
      addressLine: 'Remote or central Baku',
      distanceKm: 4.0,
      rating: 4.6,
      reviewCount: 36,
      visibilityLabels: [VisibilityLabel.common],
      approvalMode: ApprovalMode.manual,
      isAvailable: true,
      popularityScore: 72,
      nextAvailabilityLabel: 'Monday · 18:00',
      price: 120,
      descriptionSnippet:
          'Independent consulting with flexible requestable windows.',
    ),
  ];

  final Map<String, List<ReviewPreview>> _reviewsByEntity = const {
    'classic-haircut': [
      ReviewPreview(
        authorName: 'Murad',
        rating: 5,
        comment:
            'Clear communication and no rushed feeling. The manual approval window was still fast.',
        dateLabel: '3 days ago',
        reply:
            'Thanks. I keep manual approvals short so the schedule stays realistic.',
      ),
      ReviewPreview(
        authorName: 'Arzu',
        rating: 4.8,
        comment: 'Strong result and accurate start time.',
        dateLabel: '2 weeks ago',
      ),
    ],
    'dental-consultation': [
      ReviewPreview(
        authorName: 'Nigar',
        rating: 5,
        comment: 'Helpful explanation and calm clinic workflow.',
        dateLabel: '5 days ago',
      ),
      ReviewPreview(
        authorName: 'Javid',
        rating: 4.9,
        comment:
            'Good consultation quality and the reservation updates were clear.',
        dateLabel: '11 days ago',
      ),
    ],
    'signature-skin-reset': [
      ReviewPreview(
        authorName: 'Leyla',
        rating: 4.7,
        comment: 'Good quality session and smooth follow-up notes.',
        dateLabel: '1 week ago',
      ),
    ],
    'studio-north': [
      ReviewPreview(
        authorName: 'Amina',
        rating: 4.8,
        comment: 'Reliable team and strong service consistency.',
        dateLabel: '4 days ago',
      ),
    ],
    'luna-dental': [
      ReviewPreview(
        authorName: 'Samir',
        rating: 5,
        comment: 'Professional staff and clear appointment flow.',
        dateLabel: '6 days ago',
      ),
    ],
    'form-and-flare': [
      ReviewPreview(
        authorName: 'Rena',
        rating: 4.7,
        comment: 'The studio feels calm and intentional.',
        dateLabel: '2 weeks ago',
      ),
    ],
    'rauf-mammadov': [
      ReviewPreview(
        authorName: 'Elvin',
        rating: 4.8,
        comment: 'Great cut and honest timing.',
        dateLabel: '1 week ago',
      ),
    ],
    'kamala-aliyeva': [
      ReviewPreview(
        authorName: 'Ali',
        rating: 5,
        comment: 'Excellent communication before and during the visit.',
        dateLabel: '3 days ago',
      ),
    ],
    'aysel-karimova': [
      ReviewPreview(
        authorName: 'Sabina',
        rating: 4.7,
        comment: 'Thoughtful care and solid advice.',
        dateLabel: '9 days ago',
      ),
    ],
    'emin-jafarov': [
      ReviewPreview(
        authorName: 'Farid',
        rating: 4.6,
        comment: 'Useful session and good pre-meeting coordination.',
        dateLabel: '10 days ago',
      ),
    ],
  };

  Map<String, BrandSummary> get _brandsById => {
    for (final brand in _brands) brand.id: brand,
  };

  Map<String, ProviderSummary> get _providersById => {
    for (final provider in _providers) provider.id: provider,
  };

  Map<String, ServiceSummary> get _servicesById => {
    for (final service in _services) service.id: service,
  };

  @override
  DiscoveryCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  @override
  ServiceSummary? serviceSummaryById(String id) => _servicesById[id];

  @override
  Future<BrandDetail> getBrandDetail(String id) async {
    await _delay();

    final brand = _brandsById[id];
    if (brand == null) {
      throw const AppException('Brand not found.');
    }

    final members = _providers
        .where((provider) => provider.brandIds.contains(id))
        .toList();
    final services = _services
        .where((service) => service.brandId == id)
        .toList();

    return BrandDetail(
      summary: brand,
      description: switch (brand.id) {
        'studio-north' =>
          'Studio North keeps the grooming experience calm and intentionally lightweight. Reservations stay flexible, but response times are visible and reliable.',
        'luna-dental' =>
          'Luna Dental uses Reziphay to make discovery and coordination easier without pretending every clinical visit fits a rigid slot engine.',
        _ =>
          'Form & Flare focuses on studio-quality beauty sessions with careful review signals and clear availability communication.',
      },
      mapHint:
          'Map preview will connect to the geolocation abstraction in a later pass.',
      members: members,
      services: services,
      reviews: _reviewsByEntity[id] ?? const [],
    );
  }

  @override
  Future<CustomerHomeData> getCustomerHomeData() async {
    await _delay();

    final nearYou = List<ServiceSummary>.of(_services)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final featured = _services
        .where(
          (service) =>
              service.visibilityLabels.contains(VisibilityLabel.vip) ||
              service.visibilityLabels.contains(VisibilityLabel.sponsored),
        )
        .toList();
    final bestOfMonth = _services
        .where(
          (service) =>
              service.visibilityLabels.contains(VisibilityLabel.bestOfMonth),
        )
        .toList();
    final popularBrands = List<BrandSummary>.of(_brands)
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    final popularProviders = List<ProviderSummary>.of(_providers)
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    return CustomerHomeData(
      nearYou: nearYou.take(4).toList(),
      featured: featured.take(4).toList(),
      bestOfMonth: bestOfMonth.take(4).toList(),
      categories: categories,
      popularBrands: popularBrands.take(3).toList(),
      popularProviders: popularProviders.take(3).toList(),
    );
  }

  @override
  Future<ProviderDetail> getProviderDetail(String id) async {
    await _delay();

    final provider = _providersById[id];
    if (provider == null) {
      throw const AppException('Provider not found.');
    }

    final associatedBrands = provider.brandIds
        .map((brandId) => _brandsById[brandId])
        .whereType<BrandSummary>()
        .toList();
    final services = _services
        .where((service) => service.providerId == id)
        .toList();

    return ProviderDetail(
      summary: provider,
      associatedBrands: associatedBrands,
      services: services,
      reviews: _reviewsByEntity[id] ?? const [],
    );
  }

  @override
  Future<DiscoverySearchResponse> search(DiscoverySearchRequest request) async {
    await _delay();

    final normalizedQuery = request.query.trim().toLowerCase();

    final services =
        List<ServiceSummary>.of(_services)
            .where((service) => _matchesServiceQuery(service, normalizedQuery))
            .where(
              (service) => _matchesServiceFilters(service, request.filters),
            )
            .toList()
          ..sort((a, b) => _compareServices(a, b, request.sort));

    final brands =
        List<BrandSummary>.of(_brands)
            .where((brand) => _matchesBrandQuery(brand, normalizedQuery))
            .where((brand) => _matchesBrandFilters(brand, request.filters))
            .toList()
          ..sort((a, b) => _compareBrands(a, b, request.sort));

    final providers =
        List<ProviderSummary>.of(_providers)
            .where(
              (provider) => _matchesProviderQuery(provider, normalizedQuery),
            )
            .where(
              (provider) => _matchesProviderFilters(provider, request.filters),
            )
            .toList()
          ..sort((a, b) => _compareProviders(a, b, request.sort));

    return DiscoverySearchResponse(
      services: services,
      brands: brands,
      providers: providers,
    );
  }

  @override
  Future<ServiceDetail> getServiceDetail(String id) async {
    await _delay();

    final service = _servicesById[id];
    if (service == null) {
      throw const AppException('Service not found.');
    }

    final provider = _providersById[service.providerId];
    if (provider == null) {
      throw const AppException('Provider not found for this service.');
    }

    final brand = service.brandId == null
        ? null
        : _brandsById[service.brandId!];

    return ServiceDetail(
      summary: service,
      description:
          service.descriptionSnippet ??
          'Flexible reservation flow with clear approval messaging.',
      about: switch (service.id) {
        'classic-haircut' =>
          'A clean grooming service for customers who care about reliability more than artificial instant-booking theatrics. Manual approval keeps the provider in control of real schedule conflicts.',
        'precision-beard-trim' =>
          'Focused grooming session with lighter setup and faster turnaround. Auto approval is enabled because the provider keeps buffers elsewhere.',
        'dental-consultation' =>
          'Initial consultation, examination, and treatment direction. Manual approval helps the clinic sequence prep time and follow-ups safely.',
        'professional-cleaning' =>
          'Routine hygiene service designed for faster confirmation and lower coordination overhead.',
        'signature-skin-reset' =>
          'Longer beauty session with a more curated workflow, so the provider prefers manual approval and clearer lead-time control.',
        _ =>
          'Independent advisory session with flexible request windows. Times stay requestable because many meetings require light adjustment before confirmation.',
      },
      availabilitySummary: service.approvalMode == ApprovalMode.manual
          ? 'Selectable times remain requestable until the provider responds. If no response arrives in 5 minutes, the request expires.'
          : 'Available times can confirm immediately when still open.',
      requestableSlots: _availabilityForService(service.id),
      waitingTimeLabel: switch (service.categoryId) {
        'dentist' => '15-minute arrival tolerance',
        'beauty' => '10-minute arrival tolerance',
        'consulting' => '5-minute arrival tolerance',
        _ => '10-minute arrival tolerance',
      },
      freeCancellationLabel: switch (service.categoryId) {
        'dentist' => 'Free cancellation up to 12 hours before',
        'consulting' => 'Free cancellation up to 6 hours before',
        _ => 'Free cancellation up to 2 hours before',
      },
      galleryLabels: switch (service.id) {
        'classic-haircut' => const [
          'Studio chair',
          'Clean finish',
          'Product shelf',
        ],
        'dental-consultation' => const [
          'Clinic room',
          'Reception',
          'Care setup',
        ],
        'signature-skin-reset' => const [
          'Treatment room',
          'Lighting',
          'Product detail',
        ],
        _ => const ['Overview', 'Space', 'Result'],
      },
      provider: provider,
      brand: brand,
      reviews: _reviewsByEntity[id] ?? const [],
    );
  }

  List<AvailabilityWindow> _availabilityForService(String serviceId) {
    return switch (serviceId) {
      'classic-haircut' => [
        AvailabilityWindow(
          startsAt: _dateAt(0, 14, 0),
          label: 'Today · 14:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(0, 16, 0),
          label: 'Today · 16:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 11, 30),
          label: 'Tomorrow · 11:30',
          available: true,
        ),
      ],
      'precision-beard-trim' => [
        AvailabilityWindow(
          startsAt: _dateAt(0, 16, 30),
          label: 'Today · 16:30',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(0, 17, 0),
          label: 'Today · 17:00',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 12, 0),
          label: 'Tomorrow · 12:00',
          available: true,
        ),
      ],
      'dental-consultation' => [
        AvailabilityWindow(
          startsAt: _dateAt(1, 11, 0),
          label: 'Tomorrow · 11:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 13, 30),
          label: 'Tomorrow · 13:30',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(5, 9, 30),
          label: 'Friday · 09:30',
          available: false,
          note: 'Filled',
        ),
      ],
      'professional-cleaning' => [
        AvailabilityWindow(
          startsAt: _dateAt(5, 10, 30),
          label: 'Friday · 10:30',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(5, 12, 0),
          label: 'Friday · 12:00',
          available: true,
          note: 'Auto confirm',
        ),
      ],
      'signature-skin-reset' => [
        AvailabilityWindow(
          startsAt: _dateAt(6, 13, 0),
          label: 'Saturday · 13:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(6, 16, 0),
          label: 'Saturday · 16:00',
          available: true,
          note: 'Manual approval',
        ),
      ],
      _ => [
        AvailabilityWindow(
          startsAt: _dateAt(7, 18, 0),
          label: 'Monday · 18:00',
          available: true,
          note: 'Requestable',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(8, 10, 0),
          label: 'Tuesday · 10:00',
          available: true,
          note: 'Requestable',
        ),
      ],
    };
  }

  int _compareBrands(BrandSummary a, BrandSummary b, SearchSort sort) {
    return switch (sort) {
      SearchSort.proximity => a.distanceKm.compareTo(b.distanceKm),
      SearchSort.rating => b.rating.compareTo(a.rating),
      SearchSort.price => 0,
      SearchSort.popularity => b.popularityScore.compareTo(a.popularityScore),
      SearchSort.availability => _boolScore(
        b.openNow,
      ).compareTo(_boolScore(a.openNow)),
    };
  }

  int _compareProviders(ProviderSummary a, ProviderSummary b, SearchSort sort) {
    return switch (sort) {
      SearchSort.proximity => a.distanceKm.compareTo(b.distanceKm),
      SearchSort.rating => b.rating.compareTo(a.rating),
      SearchSort.price => 0,
      SearchSort.popularity => b.popularityScore.compareTo(a.popularityScore),
      SearchSort.availability => _boolScore(
        b.availableNow,
      ).compareTo(_boolScore(a.availableNow)),
    };
  }

  int _compareServices(ServiceSummary a, ServiceSummary b, SearchSort sort) {
    return switch (sort) {
      SearchSort.proximity => a.distanceKm.compareTo(b.distanceKm),
      SearchSort.rating => b.rating.compareTo(a.rating),
      SearchSort.price => _priceForSort(a).compareTo(_priceForSort(b)),
      SearchSort.popularity => b.popularityScore.compareTo(a.popularityScore),
      SearchSort.availability => _boolScore(
        b.isAvailable,
      ).compareTo(_boolScore(a.isAvailable)),
    };
  }

  int _boolScore(bool value) => value ? 1 : 0;

  bool _matchesBrandFilters(BrandSummary brand, SearchFilters filters) {
    if (filters.categoryId != null &&
        !brand.categoryIds.contains(filters.categoryId)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        brand.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && brand.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !brand.openNow) {
      return false;
    }
    return true;
  }

  bool _matchesBrandQuery(BrandSummary brand, String query) {
    if (query.isEmpty) {
      return true;
    }
    final haystack = [
      brand.name,
      brand.headline,
      brand.addressLine,
      ...brand.categoryIds,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  bool _matchesProviderFilters(
    ProviderSummary provider,
    SearchFilters filters,
  ) {
    if (filters.categoryId != null &&
        !provider.categoryIds.contains(filters.categoryId)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        provider.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && provider.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !provider.availableNow) {
      return false;
    }
    return true;
  }

  bool _matchesProviderQuery(ProviderSummary provider, String query) {
    if (query.isEmpty) {
      return true;
    }
    final relatedBrands = provider.brandIds
        .map((brandId) => _brandsById[brandId]?.name ?? '')
        .join(' ');
    final haystack = [
      provider.name,
      provider.headline,
      provider.bio,
      relatedBrands,
      ...provider.categoryIds,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  bool _matchesServiceFilters(ServiceSummary service, SearchFilters filters) {
    if (filters.categoryId != null &&
        service.categoryId != filters.categoryId) {
      return false;
    }
    if (filters.maxPrice != null &&
        (service.price == null || service.price! > filters.maxPrice!)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        service.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && service.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !service.isAvailable) {
      return false;
    }
    return true;
  }

  bool _matchesServiceQuery(ServiceSummary service, String query) {
    if (query.isEmpty) {
      return true;
    }
    final haystack = [
      service.name,
      service.categoryName,
      service.providerName,
      service.brandName ?? '',
      service.addressLine,
      service.descriptionSnippet ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  double _priceForSort(ServiceSummary service) =>
      service.price ?? double.maxFinite;

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 220));
}

DateTime _dateAt(int dayOffset, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
}
