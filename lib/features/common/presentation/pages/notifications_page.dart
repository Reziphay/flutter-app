import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/settings_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/notifications/data/notifications_repository.dart';
import 'package:reziphay_mobile/features/notifications/models/app_notification_models.dart';
import 'package:reziphay_mobile/features/reviews/presentation/pages/review_create_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/provider_reservation_detail_page.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  static const path = '/notifications';

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  var _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notificationsProvider);
        await ref.read(notificationsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          notificationsAsync.when(
            data: (notifications) => _buildContent(context, notifications),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => EmptyState(
              title: 'Could not load notifications',
              description: error.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AppNotification> notifications,
  ) {
    final unreadCount = notifications.where((item) => item.isUnread).length;
    final filtered = _filter == _NotificationFilter.unread
        ? notifications.where((item) => item.isUnread).toList()
        : notifications;
    final grouped = <String, List<AppNotification>>{};

    for (final notification in filtered) {
      grouped
          .putIfAbsent(notification.dayGroupLabel, () => [])
          .add(notification);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Notifications',
          actionLabel: unreadCount > 0 ? 'Mark all read' : null,
          onAction: unreadCount > 0 ? _markAllRead : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'In-app updates should stay actionable: read status, grouping, and deep-link routing need to be obvious without feeling noisy.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          color: AppColors.surfaceSoft,
          child: Row(
            children: [
              StatusPill(
                label: unreadCount == 0
                    ? 'All caught up'
                    : '$unreadCount unread',
                tone: unreadCount == 0
                    ? StatusPillTone.success
                    : StatusPillTone.info,
                icon: unreadCount == 0
                    ? Icons.done_all_outlined
                    : Icons.notifications_active_outlined,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(SettingsPage.path),
                child: const Text('Push settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _NotificationFilter.values
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (filtered.isEmpty)
          EmptyState(
            title: _filter == _NotificationFilter.unread
                ? 'No unread notifications'
                : 'No notifications yet',
            description: _filter == _NotificationFilter.unread
                ? 'New reservation updates and reminders will appear here as they arrive.'
                : 'This feed will fill with reservation events, reminders, and trust-and-safety updates.',
          )
        else
          ...grouped.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _NotificationGroup(
                label: entry.key,
                notifications: entry.value,
                onTap: _openNotification,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationsActionsProvider).markAllVisibleRead();
  }

  Future<void> _openNotification(AppNotification notification) async {
    final destination = await ref
        .read(notificationsActionsProvider)
        .openNotification(notification);
    if (!mounted) {
      return;
    }

    context.go(_locationForDestination(destination));
  }

  String _locationForDestination(NotificationDestination destination) {
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

enum _NotificationFilter { all, unread }

extension on _NotificationFilter {
  String get label => switch (this) {
    _NotificationFilter.all => 'All',
    _NotificationFilter.unread => 'Unread',
  };
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.label,
    required this.notifications,
    required this.onTap,
  });

  final String label;
  final List<AppNotification> notifications;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              for (final notification in notifications) ...[
                _NotificationRow(notification: notification, onTap: onTap),
                if (notification != notifications.last) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final AppNotification notification;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap(notification),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 12,
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              color: notification.isUnread
                  ? AppColors.primary
                  : AppColors.outlineSoft,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  notification.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusPill(
                      label: notification.type.label,
                      tone: notification.isUnread
                          ? StatusPillTone.info
                          : StatusPillTone.neutral,
                    ),
                    const Spacer(),
                    Text(
                      notification.relativeTimeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
