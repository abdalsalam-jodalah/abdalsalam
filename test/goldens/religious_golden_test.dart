import 'package:clock/clock.dart';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/religious/athkar_content.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/data/models/religious/prayer_times_snapshot.dart';
import 'package:abdalsalam/data/models/religious/religious_entry.dart';
import 'package:abdalsalam/features/religious/providers/athkar_providers.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_reading_providers.dart';
import 'package:abdalsalam/features/religious/providers/religious_tracking_providers.dart';
import 'package:abdalsalam/features/religious/screens/athkar_screen.dart';
import 'package:abdalsalam/features/religious/screens/religious_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../religious/religious_fakes.dart';
import 'support/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  final now = DateTime(2026, 9, 24, 8);

  PrayerTimesSnapshot buildSnapshot() {
    // `today` matches the fixed clock the "religious home" tests run under
    // (see `withClock` below), so the "Next prayer" countdown and the
    // "Updated" timestamp render deterministically.
    final today = now;
    return PrayerTimesSnapshot(
      id: 'snapshot-1',
      createdAt: now,
      updatedAt: now,
      dateKey: '2026-09-24',
      forDate: now,
      fetchedAt: today,
      sourceUrl: 'https://example.com',
      fajr: today.add(const Duration(hours: 1)),
      dhuhr: today.add(const Duration(hours: 2)),
      asr: today.add(const Duration(hours: 3)),
      maghrib: today.add(const Duration(hours: 4)),
      isha: today.add(const Duration(hours: 5)),
    );
  }

  ReligiousEntry buildEntry(String id, ReligiousEntryType type) {
    return ReligiousEntry(
      id: id,
      createdAt: now,
      updatedAt: now,
      userId: religiousDemoUserId,
      type: type,
      loggedAt: clock.now(),
      title: type == ReligiousEntryType.prayer ? 'Fajr' : 'Morning athkar',
      count: 1,
    );
  }

  PrayerLog buildPrayerLog() {
    final loggedAt = clock.now();
    return PrayerLog(
      id: 'log-1',
      createdAt: loggedAt,
      updatedAt: loggedAt,
      userId: demoUserId,
      prayerName: PrayerName.fajr,
      prayedAt: loggedAt,
      onTime: true,
    );
  }

  AthkarContent buildAthkarContent() {
    return AthkarContent(
      id: 'athkar-1',
      createdAt: now,
      updatedAt: now,
      category: AthkarCategory.morning,
      arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'Subhanallahi wa bihamdih',
      translation: 'Glory be to Allah and praise Him',
      targetCount: 33,
      isBuiltIn: true,
      isCustom: false,
      sortOrder: 0,
    );
  }

  List<Override> homeScreenOverrides() {
    return [
      religiousTrackerServiceProvider.overrideWithValue(
        FakeReligiousTrackerService(
          todayPrayerTimesResult: Success(buildSnapshot()),
          previewSourceResult: const Success(<String, DateTime>{}),
          historyResult: Success([
            buildEntry('e1', ReligiousEntryType.prayer),
            buildEntry('e2', ReligiousEntryType.athkar),
          ]),
          logEntryResult: Success(buildEntry('e3', ReligiousEntryType.prayer)),
          syncResult: Success(buildSnapshot()),
        ),
      ),
      religiousServiceProvider.overrideWithValue(
        FakeReligiousService(statisticsResult: const Success(<String, dynamic>{'currentStreak': 5})),
      ),
      prayerServiceProvider.overrideWithValue(
        FakePrayerService(
          todayLogsResult: const Success(<PrayerLog>[]),
          logPrayerResult: Success(buildPrayerLog()),
        ),
      ),
      athkarLogRepositoryProvider.overrideWithValue(
        FakeAthkarLogRepository(byUserIdResult: const Success([])),
      ),
      quranReadingServiceProvider.overrideWithValue(
        FakeQuranReadingService(
          todayReadingsResult: const Success([]),
          logReadingResult: Failure(DatabaseError('unused')),
          byDateRangeResult: const Success([]),
        ),
      ),
    ];
  }

  List<Override> athkarScreenOverrides() {
    return [
      athkarServiceProvider.overrideWithValue(
        FakeAthkarService(
          mergedResult: Success([buildAthkarContent()]),
          logCompletionResult: Failure(DatabaseError('unused')),
          addCustomAthkarResult: Failure(DatabaseError('unused')),
          deleteCustomAthkarResult: Failure(DatabaseError('unused')),
        ),
      ),
    ];
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('religious home ${brightness.name}', (tester) async {
      await withClock(Clock.fixed(now), () async {
        await setGoldenSurface(tester, const Size(430, 1400));
        await tester.pumpWidget(ProviderScope(
          overrides: homeScreenOverrides(),
          child: goldenHost(
            appearance: Appearance.defaults,
            brightness: brightness,
            child: const ReligiousHomeScreen(),
          ),
        ));
        await pumpFrames(tester);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('images/religious_home_${brightness.name}.png'),
        );
      });
    });

    testWidgets('athkar screen ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1400));
      await tester.pumpWidget(ProviderScope(
        overrides: athkarScreenOverrides(),
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const AthkarScreen(),
        ),
      ));
      await pumpFrames(tester);

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/athkar_screen_${brightness.name}.png'));
    });
  }
}
