// lib/features/sync/screens/sync_hub_screen.dart — entry screen of USB device sync, switching on the platform role.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sync_constants.dart';
import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../providers/sync_providers.dart';
import '../services/sync_platform_role.dart';
import '../widgets/sync_host_panel.dart';
import '../widgets/sync_join_panel.dart';

class SyncHubScreen extends ConsumerWidget {
  static const routeName = SyncConstants.routeName;

  const SyncHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(syncPlatformRoleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(SyncUiText.hubTitle)),
      body: switch (role) {
        SyncPlatformRole.host => const SyncHostPanel(),
        SyncPlatformRole.client => const SyncJoinPanel(),
        SyncPlatformRole.unsupported => const _UnsupportedPlatformMessage(),
      },
    );
  }
}

class _UnsupportedPlatformMessage extends StatelessWidget {
  const _UnsupportedPlatformMessage();

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(SyncUiText.unsupportedTitle, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            SizedBox(height: spacing.sm),
            const Text(SyncUiText.unsupportedMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
