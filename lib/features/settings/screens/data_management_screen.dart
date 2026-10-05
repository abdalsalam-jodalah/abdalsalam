import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/module_table_registry.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../sync/screens/sync_hub_screen.dart';
import '../widgets/auto_backup_settings_card.dart';
import '../widgets/settings_section_header.dart';
import 'backup_screen.dart';
import 'export_data_screen.dart';
import 'restore_screen.dart';

class DataManagementScreen extends ConsumerWidget {
  static const routeName = '/settings/data';

  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = AppThemeTokens.of(context).spacing;
    final counts = ref.watch(recordCountsByModuleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const SettingsSectionHeader('Protect your data'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NavigationTile(
                  icon: Icons.backup_outlined,
                  title: 'Back up now',
                  subtitle: 'Everything, including settings and attached files',
                  routeName: BackupScreen.routeName,
                ),
                _NavigationTile(
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Restore from backup',
                  subtitle: 'Bring your data back after a reinstall or on a new phone',
                  routeName: RestoreScreen.routeName,
                ),
                _NavigationTile(
                  icon: Icons.usb_rounded,
                  title: SyncUiText.hubTitle,
                  subtitle: SyncUiText.hubTileSubtitle,
                  routeName: SyncHubScreen.routeName,
                ),
              ],
            ),
          ),
          const SettingsSectionHeader('Automatic backup'),
          const AutoBackupSettingsCard(),
          const SettingsSectionHeader('Use your data'),
          AppCard(
            padding: EdgeInsets.zero,
            child: _NavigationTile(
              icon: Icons.table_chart_outlined,
              title: 'Export for analysis',
              subtitle: 'JSON and CSV per module, ready for spreadsheets',
              routeName: ExportDataScreen.routeName,
            ),
          ),
          const SettingsSectionHeader('Stored on this device'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final module in DataModule.values.where((module) => module != DataModule.system))
                  ListTile(
                    title: Text(module.label),
                    trailing: Text(
                      counts.maybeWhen(data: (values) => '${values[module] ?? 0}', orElse: () => '...'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String routeName;

  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).pushNamed(routeName),
    );
  }
}
