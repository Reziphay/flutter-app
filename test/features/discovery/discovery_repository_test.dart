import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

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
}
