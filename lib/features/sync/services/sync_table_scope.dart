// lib/features/sync/services/sync_table_scope.dart — decides which storage tables take part in device sync.

import '../../../shared/infrastructure/database_schema_initializer.dart';

class SyncTableScope {
  const SyncTableScope._();

  static const Set<String> excludedTables = <String>{'credentials', 'credential_categories', 'sync_queue'};

  static List<String> get defaultTables => filter(DatabaseSchemaInitializer.tables);

  static bool isSyncable(String table) => !excludedTables.contains(table);

  static List<String> filter(Iterable<String> tables) {
    return tables.where(isSyncable).toList(growable: false);
  }
}
