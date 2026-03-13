import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const path = '/notifications';

  @override
  Widget build(BuildContext context) {
    final notifications = const [
      (
        title: 'Reservation confirmed',
        body: 'Your barber reservation for Friday at 14:00 was approved.',
        time: '2m ago',
        unread: true,
      ),
      (
        title: 'Upcoming appointment',
        body:
            'Reminder settings will route here once notification preferences are wired.',
        time: 'Yesterday',
        unread: false,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xs),
        const SectionHeader(title: 'Notifications'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              for (final notification in notifications) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: notification.unread
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
                          Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            notification.body,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              StatusPill(
                                label: notification.unread ? 'Unread' : 'Read',
                                tone: notification.unread
                                    ? StatusPillTone.info
                                    : StatusPillTone.neutral,
                              ),
                              const Spacer(),
                              Text(
                                notification.time,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
