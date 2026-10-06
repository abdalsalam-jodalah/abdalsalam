import 'package:abdalsalam/shared/services/planning_export_enricher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const enricher = PlanningExportEnricher();

  test('should list every category name next to categoryIds on task rows', () {
    final rows = enricher.enrich({
      'planning_task_categories': [
        {'id': 'cat-1', 'name': 'iOS'},
        {'id': 'cat-2', 'name': 'Work'},
      ],
      'life_planning_tasks': [
        {'id': 't1', 'categoryIds': ['cat-1', 'cat-2']},
        {'id': 't2', 'categoryIds': <String>[]},
        {'id': 't3', 'categoryIds': ['deleted', 'cat-2']},
      ],
    });

    final tasks = rows['life_planning_tasks']!;
    expect(tasks[0]['categoryNames'], 'iOS, Work');
    expect(tasks[1]['categoryNames'], '');
    expect(tasks[2]['categoryNames'], 'Work');
  });

  test('should still resolve the single categoryId saved by the first version', () {
    final rows = enricher.enrich({
      'planning_task_categories': [
        {'id': 'cat-1', 'name': 'iOS'},
      ],
      'life_planning_tasks': [
        {'id': 't1', 'categoryId': 'cat-1'},
      ],
    });

    expect(rows['life_planning_tasks']!.single['categoryNames'], 'iOS');
  });

  test('should leave the rows untouched when tasks are not part of the export', () {
    final input = {
      'planning_task_categories': [
        {'id': 'cat-1', 'name': 'iOS'},
      ],
    };

    expect(enricher.enrich(input), input);
  });
}
