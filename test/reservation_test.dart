import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';

void main() {
  test('parse API payload', () async {
      final payload = await File('/tmp/test_api_reservations.json').readAsString();
      final Map<String, dynamic> jsonResponse = jsonDecode(payload);
      final envelope = unwrapResponseEnvelope(jsonResponse);
      final repo = BackendReservationsRepository(
         apiClient: ApiClient(Dio()),
         discoveryRepository: BackendDiscoveryRepository(apiClient: ApiClient(Dio())),
         readSession: () => null,
      );
      try {
         repo.testParseCustomerReservations(envelope);
         print('Parsed search response payload successfully.');
      } catch (e, st) {
         print('Fail: $e\n$st');
         rethrow;
      }
  });
}
