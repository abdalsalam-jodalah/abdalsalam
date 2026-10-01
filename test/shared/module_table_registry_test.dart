import 'dart:io';

import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/services/module_table_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModuleTableRegistry', () {
    test('should cover exactly the tables the database schema creates', () {
      final registryTables = ModuleTableRegistry.allTables.toSet();
      final schemaTables = DatabaseSchemaInitializer.tables.toSet();

      expect(registryTables.difference(schemaTables), isEmpty);
      expect(schemaTables.difference(registryTables), isEmpty);
    });

    test('should assign each table to exactly one module', () {
      final allDeclared = DataModule.values.expand((module) => module.tables).toList();

      expect(allDeclared.length, allDeclared.toSet().length);
    });

    test('should cover every table name declared by a repository in lib', () {
      final tableNamePattern = RegExp(r"tableName\s*(?:=>|=)\s*'([a-z_]+)'");
      final declaredTables = <String>{};
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        for (final match in tableNamePattern.allMatches(entity.readAsStringSync())) {
          declaredTables.add(match.group(1)!);
        }
      }

      expect(declaredTables, isNotEmpty);
      expect(declaredTables.difference(ModuleTableRegistry.allTables.toSet()), isEmpty);
    });

    test('should exclude credentials and the sync queue from readable exports', () {
      final exportable = DataModule.values.expand(ModuleTableRegistry.readableExportTablesFor).toSet();

      expect(exportable, isNot(contains('credentials')));
      expect(exportable, isNot(contains('credential_categories')));
      expect(exportable, isNot(contains('sync_queue')));
      expect(exportable, contains('transactions'));
      expect(exportable, contains('prayer_logs'));
    });

    test('should resolve the owning module of a table', () {
      expect(ModuleTableRegistry.moduleOf('transactions'), DataModule.financial);
      expect(ModuleTableRegistry.moduleOf('prayer_logs'), DataModule.religious);
      expect(ModuleTableRegistry.moduleOf('unknown_table'), isNull);
    });
  });
}
