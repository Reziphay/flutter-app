import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const path = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _upcomingReminders = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xs),
        const SectionHeader(title: 'Settings'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              SwitchListTile(
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                },
                title: const Text('Push notifications'),
                subtitle: const Text('Reservation and status updates'),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              SwitchListTile(
                value: _upcomingReminders,
                onChanged: (value) {
                  setState(() => _upcomingReminders = value);
                },
                title: const Text('Upcoming appointment reminders'),
                subtitle: const Text('User-configurable reminder timings'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance and language'),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Light mode is the first-class target. Localization scaffolding stays ready for future ARB integration.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
