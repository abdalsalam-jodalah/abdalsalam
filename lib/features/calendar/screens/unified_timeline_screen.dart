import 'package:flutter/material.dart';

import '../widgets/calendar_widgets.dart';

class UnifiedTimelineScreen extends StatelessWidget {
  static const routeName = '/calendar/timeline';

  const UnifiedTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unified Timeline')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TimelineView(
          items: const [
            EventCard(title: 'Prayer Reminder', subtitle: 'Maghrib in 10 minutes', time: '18:12'),
            EventCard(title: 'Workout Session', subtitle: 'Push day', time: '19:00'),
            EventCard(title: 'Medication', subtitle: 'Vitamin D dose', time: '21:00'),
          ],
        ),
      ),
    );
  }
}
