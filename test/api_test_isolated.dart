import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('Test localhost dashboard endpoints', () async {
    final dio = Dio();
    final endpoints = [
      '/categories',
      '/services',
      '/brands',
      '/service-owners',
    ];

    for (var endpoint in endpoints) {
      try {
        final response = await dio.get('http://localhost:3000/api/v1' + endpoint);
        print('Status ' + endpoint + ': ' + (response.statusCode?.toString() ?? 'null'));
      } on DioException catch (e) {
        print('DioException ' + endpoint + ': ' + (e.response?.statusCode?.toString() ?? 'null'));
        print('DioException Data: ' + (e.response?.data?.toString() ?? 'null'));
      }
    }
  });
}
