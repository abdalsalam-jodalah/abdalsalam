import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/screens/backup_screen.dart';
import '../../providers/app_providers.dart';

class BackupReminderBanner extends ConsumerStatefulWidget {
  static const String _backUpLabel = 'Back up';
  static const String _dismissLabel = 'Dismiss until next launch';
  static const double _horizontalPadding = 12;
  static const double _verticalPadding = 6;
  static const double _iconSpacing = 8;

  final GlobalKey<NavigatorState> navigatorKey;

  const BackupReminderBanner({super.key, required this.navigatorKey});

  static String messageFor(int daysOverdue) {
    return daysOverdue == 1
        ? 'No backup saved outside the app for 1 day. Back up so your data survives a reinstall.'
        : 'No backup saved outside the app for $daysOverdue days. Back up so your data survives a reinstall.';
  }

  @override
  ConsumerState<BackupReminderBanner> createState() => _BackupReminderBannerState();
}

class _BackupReminderBannerState extends ConsumerState<BackupReminderBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final daysOverdue = ref.watch(backupReminderDaysProvider).valueOrNull;
    if (_isDismissed || daysOverdue == null) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BackupReminderBanner._horizontalPadding,
            vertical: BackupReminderBanner._verticalPadding,
          ),
          child: Row(
            children: [
              Icon(Icons.backup_outlined, color: colorScheme.onSecondaryContainer),
              const SizedBox(width: BackupReminderBanner._iconSpacing),
              Expanded(
                child: Text(
                  BackupReminderBanner.messageFor(daysOverdue),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondaryContainer),
                ),
              ),
              TextButton(
                onPressed: () => widget.navigatorKey.currentState?.pushNamed(BackupScreen.routeName),
                child: const Text(BackupReminderBanner._backUpLabel),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSecondaryContainer,
                  semanticLabel: BackupReminderBanner._dismissLabel,
                ),
                onPressed: () => setState(() => _isDismissed = true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
