import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(title: Text('Appearance'), subtitle: Text('Theme, language, first day of week')),
          ListTile(title: Text('Notifications'), subtitle: Text('Per-module preferences')),
          ListTile(title: Text('Backup & Restore'), subtitle: Text('Manage backups and restore data')),
          ListTile(title: Text('Dashboard Customization'), subtitle: Text('Card order and visibility')),
        ],
      ),
    );
  }
}
