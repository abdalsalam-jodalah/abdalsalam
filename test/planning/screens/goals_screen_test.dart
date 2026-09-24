import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/planning/screens/goals_screen.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../planning_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LoggerService.initialize();
  });

  testWidgets('shows AsyncErrorView friendly message and retries on failure', (tester) async {
    final repo = FakeGoalRepository()..shouldFailGetActive = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [goalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Failed to load goals'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('delete failure shows a mapped error and keeps the goal in the list', (tester) async {
    final goal = buildGoal(id: 'goal-1', title: 'Read daily');
    final repo = FakeGoalRepository([goal])..shouldFailSoftDelete = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [goalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read daily'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete "Read daily"?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Read daily'), findsOneWidget);
  });
}
