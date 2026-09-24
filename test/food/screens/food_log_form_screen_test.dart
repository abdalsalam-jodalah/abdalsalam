import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/food/food_log.dart';
import 'package:abdalsalam/data/repositories/food/food_log_repository.dart';
import 'package:abdalsalam/features/food/providers/food_providers.dart';
import 'package:abdalsalam/features/food/screens/food_log_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFoodLogRepository implements FoodLogRepository {
  final List<FoodLog> items = <FoodLog>[];
  bool shouldFailCreate = false;

  @override
  Future<Result<List<FoodLog>, AppError>> getActive() async => Success(List<FoodLog>.of(items));

  @override
  Future<Result<FoodLog, AppError>> create(FoodLog entity) async {
    if (shouldFailCreate) {
      return Failure(DatabaseError('fake write failure'));
    }
    items.add(entity);
    return Success(entity);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  Future<void> useTallViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('rejects an empty dish name and does not save', (tester) async {
    await useTallViewport(tester);
    final repository = _FakeFoodLogRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodLogRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: FoodLogFormScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
    expect(repository.items, isEmpty);
  });

  testWidgets('shows an error snackbar and keeps the form open when save fails', (tester) async {
    await useTallViewport(tester);
    final repository = _FakeFoodLogRepository()..shouldFailCreate = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodLogRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: FoodLogFormScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'Salad');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Your data could not be saved or loaded. Please try again.'), findsOneWidget);
    expect(find.byType(FoodLogFormScreen), findsOneWidget);
    expect(repository.items, isEmpty);
  });
}
