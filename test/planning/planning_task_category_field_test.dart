import 'package:abdalsalam/data/models/planning/planning_task.dart';
import 'package:abdalsalam/data/models/planning/task_category.dart';
import 'package:flutter_test/flutter_test.dart';

import 'planning_fakes.dart';

void main() {
  group('PlanningTask.categoryIds', () {
    test('should read a task saved before categories existed as uncategorised', () {
      final json = buildPlanningTask().toJson()..remove('categoryIds');

      expect(PlanningTask.fromJson(json).categoryIds, isEmpty);
    });

    test('should read the single category saved by the first version as a one item list', () {
      final json = buildPlanningTask().toJson()
        ..remove('categoryIds')
        ..['categoryId'] = 'cat-1';

      expect(PlanningTask.fromJson(json).categoryIds, ['cat-1']);
    });

    test('should survive a JSON round trip with several categories in order', () {
      final task = buildPlanningTask(categoryIds: ['cat-2', 'cat-1']);

      expect(PlanningTask.fromJson(task.toJson()).categoryIds, ['cat-2', 'cat-1']);
    });

    test('should keep the categories on copy and replace them only when given', () {
      final task = buildPlanningTask(categoryIds: ['cat-1', 'cat-2']);

      expect(task.copyWith(title: 'Other').categoryIds, ['cat-1', 'cat-2']);
      expect(task.copyWith(categoryIds: ['cat-3']).categoryIds, ['cat-3']);
      expect(task.copyWith(categoryIds: const <String>[]).categoryIds, isEmpty);
    });
  });

  group('TaskCategory', () {
    test('should round trip through JSON', () {
      final category = buildTaskCategory(name: 'Work', color: '#1D76DB');

      final restored = TaskCategory.fromJson(category.toJson());

      expect(restored.name, 'Work');
      expect(restored.color, '#1D76DB');
    });

    test('should fall back to the default color when none was stored', () {
      final json = buildTaskCategory().toJson()..remove('color');

      expect(TaskCategory.fromJson(json).color, TaskCategory.defaultColor);
    });
  });
}
