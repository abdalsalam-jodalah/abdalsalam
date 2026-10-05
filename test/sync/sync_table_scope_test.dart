// test/sync/sync_table_scope_test.dart — verifies the vault and queue tables are excluded from sync.

import 'package:abdalsalam/features/sync/services/sync_table_scope.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should exclude credentials, credential categories and the sync queue', () {
    final tables = SyncTableScope.defaultTables;

    expect(tables, isNot(contains('credentials')));
    expect(tables, isNot(contains('credential_categories')));
    expect(tables, isNot(contains('sync_queue')));
  });

  test('should include every other schema table', () {
    final expected = DatabaseSchemaInitializer.tables.where((table) => !SyncTableScope.excludedTables.contains(table));

    expect(SyncTableScope.defaultTables, expected.toList());
  });

  test('should report excluded tables as not syncable', () {
    expect(SyncTableScope.isSyncable('credentials'), isFalse);
    expect(SyncTableScope.isSyncable('notes'), isTrue);
  });
}
