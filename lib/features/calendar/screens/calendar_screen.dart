import 'package:flutter/material.dart';

import '../widgets/calendar_widgets.dart';
import 'event_form_screen.dart';
import 'event_list_screen.dart';
import 'google_calendar_sync_screen.dart';
import 'unified_timeline_screen.dart';

class CalendarScreen extends StatefulWidget {
  static const routeName = '/calendar';

  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sampleDays = <DateTime>{
      DateTime.now(),
      DateTime.now().add(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 3)),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Integration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Month'),
            Tab(text: 'Week'),
            Tab(text: 'Day'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(EventFormScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CalendarGrid(
                selectedMonth: _selectedMonth,
                daysWithEvents: sampleDays,
                onDaySelected: (day) => setState(() => _selectedDay = day),
              ),
              const SizedBox(height: 12),
              Text('Selected: ${_selectedDay.toLocal()}'.split(' ').first),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Agenda View'),
                    onPressed: () => Navigator.of(context).pushNamed(EventListScreen.routeName),
                  ),
                  ActionChip(
                    label: const Text('Unified Timeline'),
                    onPressed: () => Navigator.of(context).pushNamed(UnifiedTimelineScreen.routeName),
                  ),
                  ActionChip(
                    label: const Text('Google Sync'),
                    onPressed: () => Navigator.of(context).pushNamed(GoogleCalendarSyncScreen.routeName),
                  ),
                ],
              ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              EventCard(title: 'Team Sync', subtitle: 'Weekly planning', time: 'Mon 10:00'),
              SizedBox(height: 8),
              EventCard(title: 'Workout', subtitle: 'Leg day session', time: 'Tue 19:00'),
              SizedBox(height: 8),
              EventCard(title: 'Family Visit', subtitle: 'Dinner', time: 'Thu 20:00'),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              EventCard(title: 'Fajr Reminder', subtitle: 'Prayer schedule', time: '05:00'),
              SizedBox(height: 8),
              EventCard(title: 'Medication', subtitle: 'After breakfast', time: '08:30'),
              SizedBox(height: 8),
              EventCard(title: 'Todo Due', subtitle: 'Project review', time: '16:00'),
            ],
          ),
        ],
      ),
    );
  }
}
