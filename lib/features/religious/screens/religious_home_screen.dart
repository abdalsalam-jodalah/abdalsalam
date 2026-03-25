import 'package:flutter/material.dart';

import '../widgets/prayer_calendar_heatmap.dart';
import '../widgets/prayer_streak_widget.dart';
import '../widgets/prayer_time_card.dart';
import '../widgets/quran_progress_chart.dart';
import 'prayer_log_screen.dart';
import 'prayer_logs_screen.dart';
import 'quran_reading_screen.dart';
import 'quran_progress_screen.dart';
import 'spiritual_progress_screen.dart';

class ReligiousHomeScreen extends StatelessWidget {
  static const routeName = '/religious';

  const ReligiousHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Religious Tracking')),
      body: ListView(
        key: const ValueKey('religious-home'),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(PrayerLogScreen.routeName),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Log Prayer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(QuranReadingScreen.routeName),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Quran Reading'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const PrayerStreakWidget(streakDays: 6),
          const SizedBox(height: 12),
          Text('Today Prayer Times', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          PrayerTimeCard(prayerName: 'Fajr', time: DateTime(today.year, today.month, today.day, 5, 7)),
          PrayerTimeCard(prayerName: 'Dhuhr', time: DateTime(today.year, today.month, today.day, 12, 19)),
          PrayerTimeCard(prayerName: 'Asr', time: DateTime(today.year, today.month, today.day, 15, 44)),
          PrayerTimeCard(prayerName: 'Maghrib', time: DateTime(today.year, today.month, today.day, 18, 11)),
          PrayerTimeCard(prayerName: 'Isha', time: DateTime(today.year, today.month, today.day, 19, 34)),
          const SizedBox(height: 12),
          const QuranProgressChart(totalAyahsRead: 1240, surahsCompleted: 8),
          const SizedBox(height: 12),
          PrayerCalendarHeatmap(
            dailyCompletions: {
              for (var i = 0; i < 30; i++)
                today.subtract(Duration(days: i)): 2 + (i % 4),
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(SpiritualProgressScreen.routeName),
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('Open Spiritual Journal'),
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> shortcuts(BuildContext context) {
    return <Widget>[
      ListTile(
        leading: const Icon(Icons.access_time),
        title: const Text('Prayer Logs'),
        onTap: () => Navigator.of(context).pushNamed(PrayerLogsScreen.routeName),
      ),
      ListTile(
        leading: const Icon(Icons.menu_book),
        title: const Text('Quran Reading'),
        onTap: () => Navigator.of(context).pushNamed(QuranProgressScreen.routeName),
      ),
      ListTile(
        leading: const Icon(Icons.auto_stories_outlined),
        title: const Text('Spiritual Journal'),
        onTap: () => Navigator.of(context).pushNamed(SpiritualProgressScreen.routeName),
      ),
    ];
  }
}
