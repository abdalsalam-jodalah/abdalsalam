import 'package:flutter/material.dart';

import '../widgets/settings_section_header.dart';

class PlanningSettingsScreen extends StatelessWidget {
  static const routeName = '/settings/planning';

  const PlanningSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planning')),
      body: ListView(
        children: const [
          SettingsSectionHeader('Life & day planning'),
          ListTile(
            title: Text('No planning-specific settings yet'),
            subtitle: Text('Goals, reviews, and daily/life planning structure are managed within the Planning module itself'),
          ),
        ],
      ),
    );
  }
}
