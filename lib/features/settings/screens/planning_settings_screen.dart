import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../widgets/settings_section_header.dart';

class PlanningSettingsScreen extends StatelessWidget {
  static const routeName = '/settings/planning';

  const PlanningSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Scaffold(
      appBar: AppBar(title: const Text('Planning')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const SettingsSectionHeader('Life & day planning'),
          const AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: Text('No planning-specific settings yet'),
              subtitle: Text(
                'Goals, reviews, and daily/life planning structure are managed within the Planning module itself',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
