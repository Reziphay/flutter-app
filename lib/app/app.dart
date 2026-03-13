import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/config/app_environment.dart';
import 'package:reziphay_mobile/app/router/app_router.dart';
import 'package:reziphay_mobile/app/theme/app_theme.dart';
import 'package:reziphay_mobile/features/deep_links/presentation/deep_link_lifecycle_host.dart';
import 'package:reziphay_mobile/features/push/presentation/push_lifecycle_host.dart';

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
      builder: (context, child) => DeepLinkLifecycleHost(
        child: PushLifecycleHost(child: child ?? const SizedBox.shrink()),
      ),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
