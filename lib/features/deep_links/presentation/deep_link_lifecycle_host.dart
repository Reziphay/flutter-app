import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/router/app_router.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/auth/session_state.dart';
import 'package:reziphay_mobile/features/deep_links/data/deep_link_actions.dart';
import 'package:reziphay_mobile/features/deep_links/data/deep_link_service.dart';

class DeepLinkLifecycleHost extends ConsumerStatefulWidget {
  const DeepLinkLifecycleHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DeepLinkLifecycleHost> createState() =>
      _DeepLinkLifecycleHostState();
}

class _DeepLinkLifecycleHostState extends ConsumerState<DeepLinkLifecycleHost> {
  StreamSubscription<Uri>? _linkSubscription;
  final Set<String> _handledLinks = <String>{};
  bool _started = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_start);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _start() async {
    if (_started) {
      return;
    }
    _started = true;

    final service = ref.read(deepLinkServiceProvider);
    await service.initialize();

    final initialUri = await service.getInitialUri();
    if (initialUri != null) {
      await _handleUri(initialUri);
    }

    _linkSubscription = service.uriStream.listen((uri) {
      unawaited(_handleUri(uri));
    });
  }

  Future<void> _handleUri(Uri uri) async {
    final key = uri.toString();
    if (_handledLinks.contains(key)) {
      return;
    }
    _handledLinks.add(key);
    if (_handledLinks.length > 12) {
      _handledLinks.remove(_handledLinks.first);
    }

    await _waitForBootstrapReady();
    final location = await ref
        .read(deepLinkActionsProvider)
        .locationForUri(uri);
    if (!mounted || location == null) {
      return;
    }

    ref.read(goRouterProvider).go(location);
  }

  Future<void> _waitForBootstrapReady() async {
    for (var attempt = 0; attempt < 40; attempt += 1) {
      if (!mounted) {
        return;
      }
      final status = ref.read(sessionControllerProvider).bootstrapStatus;
      if (status == BootstrapStatus.ready) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 75));
    }
  }
}
