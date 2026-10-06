import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/planning/screens/task_categories_screen.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../planning_fakes.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeTaskCategoryRepository categories,
  FakePlanningTaskRepository? tasks,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskCategoryRepositoryProvider.overrideWithValue(categories),
        planningTaskRepositoryProvider.overrideWithValue(tasks ?? FakePlanningTaskRepository()),
      ],
      child: const MaterialApp(home: TaskCategoriesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LoggerService.initialize();
  });

  testWidgets('shows an empty state when there are no categories', (tester) async {
    await _pump(tester, categories: FakeTaskCategoryRepository());

    expect(find.text('No categories yet'), findsOneWidget);
  });

  testWidgets('lists categories as badges sorted by name', (tester) async {
    await _pump(
      tester,
      categories: FakeTaskCategoryRepository([
        buildTaskCategory(id: 'w', name: 'Work'),
        buildTaskCategory(id: 'a', name: 'Android'),
      ]),
    );

    expect(tester.getTopLeft(find.text('Android')).dy, lessThan(tester.getTopLeft(find.text('Work')).dy));
  });

  testWidgets('creates a category with the chosen name and color', (tester) async {
    final categories = FakeTaskCategoryRepository();
    await _pump(tester, categories: categories);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Health');
    await tester.tap(find.byKey(const ValueKey('category-color-#2DA44E')));
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(categories.items.single.name, 'Health');
    expect(categories.items.single.color, '#2DA44E');
    expect(find.text('Health'), findsOneWidget);
  });

  testWidgets('refuses a duplicate name and keeps the dialog open', (tester) async {
    final categories = FakeTaskCategoryRepository([buildTaskCategory(name: 'iOS')]);
    await _pump(tester, categories: categories);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), ' ios ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('A category with this name already exists'), findsOneWidget);
    expect(categories.items, hasLength(1));
  });

  testWidgets('does not create a category with a blank name', (tester) async {
    final categories = FakeTaskCategoryRepository();
    await _pump(tester, categories: categories);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
    expect(categories.items, isEmpty);
  });

  testWidgets('renames a category', (tester) async {
    final categories = FakeTaskCategoryRepository([buildTaskCategory(name: 'iOS')]);
    await _pump(tester, categories: categories);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Apple');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(categories.items.single.name, 'Apple');
  });

  testWidgets('deletes a category and clears it from its tasks after confirmation', (tester) async {
    final categories = FakeTaskCategoryRepository([buildTaskCategory(id: 'cat-1', name: 'iOS')]);
    final tasks = FakePlanningTaskRepository([buildPlanningTask(categoryIds: ['cat-1', 'cat-2'])]);
    await _pump(tester, categories: categories, tasks: tasks);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "iOS"?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(categories.items, isEmpty);
    expect(tasks.items.single.categoryIds, ['cat-2']);
  });

  testWidgets('keeps the category when deletion is cancelled', (tester) async {
    final categories = FakeTaskCategoryRepository([buildTaskCategory(name: 'iOS')]);
    await _pump(tester, categories: categories);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(categories.items, hasLength(1));
  });
}
