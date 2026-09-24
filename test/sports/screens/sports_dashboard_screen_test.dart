import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sports/body_measurement.dart';
import 'package:abdalsalam/features/sports/providers/sports_providers.dart';
import 'package:abdalsalam/features/sports/screens/sports_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sports_fakes.dart';

class _FailingCreateBodyMeasurementRepository extends FakeBodyMeasurementRepository {
  @override
  Future<Result<BodyMeasurement, AppError>> create(BodyMeasurement entity) async =>
      Failure(fakeSportsStorageFailure());
}

void main() {
  const databaseErrorMessage = 'Your data could not be saved or loaded. Please try again.';

  testWidgets('activity card shows a mapped error via AsyncErrorView and retries on tap', (tester) async {
    final logRepo = FakeExerciseLogRepository()..shouldFailGetByDateRange = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseLogRepositoryProvider.overrideWithValue(logRepo),
          exerciseCategoryRepositoryProvider.overrideWithValue(FakeExerciseCategoryRepository()),
          exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository()),
          bodyMeasurementRepositoryProvider.overrideWithValue(FakeBodyMeasurementRepository()),
        ],
        child: const MaterialApp(home: SportsDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(databaseErrorMessage), findsOneWidget);
    expect(find.text('fake sports storage failure'), findsNothing);

    logRepo.shouldFailGetByDateRange = false;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text(databaseErrorMessage), findsNothing);
    expect(find.text('No activity for this period'), findsOneWidget);
  });

  testWidgets('measurement dialog rejects non-numeric optional fields and does not save', (tester) async {
    final repo = FakeBodyMeasurementRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bodyMeasurementRepositoryProvider.overrideWithValue(repo),
          exerciseLogRepositoryProvider.overrideWithValue(FakeExerciseLogRepository()),
          exerciseCategoryRepositoryProvider.overrideWithValue(FakeExerciseCategoryRepository()),
          exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository()),
        ],
        child: const MaterialApp(home: SportsDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log weight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log weight'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '80');
    await tester.enterText(find.widgetWithText(TextFormField, 'Chest'), 'not-a-number');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Must be a number'), findsOneWidget);
    expect(repo.items, isEmpty);
    expect(find.text('Log Body Measurements'), findsOneWidget);
  });

  testWidgets('shows a mapped error snackbar (not raw text) when the create write fails', (tester) async {
    final repo = _FailingCreateBodyMeasurementRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bodyMeasurementRepositoryProvider.overrideWithValue(repo),
          exerciseLogRepositoryProvider.overrideWithValue(FakeExerciseLogRepository()),
          exerciseCategoryRepositoryProvider.overrideWithValue(FakeExerciseCategoryRepository()),
          exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository()),
        ],
        child: const MaterialApp(home: SportsDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log weight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log weight'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '80');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text(databaseErrorMessage), findsOneWidget);
    expect(find.text('fake sports storage failure'), findsNothing);
  });
}
