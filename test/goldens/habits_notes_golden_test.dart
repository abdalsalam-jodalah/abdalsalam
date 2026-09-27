import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/habits/habit.dart';
import 'package:abdalsalam/data/models/habits/habit_log.dart';
import 'package:abdalsalam/data/models/notes/note.dart';
import 'package:abdalsalam/features/habits/providers/habits_providers.dart';
import 'package:abdalsalam/features/habits/screens/habit_detail_screen.dart';
import 'package:abdalsalam/features/habits/screens/habits_home_screen.dart';
import 'package:abdalsalam/features/notes/providers/notes_providers.dart';
import 'package:abdalsalam/features/notes/screens/notes_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  final goodHabit = Habit(
    id: 'habit-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userId: 'u1',
    name: 'Read Quran',
    description: 'Ten pages a day',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    reminderTime: null,
    icon: 'book',
    color: '#2196F3',
    category: 'Spiritual',
    isGoodHabit: true,
  );
  final badHabit = Habit(
    id: 'habit-2',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userId: 'u1',
    name: 'Late night snacking',
    description: '',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    reminderTime: null,
    icon: 'warning',
    color: '#F97316',
    category: 'Health',
    isGoodHabit: false,
  );
  final habitLog = HabitLog(
    id: 'log-1',
    createdAt: DateTime(2026, 9, 20, 8, 30),
    updatedAt: DateTime(2026, 9, 20, 8, 30),
    userId: 'u1',
    habitId: goodHabit.id,
    completedAt: DateTime(2026, 9, 20, 8, 30),
    mood: 'Good',
    notes: 'Felt focused',
  );
  final habitStats = <String, dynamic>{
    'currentStreak': 5,
    'bestStreak': 12,
    'completionRateThisMonth': 80.0,
    'totalLogs': 24,
  };

  final notes = <Note>[
    Note(
      id: 'note-1',
      createdAt: DateTime(2026, 9, 18),
      updatedAt: DateTime(2026, 9, 18),
      userId: 'u1',
      title: 'Weekly plan',
      content: 'Focus on Quran reading and workout consistency this week.',
      tags: const [],
      categoryId: null,
      pinned: false,
      archived: false,
      attachments: const [],
      color: 'yellow',
      order: 0,
    ),
    Note(
      id: 'note-2',
      createdAt: DateTime(2026, 9, 19),
      updatedAt: DateTime(2026, 9, 19),
      userId: 'u1',
      title: 'Budget note',
      content: 'Reduce transport spending this month.',
      tags: const [],
      categoryId: null,
      pinned: false,
      archived: false,
      attachments: const [],
      color: null,
      order: 1,
    ),
  ];

  List<Override> habitsHomeOverrides() => [
        activeHabitsProvider.overrideWith((ref) async => [goodHabit, badHabit]),
        habitStatisticsProvider.overrideWith((ref, habitId) async => habitStats),
        logsForHabitProvider.overrideWith((ref, habitId) async => habitId == goodHabit.id ? [habitLog] : []),
      ];

  List<Override> habitDetailOverrides() => [
        activeHabitsProvider.overrideWith((ref) async => [goodHabit]),
        habitByIdProvider.overrideWith((ref, habitId) async => goodHabit),
        logsForHabitProvider.overrideWith((ref, habitId) async => [habitLog]),
        habitStatisticsProvider.overrideWith((ref, habitId) async => habitStats),
      ];

  List<Override> notesHomeOverrides() => [
        activeNotesProvider.overrideWith((ref) async => notes),
      ];

  Future<void> pumpGolden(
    WidgetTester tester, {
    required List<Override> overrides,
    required Widget child,
    required Appearance appearance,
    required Brightness brightness,
    Size size = const Size(430, 1200),
  }) async {
    await setGoldenSurface(tester, size);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: goldenHost(appearance: appearance, brightness: brightness, child: child),
    ));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('habits home ${brightness.name}', (tester) async {
      await pumpGolden(
        tester,
        overrides: habitsHomeOverrides(),
        child: const HabitsHomeScreen(),
        appearance: Appearance.defaults,
        brightness: brightness,
      );

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/habits_home_${brightness.name}.png'));
    });

    testWidgets('habit detail ${brightness.name}', (tester) async {
      await pumpGolden(
        tester,
        overrides: habitDetailOverrides(),
        child: const HabitDetailScreen(habitId: 'habit-1'),
        appearance: Appearance.defaults,
        brightness: brightness,
        size: const Size(430, 1600),
      );

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/habit_detail_${brightness.name}.png'));
    });

    testWidgets('notes home ${brightness.name}', (tester) async {
      await pumpGolden(
        tester,
        overrides: notesHomeOverrides(),
        child: const NotesHomeScreen(),
        appearance: Appearance.defaults,
        brightness: brightness,
      );

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/notes_home_${brightness.name}.png'));
    });
  }
}
