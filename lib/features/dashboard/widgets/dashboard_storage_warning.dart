import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

class DashboardStorageWarning extends ConsumerWidget {
  static const double lowStoragePercentage = 90;
  static const String _fallbackMessage = 'Storage is running low.';

  const DashboardStorageWarning({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLow = ref.watch(storageInfoProvider).maybeWhen(
          data: (info) => info.usagePercentage >= lowStoragePercentage,
          orElse: () => false,
        );
    if (!isLow) {
      return const SizedBox.shrink();
    }
    final tokens = AppThemeTokens.of(context);
    final stateAware = ref.watch(stateAwareServiceProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.md),
      child: AppCard(
        accentColor: tokens.colors.danger,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: Icons.sd_storage_rounded, color: tokens.colors.danger),
            SizedBox(width: tokens.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stateAware.storageWarningMessage() ?? _fallbackMessage,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: tokens.spacing.xs),
                  for (final tip in stateAware.cleanupSuggestions())
                    Text('• $tip', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
