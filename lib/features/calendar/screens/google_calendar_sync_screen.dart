import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Google Calendar Sync')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SyncStatusIndicator(enabled: _enabled),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _enabled,
              title: const Text('Enable Google Calendar Sync'),
              subtitle: const Text('Pull and push events from/to Google Calendar.'),
              onChanged: (value) => setState(() => _enabled = value),
            ),
          ],
        ),
      ),
    );
  }
}
