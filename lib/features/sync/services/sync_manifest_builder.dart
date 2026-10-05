// lib/features/sync/services/sync_manifest_builder.dart — reads the id-to-stamp manifest of the syncable tables from a data store.

import '../../../data/models/sync/sync_manifest.dart';
import '../../../data/models/sync/sync_row_stamp.dart';
import 'sync_data_store.dart';

class SyncManifestBuilder {
  final SyncDataStore store;

  const SyncManifestBuilder(this.store);

  Future<Map<String, SyncRowStamp>> buildTable(String table) => store.readStamps(table);

  Future<SyncManifest> build() async {
    final tables = <String, Map<String, SyncRowStamp>>{};
    for (final table in store.syncableTables) {
      tables[table] = await buildTable(table);
    }
    return SyncManifest(tables);
  }
}
