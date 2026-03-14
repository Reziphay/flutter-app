import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/customer_home_page.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/search_page.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

void main() {
  testWidgets('Load search page to trigger error logs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => MockSessionController()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SearchPage()),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1)); // wait for riverpod
    await tester.pumpAndSettle(); // flush animations
  });
}

class MockSessionController extends SessionController {
  @override
  UserSession? get session => null;
  
  @override
  Future<UserSession?> ensureFreshSession({bool force = false}) async {
      return null;
  }
}
