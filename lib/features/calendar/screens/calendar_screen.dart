import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/month_heatmap.dart';
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
  static const String _moduleKey = 'calendar';

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

  bool _hasEvent(DateTime day, Set<DateTime> daysWithEvents) {
    return daysWithEvents.any(
      (item) => item.year == day.year && item.month == day.month && item.day == day.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule(_moduleKey);
    final textTheme = Theme.of(context).textTheme;
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
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              AppCard(
                accentColor: accent,
                child: MonthHeatmap(
                  month: _selectedMonth,
                  intensityForDay: (day) => _hasEvent(day, sampleDays) ? 1.0 : 0.0,
                  onDayTap: (day) => setState(() => _selectedDay = day),
                  color: accent,
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              Text(
                'Selected: ${AppDateFormatter.date(_selectedDay)}',
                style: textTheme.bodyMedium,
              ),
              SizedBox(height: tokens.spacing.md),
              Wrap(
                spacing: tokens.spacing.sm,
                runSpacing: tokens.spacing.sm,
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
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              EntityTile(
                icon: Icons.event_rounded,
                accentColor: accent,
                title: 'Team Sync',
                subtitle: 'Weekly planning',
                trailing: Text('Mon 10:00', style: textTheme.labelLarge),
              ),
              SizedBox(height: tokens.spacing.sm),
              EntityTile(
                icon: Icons.event_rounded,
                accentColor: accent,
                title: 'Workout',
                subtitle: 'Leg day session',
                trailing: Text('Tue 19:00', style: textTheme.labelLarge),
              ),
              SizedBox(height: tokens.spacing.sm),
              EntityTile(
                icon: Icons.event_rounded,
                accentColor: accent,
                title: 'Family Visit',
                subtitle: 'Dinner',
                trailing: Text('Thu 20:00', style: textTheme.labelLarge),
              ),
            ],
          ),
          ListView(
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              EntityTile(
                icon: Icons.event_rounded,
                accentColor: accent,
                title: 'Fajr Reminder',
                subtitle: 'Prayer schedule',
                trailing: Text('05:00', style: textTheme.labelLarge),
              ),
              SizedBox(height: tokens.spacing.sm),
              EntityTile(
                icon: Icons.event_rounded,
                accentColor: accent,
                title: 'Medication',
                subtitle: 'After breakfast',
                trailing: Text('08:30', style: textTheme.labelLarge),
              ),
              SizedBox(height: tokens.spacing.sm),
              EntityTile(
                icon: Icons.event_rounded,
                accentColor: accent,
                title: 'Todo Due',
                subtitle: 'Project review',
                trailing: Text('16:00', style: textTheme.labelLarge),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
