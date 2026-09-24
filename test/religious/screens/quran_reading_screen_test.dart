import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/quran_reading.dart';
import 'package:abdalsalam/features/religious/providers/quran_reading_providers.dart';
import 'package:abdalsalam/features/religious/screens/quran_reading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../religious_fakes.dart';

Future<void> _openAddDialog(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

void main() {
  ProviderContainer buildContainer() => ProviderContainer(
        overrides: [
          quranReadingServiceProvider.overrideWithValue(
            FakeQuranReadingService(
              todayReadingsResult: const Success(<QuranReading>[]),
              logReadingResult: Failure(DatabaseError('should never be called')),
              byDateRangeResult: const Success(<QuranReading>[]),
            ),
          ),
          quranReadingRepositoryProvider.overrideWithValue(
            FakeQuranReadingRepository(
              byUserIdResult: const Success(<QuranReading>[]),
              byDateRangeResult: const Success(<QuranReading>[]),
            ),
          ),
        ],
      );

  testWidgets('rejects surah 0 and does not call the save service', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: QuranReadingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await _openAddDialog(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Surah number (1-114)'),
      '0',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Ayah from'), '1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ayah to'), '1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Pages read'), '1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Minutes spent'), '1');

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Surah number must be at least 1'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('rejects empty required fields and does not call the save service', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: QuranReadingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await _openAddDialog(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Surah number is required'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
