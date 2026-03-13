import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/router/app_router.dart';
import 'package:reziphay_mobile/features/notifications/data/notification_navigation.dart';
import 'package:reziphay_mobile/features/notifications/data/notifications_repository.dart';
import 'package:reziphay_mobile/features/push/data/push_messaging_service.dart';
import 'package:reziphay_mobile/features/settings/data/settings_repository.dart';

class PushLifecycleHost extends ConsumerStatefulWidget {
  const PushLifecycleHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PushLifecycleHost> createState() => _PushLifecycleHostState();
}

class _PushLifecycleHostState extends ConsumerState<PushLifecycleHost> {
  StreamSubscription<PushInboundEvent>? _inboundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_start);
  }

  @override
  void dispose() {
    _inboundSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
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

    final pushService = ref.read(pushMessagingServiceProvider);
    await pushService.initialize();

    _tokenRefreshSubscription = pushService.tokenRefreshes.listen((_) {
      unawaited(_syncPushRegistration());
    });

    _inboundSubscription = pushService.inboundEvents.listen((event) {
      if (!mounted) {
        return;
      }

      ref.invalidate(notificationsProvider);

      if (event.source == PushInboundEventSource.foreground) {
        _showForegroundBanner(event);
        return;
      }

      unawaited(_openDestination(event));
    });

    await _syncPushRegistration();

    final initialEvent = await pushService.takeInitialEvent();
    if (initialEvent != null && mounted) {
      await _openDestination(initialEvent);
    }
  }

  Future<void> _openDestination(PushInboundEvent event) async {
    final navigation = ref.read(notificationNavigationActionsProvider);
    final destination = await navigation.prepareDestination(event.destination);
    if (!mounted) {
      return;
    }

    ref
        .read(goRouterProvider)
        .go(navigation.locationForDestination(destination));
  }

  void _showForegroundBanner(PushInboundEvent event) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(event.title),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            unawaited(_openDestination(event));
          },
        ),
      ),
    );
  }

  Future<void> _syncPushRegistration() async {
    try {
      await ref.read(settingsRepositoryProvider).syncPushRegistration();
      ref.invalidate(pushRegistrationProvider);
    } catch (_) {}
  }
}
