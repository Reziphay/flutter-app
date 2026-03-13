import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/notifications/models/app_notification_models.dart';
import 'package:reziphay_mobile/features/reviews/presentation/pages/review_create_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/provider_reservation_detail_page.dart';

final notificationNavigationActionsProvider =
    Provider<NotificationNavigationActions>(
      (ref) => NotificationNavigationActions(ref),
    );

class NotificationNavigationActions {
  NotificationNavigationActions(this.ref);

  final Ref ref;

  Future<NotificationDestination> prepareDestination(
    NotificationDestination destination,
  ) async {
    final session = ref.read(sessionControllerProvider).session;
    if (session != null &&
        session.availableRoles.contains(destination.role) &&
        session.activeRole != destination.role) {
      await ref
          .read(sessionControllerProvider.notifier)
          .switchRole(destination.role);
    }

    return destination;
  }

  String locationForDestination(NotificationDestination destination) {
    return switch (destination.type) {
      NotificationDestinationType.customerReservation =>
        CustomerReservationDetailPage.location(destination.entityId),
      NotificationDestinationType.providerReservation =>
        ProviderReservationDetailPage.location(destination.entityId),
      NotificationDestinationType.service => ServiceDetailPage.location(
        destination.entityId,
      ),
      NotificationDestinationType.provider => ProviderDetailPage.location(
        destination.entityId,
      ),
      NotificationDestinationType.brand => BrandDetailPage.location(
        destination.entityId,
      ),
      NotificationDestinationType.reviewCreate => ReviewCreatePage.location(
        destination.entityId,
      ),
    };
  }
}
