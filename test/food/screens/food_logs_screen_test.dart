import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/food/food_log.dart';
import 'package:abdalsalam/data/repositories/food/food_log_repository.dart';
import 'package:abdalsalam/features/food/providers/food_providers.dart';
import 'package:abdalsalam/features/food/screens/food_logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFoodLogRepository implements FoodLogRepository {
  final List<FoodLog> items;
  bool shouldFailGetActive = false;

  _FakeFoodLogRepository([List<FoodLog>? seed]) : items = seed ?? <FoodLog>[];

  @override
  Future<Result<List<FoodLog>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(DatabaseError('fake storage failure'));
    }
    return Success(List<FoodLog>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('shows AsyncErrorView friendly message on failure and reloads on retry', (tester) async {
    final repository = _FakeFoodLogRepository()..shouldFailGetActive = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodLogRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: FoodLogsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Your data could not be saved or loaded. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No food logs yet. Tap + to add one.'), findsNothing);

    repository.shouldFailGetActive = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No food logs yet. Tap + to add one.'), findsOneWidget);
  });
}
