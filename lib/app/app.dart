import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/config/app_environment.dart';
import 'package:reziphay_mobile/app/router/app_router.dart';
import 'package:reziphay_mobile/app/theme/app_theme.dart';

class ReziphayApp extends ConsumerWidget {
  const ReziphayApp({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: environment.appName,
      debugShowCheckedModeBanner: !environment.isProduction,
      theme: buildAppTheme(),
      routerConfig: router,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
