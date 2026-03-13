import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/settings/data/settings_repository.dart';
import 'package:reziphay_mobile/features/settings/models/settings_models.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const path = '/settings';

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final pushAsync = ref.watch(pushRegistrationProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        settingsAsync.when(
          data: (settings) => pushAsync.when(
            data: (pushState) => _buildContent(context, settings, pushState),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => EmptyState(
              title: 'Could not load push status',
              description: error.toString(),
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => EmptyState(
            title: 'Could not load settings',
            description: error.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppSettings settings,
    PushRegistrationState pushState,
  ) {
    final pushTone = switch (pushState.permissionStatus) {
      PushPermissionStatus.notRequested => StatusPillTone.warning,
      PushPermissionStatus.granted => StatusPillTone.success,
      PushPermissionStatus.denied => StatusPillTone.error,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Settings'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Keep notification delivery, reminder timing, and app-level preferences easy to adjust without burying the important device state.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          color: AppColors.surfaceSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Push delivery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusPill(
                    label: pushState.permissionStatus.label,
                    tone: pushTone,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                pushState.permissionStatus.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(label: 'Device token', value: pushState.tokenPreview),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                label: 'Last synced',
                value: pushState.lastSyncedAt == null
                    ? 'Not synced yet'
                    : DateFormat(
                        'MMM d, HH:mm',
                      ).format(pushState.lastSyncedAt!),
              ),
              if (!settings.pushNotificationsEnabled) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Push permission may be ready, but deliveries are paused by your local settings.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label:
                        pushState.permissionStatus ==
                            PushPermissionStatus.granted
                        ? 'Refresh permission'
                        : 'Enable push delivery',
                    expand: false,
                    isLoading: _busyAction == 'push-permission',
                    onPressed: () => _runAction(
                      'push-permission',
                      () => ref
                          .read(settingsActionsProvider)
                          .requestPushPermission(),
                      successMessage:
                          'Push delivery is enabled for this device.',
                    ),
                  ),
                  AppButton(
                    label: 'Sync device token',
                    variant: AppButtonVariant.secondary,
                    expand: false,
                    isLoading: _busyAction == 'push-sync',
                    onPressed: pushState.canSync
                        ? () => _runAction(
                            'push-sync',
                            () => ref
                                .read(settingsActionsProvider)
                                .syncPushRegistration(),
                            successMessage:
                                'Device token synced for background updates.',
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              SwitchListTile(
                value: settings.pushNotificationsEnabled,
                onChanged: (value) => _runAction(
                  'settings-push',
                  () => ref
                      .read(settingsActionsProvider)
                      .setPushNotificationsEnabled(value),
                ),
                title: const Text('Push notifications'),
                subtitle: const Text(
                  'Master toggle for device delivery of reservation updates.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              SwitchListTile(
                value: settings.reservationUpdatesEnabled,
                onChanged: settings.pushNotificationsEnabled
                    ? (value) => _runAction(
                        'settings-updates',
                        () => ref
                            .read(settingsActionsProvider)
                            .setReservationUpdatesEnabled(value),
                      )
                    : null,
                title: const Text('Reservation updates'),
                subtitle: const Text(
                  'Confirmations, rejections, cancellations, and change requests.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              SwitchListTile(
                value: settings.upcomingRemindersEnabled,
                onChanged: settings.pushNotificationsEnabled
                    ? (value) => _runAction(
                        'settings-reminders',
                        () => ref
                            .read(settingsActionsProvider)
                            .setUpcomingRemindersEnabled(value),
                      )
                    : null,
                title: const Text('Upcoming reminders'),
                subtitle: const Text(
                  'Short reminder before confirmed reservations.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reminder timing',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pick one reminder window for upcoming confirmed reservations.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: ReminderLeadTime.values
                    .map(
                      (leadTime) => ChoiceChip(
                        label: Text(leadTime.label),
                        selected: settings.reminderLeadTime == leadTime,
                        onSelected: settings.upcomingRemindersEnabled
                            ? (_) => _runAction(
                                'lead-time',
                                () => ref
                                    .read(settingsActionsProvider)
                                    .setReminderLeadTime(leadTime),
                              )
                            : null,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                settings.reminderLeadTime.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Appearance'),
                subtitle: Text(
                  settings.themePreference == 'light'
                      ? 'Light mode is the production target for MVP.'
                      : settings.themePreference,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfoSheet(
                  title: 'Appearance',
                  message:
                      'Light mode is the first-class mobile target. Theme selection stays structured here so dark mode can be added later without moving this setting.',
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: Text(
                  settings.languageCode == 'en'
                      ? 'English'
                      : settings.languageCode,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfoSheet(
                  title: 'Language',
                  message:
                      'Localization scaffolding is ready for ARB-based expansion. English remains the default language for this MVP pass.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy'),
                subtitle: const Text(
                  'Session tokens stay in secure storage and reports stay lightweight.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfoSheet(
                  title: 'Privacy',
                  message:
                      'Access and refresh tokens remain in secure storage. Non-sensitive app preferences stay local to the device. Reports submit only the issue context required for moderation review.',
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline),
                title: const Text('Help'),
                subtitle: const Text(
                  'Guidance for push delivery, reservation changes, and QR fallback.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInfoSheet(
                  title: 'Help',
                  message:
                      'If push delivery is disabled, reservation updates still appear in-app. If QR completion fails on-site, providers can still complete the reservation manually from the detail screen.',
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('Version, licensing, and app identity.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Reziphay',
                  applicationVersion: '0.1.0+1',
                  applicationLegalese: 'Reziphay mobile MVP foundation',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Log out',
          variant: AppButtonVariant.destructive,
          isLoading: _busyAction == 'logout',
          onPressed: () => _runAction(
            'logout',
            () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ),
      ],
    );
  }

  Future<void> _runAction(
    String action,
    Future<void> Function() task, {
    String? successMessage,
  }) async {
    setState(() => _busyAction = action);

    try {
      await task();

      if (!mounted || successMessage == null) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _showInfoSheet({
    required String title,
    required String message,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
