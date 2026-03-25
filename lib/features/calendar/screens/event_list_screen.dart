import 'package:flutter/material.dart';

import '../widgets/calendar_widgets.dart';

class EventListScreen extends StatelessWidget {
  static const routeName = '/calendar/events';

  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda View')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => EventCard(
          title: 'Event ${index + 1}',
          subtitle: 'Agenda item details',
          time: '${9 + index}:00',
        ),
      ),
    );
  }
}
