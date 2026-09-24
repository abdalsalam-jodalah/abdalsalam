import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sports/exercise_category.dart';
import 'package:abdalsalam/features/sports/providers/sports_providers.dart';
import 'package:abdalsalam/features/sports/screens/exercise_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sports_fakes.dart';

class _FailingCreateExerciseCategoryRepository extends FakeExerciseCategoryRepository {
  @override
  Future<Result<ExerciseCategory, AppError>> create(ExerciseCategory entity) async =>
      Failure(fakeSportsStorageFailure());
}

void main() {
  const databaseErrorMessage = 'Your data could not be saved or loaded. Please try again.';

  testWidgets('shows a mapped error via AsyncErrorView and retries on tap', (tester) async {
    final repo = FakeExerciseCategoryRepository()..shouldFailGetAllOrdered = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [exerciseCategoryRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ExerciseLibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(databaseErrorMessage), findsOneWidget);
    expect(find.text('fake sports storage failure'), findsNothing);

    repo.shouldFailGetAllOrdered = false;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text(databaseErrorMessage), findsNothing);
    expect(find.text('No categories yet'), findsOneWidget);
  });

  testWidgets('category dialog rejects an empty name and does not create anything', (tester) async {
    final repo = FakeExerciseCategoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [exerciseCategoryRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ExerciseLibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('New Category'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
    expect(repo.items, isEmpty);
    expect(find.text('New Category'), findsOneWidget);
  });

  testWidgets('shows a mapped error snackbar (not raw text) when the create write fails', (tester) async {
    final repo = _FailingCreateExerciseCategoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [exerciseCategoryRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ExerciseLibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Legs');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text(databaseErrorMessage), findsOneWidget);
    expect(find.text('fake sports storage failure'), findsNothing);
  });
}
