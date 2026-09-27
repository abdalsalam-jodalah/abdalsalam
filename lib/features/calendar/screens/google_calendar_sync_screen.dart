import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../widgets/calendar_widgets.dart';

class GoogleCalendarSyncScreen extends StatefulWidget {
  static const routeName = '/calendar/google-sync';

  const GoogleCalendarSyncScreen({super.key});

  @override
  State<GoogleCalendarSyncScreen> createState() => _GoogleCalendarSyncScreenState();
}

class _GoogleCalendarSyncScreenState extends State<GoogleCalendarSyncScreen> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Google Calendar Sync')),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [
          SyncStatusIndicator(enabled: _enabled),
          SizedBox(height: tokens.spacing.md),
          SwitchListTile(
            value: _enabled,
            title: const Text('Enable Google Calendar Sync'),
            subtitle: const Text('Pull and push events from/to Google Calendar.'),
            onChanged: (value) => setState(() => _enabled = value),
          ),
        ],
      ),
    );
  }
}
