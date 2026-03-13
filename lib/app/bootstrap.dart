import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/app.dart';
import 'package:reziphay_mobile/app/config/app_environment.dart';

Future<Widget> bootstrap() async {
  final environment = AppEnvironment.fromDefines();

  return ProviderScope(
    overrides: [appEnvironmentProvider.overrideWithValue(environment)],
    child: ReziphayApp(environment: environment),
  );
}
