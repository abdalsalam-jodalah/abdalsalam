// lib/shared/services/planning_export_enricher.dart — adds the category names next to categoryIds in planning task exports.

import 'export_row_enricher.dart';

class PlanningExportEnricher implements ExportRowEnricher {
  static const String _tasksTable = 'life_planning_tasks';
  static const String _categoriesTable = 'planning_task_categories';
  static const String _nameField = 'name';
  static const String _categoryIdsField = 'categoryIds';
  static const String _legacyCategoryIdField = 'categoryId';
  static const String _categoryNamesField = 'categoryNames';
  static const String _separator = ', ';

  const PlanningExportEnricher();

  @override
  Map<String, List<Map<String, dynamic>>> enrich(Map<String, List<Map<String, dynamic>>> rowsByTable) {
    final tasks = rowsByTable[_tasksTable];
    if (tasks == null) {
      return rowsByTable;
    }
    final categoryNames = <Object?, String>{
      for (final row in rowsByTable[_categoriesTable] ?? const <Map<String, dynamic>>[])
        if (row[_nameField] is String) row['id']: row[_nameField] as String,
    };
    return <String, List<Map<String, dynamic>>>{
      ...rowsByTable,
      _tasksTable: tasks
          .map((row) => <String, dynamic>{...row, _categoryNamesField: _namesFor(row, categoryNames)})
          .toList(growable: false),
    };
  }

  String _namesFor(Map<String, dynamic> row, Map<Object?, String> categoryNames) {
    final ids = row[_categoryIdsField] is List ? row[_categoryIdsField] as List : [row[_legacyCategoryIdField]];
    return ids.map((id) => categoryNames[id]).whereType<String>().join(_separator);
  }
}
