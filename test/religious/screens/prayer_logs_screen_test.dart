import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/screens/prayer_logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../religious_fakes.dart';
import 'screen_test_utils.dart';

void main() {
  testWidgets(
    "shows AsyncErrorView's friendly message (not raw text) when today's prayer logs "
    'fail to load, and Retry re-requests',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          prayerServiceProvider.overrideWithValue(
            FakePrayerService(
              todayLogsResult: Failure(DatabaseError('boom')),
              logPrayerResult: Success(_prayerLog('logged')),
            ),
          ),
          prayerRepositoryProvider.overrideWithValue(
            FakePrayerRepository(byUserIdResult: const Success(<PrayerLog>[])),
          ),
          religiousServiceProvider.overrideWithValue(
            FakeReligiousService(
              statisticsResult: const Success(<String, dynamic>{'currentStreak': 0}),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      enlargeTestSurface(tester);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PrayerLogsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(UserErrorMessages.database), findsOneWidget);
      expect(find.textContaining('DatabaseError'), findsNothing);
      expect(find.textContaining('Instance of'), findsNothing);

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Still fails (the fake always returns the same failure), but the
      // retry must not crash and must keep showing the mapped message.
      expect(find.text(UserErrorMessages.database), findsOneWidget);
    },
  );
}

PrayerLog _prayerLog(String id) {
  final now = DateTime(2026, 1, 1, 5);
  return PrayerLog(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: demoUserId,
    prayerName: PrayerName.fajr,
    prayedAt: now,
    onTime: true,
  );
}
