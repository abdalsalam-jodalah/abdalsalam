import 'package:abdalsalam/core/formatting/app_date_formatter.dart';
import 'package:abdalsalam/data/models/planning/planning_task.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/planning/screens/day_planning_screen.dart';
import 'package:abdalsalam/features/planning/services/day_planning_range.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../planning_fakes.dart';

final DateTime _today = DayPlanningRange.dateOnly(DateTime.now());
final ValueKey<String> _todayHeaderKey = ValueKey('day-header-${_today.year}-${_today.month}-${_today.day}');

PlanningTask _task(String id, String title, {DateTime? date, int order = 0}) {
  return buildPlanningTask(id: id, title: title, date: date).copyWith(order: order);
}

Future<void> _pumpScreen(
  WidgetTester tester,
  FakePlanningTaskRepository repo, {
  FakeTaskCategoryRepository? categories,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planningTaskRepositoryProvider.overrideWithValue(repo),
        taskCategoryRepositoryProvider.overrideWithValue(categories ?? FakeTaskCategoryRepository()),
      ],
      child: const MaterialApp(home: DayPlanningScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LoggerService.initialize();
  });

  testWidgets('shows unassigned tasks in a collapsible panel', (tester) async {
    final repo = FakePlanningTaskRepository([_task('free', 'Buy milk')]);
    await _pumpScreen(tester, repo);

    expect(find.text('Buy milk'), findsOneWidget);

    await tester.tap(find.text('Unassigned tasks (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsNothing);
  });

  testWidgets('moves a completed task below the open ones', (tester) async {
    final repo = FakePlanningTaskRepository([
      _task('a', 'First task', date: _today, order: 0),
      _task('b', 'Second task', date: _today, order: 1),
    ]);
    await _pumpScreen(tester, repo);

    await tester.tap(find.byKey(const ValueKey('checkbox-a')));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('First task')).dy, greaterThan(tester.getTopLeft(find.text('Second task')).dy));
    expect(repo.items.firstWhere((task) => task.id == 'a').isCompleted, isTrue);
  });

  testWidgets('drags an unassigned task onto the day', (tester) async {
    final repo = FakePlanningTaskRepository([_task('free', 'Buy milk')]);
    await _pumpScreen(tester, repo);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Buy milk')));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveTo(tester.getCenter(find.byKey(_todayHeaderKey)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repo.items.single.date, _today);
    expect(find.text('0/1 done'), findsOneWidget);
    expect(find.text('Unassigned tasks (0)'), findsOneWidget);
  });

  testWidgets('swiping horizontally moves to the next day', (tester) async {
    final repo = FakePlanningTaskRepository([_task('later', 'Tomorrow task', date: _today.add(const Duration(days: 1)))]);
    await _pumpScreen(tester, repo);

    expect(find.text('Tomorrow task'), findsNothing);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 2000);
    await tester.pumpAndSettle();

    expect(find.text(AppDateFormatter.date(_today.add(const Duration(days: 1)))), findsWidgets);
    expect(find.text('Tomorrow task'), findsOneWidget);
  });

  testWidgets('reorders tasks within a day by dragging', (tester) async {
    final repo = FakePlanningTaskRepository([
      _task('a', 'First task', date: _today, order: 0),
      _task('b', 'Second task', date: _today, order: 1),
    ]);
    await _pumpScreen(tester, repo);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Second task')));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveTo(tester.getCenter(find.text('First task')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Second task')).dy, lessThan(tester.getTopLeft(find.text('First task')).dy));
    expect(repo.items.firstWhere((task) => task.id == 'b').order, 0);
    expect(repo.items.firstWhere((task) => task.id == 'a').order, 1);
  });

  group('multi-day layouts', () {
    final tomorrow = _today.add(const Duration(days: 1));

    void useScreenSize(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Future<void> showWeek(WidgetTester tester) async {
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows days side by side as columns with a side panel on a wide screen', (tester) async {
      useScreenSize(tester, const Size(1500, 900));
      final repo = FakePlanningTaskRepository([
        _task('free', 'Buy milk'),
        _task('today', 'Today task', date: _today),
        _task('next', 'Tomorrow task', date: tomorrow),
      ]);
      await _pumpScreen(tester, repo);
      await showWeek(tester);

      final todayTop = tester.getTopLeft(find.byKey(const ValueKey('checkbox-today')));
      final tomorrowTop = tester.getTopLeft(find.byKey(const ValueKey('checkbox-next')));
      expect(tester.getTopLeft(find.text('Buy milk')).dx, lessThan(todayTop.dx));
      expect(todayTop.dy, tomorrowTop.dy);
      expect(todayTop.dx, isNot(tomorrowTop.dx));
    });

    testWidgets('drags a task from one day column to another on a wide screen', (tester) async {
      useScreenSize(tester, const Size(1500, 900));
      final repo = FakePlanningTaskRepository([_task('today', 'Today task', date: _today)]);
      await _pumpScreen(tester, repo);
      await showWeek(tester);

      final tomorrowHeader = find.byKey(
        ValueKey('day-header-${tomorrow.year}-${tomorrow.month}-${tomorrow.day}'),
      );
      final gesture = await tester.startGesture(tester.getCenter(find.text('Today task')));
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveTo(tester.getCenter(tomorrowHeader));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repo.items.single.date, tomorrow);
    });

    testWidgets('stacks day cards vertically with the panel on top on a phone', (tester) async {
      useScreenSize(tester, const Size(400, 800));
      final repo = FakePlanningTaskRepository([
        _task('free', 'Buy milk'),
        _task('today', 'Today task', date: _today),
        _task('next', 'Tomorrow task', date: tomorrow),
      ]);
      await _pumpScreen(tester, repo);
      await showWeek(tester);

      expect(find.text('Today'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Buy milk')).dy, lessThan(tester.getTopLeft(find.text('Today task')).dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('marks only today with the today pill', (tester) async {
      useScreenSize(tester, const Size(400, 800));
      await _pumpScreen(tester, FakePlanningTaskRepository());
      await showWeek(tester);

      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('task categories', () {
    testWidgets('shows every category of the task as a badge', (tester) async {
      final repo = FakePlanningTaskRepository([
        buildPlanningTask(id: 'a', title: 'Fix bug', date: _today, categoryIds: ['cat-1', 'cat-2']),
      ]);
      await _pumpScreen(
        tester,
        repo,
        categories: FakeTaskCategoryRepository([
          buildTaskCategory(id: 'cat-1', name: 'iOS'),
          buildTaskCategory(id: 'cat-2', name: 'Work', color: '#1D76DB'),
        ]),
      );

      expect(find.byKey(const ValueKey('task-badge-a-cat-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-badge-a-cat-2')), findsOneWidget);
      expect(find.text('iOS'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('skips categories that no longer exist', (tester) async {
      final repo = FakePlanningTaskRepository([
        buildPlanningTask(id: 'a', title: 'Fix bug', date: _today, categoryIds: ['deleted', 'cat-1']),
      ]);
      await _pumpScreen(tester, repo, categories: FakeTaskCategoryRepository([buildTaskCategory(id: 'cat-1')]));

      expect(find.byKey(const ValueKey('task-badge-a-cat-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-badge-a-deleted')), findsNothing);
      expect(find.text('Fix bug'), findsOneWidget);
    });

    testWidgets('creates a task in several chosen categories from the add dialog', (tester) async {
      final repo = FakePlanningTaskRepository();
      await _pumpScreen(
        tester,
        repo,
        categories: FakeTaskCategoryRepository([
          buildTaskCategory(id: 'cat-1', name: 'Work'),
          buildTaskCategory(id: 'cat-2', name: 'Health'),
          buildTaskCategory(id: 'cat-3', name: 'Home'),
        ]),
      );

      await tester.tap(find.byTooltip('Add task').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Ship release');
      await tester.tap(find.byKey(const ValueKey('category-choice-cat-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('category-choice-cat-3')));
      await tester.pump();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(repo.items.single.title, 'Ship release');
      expect(repo.items.single.categoryIds, ['cat-1', 'cat-3']);
    });

    testWidgets('deselecting a category in the edit dialog removes only that category', (tester) async {
      final repo = FakePlanningTaskRepository([
        buildPlanningTask(id: 'a', title: 'Fix bug', date: _today, categoryIds: ['cat-1', 'cat-2']),
      ]);
      await _pumpScreen(
        tester,
        repo,
        categories: FakeTaskCategoryRepository([
          buildTaskCategory(id: 'cat-1', name: 'iOS'),
          buildTaskCategory(id: 'cat-2', name: 'Work'),
        ]),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-choice-cat-1')));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.items.single.categoryIds, ['cat-2']);
    });

    testWidgets('removes every category when all are deselected', (tester) async {
      final repo = FakePlanningTaskRepository([
        buildPlanningTask(id: 'a', title: 'Fix bug', date: _today, categoryIds: ['cat-1']),
      ]);
      await _pumpScreen(tester, repo, categories: FakeTaskCategoryRepository([buildTaskCategory(id: 'cat-1')]));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-choice-cat-1')));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.items.single.categoryIds, isEmpty);
    });

    testWidgets('opens the category manager from the app bar', (tester) async {
      await _pumpScreen(tester, FakePlanningTaskRepository());

      expect(find.byTooltip('Task categories'), findsOneWidget);
    });
  });
}
