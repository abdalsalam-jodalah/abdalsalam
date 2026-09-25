import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';

class DashboardStatusChips extends ConsumerWidget {
  static const int _lowBatteryLevel = 20;
  static const String _offlineLabel = 'Offline';
  static const String _onlineLabel = 'Online';

  const DashboardStatusChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final isOffline = ref.watch(isOfflineProvider);
    final battery = ref.watch(batteryInfoProvider);
    return Wrap(
      spacing: tokens.spacing.sm,
      children: [
        Chip(
          avatar: Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
            color: isOffline ? tokens.colors.warning : tokens.colors.success,
          ),
          label: Text(isOffline ? _offlineLabel : _onlineLabel),
        ),
        ...battery.maybeWhen(
          data: (info) {
            final level = info.batteryLevel ?? 0;
            final isLow = level < _lowBatteryLevel;
            return [
              Chip(
                avatar: Icon(
                  isLow ? Icons.battery_alert_rounded : Icons.battery_full_rounded,
                  color: isLow ? tokens.colors.danger : tokens.colors.success,
                ),
                label: Text('$level%'),
              ),
            ];
          },
          orElse: () => const <Widget>[],
        ),
      ],
    );
  }
}
