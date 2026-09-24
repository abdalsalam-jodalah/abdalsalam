import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/quran_progress.dart';
import 'package:abdalsalam/features/religious/providers/quran_providers.dart';
import 'package:abdalsalam/features/religious/screens/quran_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../religious_fakes.dart';

void main() {
  testWidgets(
    'a failed save shows an error SnackBar (not raw text) and keeps the form open',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          quranServiceProvider.overrideWithValue(
            FakeQuranService(
              todayProgressResult: const Success(<QuranProgress>[]),
              logProgressResult: Failure(DatabaseError('save failed')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: QuranProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Pages read'), '5');
      await tester.enterText(find.widgetWithText(TextFormField, 'Minutes spent'), '10');

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text(UserErrorMessages.database), findsOneWidget);
      expect(find.textContaining('DatabaseError'), findsNothing);
      // The dialog stays open on failure — no pop, no silent success.
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );
}
