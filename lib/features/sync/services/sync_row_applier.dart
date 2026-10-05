// lib/features/sync/services/sync_row_applier.dart — applies received rows that are newer than local ones in one transaction.

import '../../../data/models/sync/sync_module_stats.dart';
import '../../../data/models/sync/sync_row_bundle.dart';
import '../../../data/models/sync/sync_row_stamp.dart';
import 'sync_data_store.dart';
import 'sync_diff_engine.dart';

class SyncRowApplier {
  final SyncDataStore store;
  final SyncDiffEngine diffEngine;

  const SyncRowApplier(this.store, {this.diffEngine = const SyncDiffEngine()});

  Future<Map<String, SyncModuleStats>> apply(Map<String, List<SyncRowBundle>> stagedByTable) async {
    final rowsToApply = <String, List<Map<String, dynamic>>>{};
    final outcomes = <String, SyncModuleStats>{};
    for (final entry in stagedByTable.entries) {
      final localStamps = <String, SyncRowStamp>{...await store.readStamps(entry.key)};
      var outcome = const SyncModuleStats();
      final tableRows = <Map<String, dynamic>>[];
      for (final bundle in entry.value) {
        final chosen = <Map<String, dynamic>>[];
        for (final row in bundle.rows) {
          final incoming = SyncRowStamp.fromRow(row);
          final local = localStamps['${row['id']}'];
          if (!diffEngine.shouldApplyIncoming(local: local, incoming: incoming)) {
            outcome += const SyncModuleStats(skipped: 1);
            continue;
          }
          chosen.add(row);
          localStamps['${row['id']}'] = incoming;
          outcome += _appliedOutcome(local: local, incoming: incoming);
        }
        tableRows.addAll(
          bundle.attachments.isEmpty ? chosen : await store.restoreAttachments(entry.key, chosen, bundle.attachments),
        );
      }
      rowsToApply[entry.key] = tableRows;
      outcomes[entry.key] = outcome;
    }
    await store.applyRows(rowsToApply);
    return outcomes;
  }

  SyncModuleStats _appliedOutcome({required SyncRowStamp? local, required SyncRowStamp incoming}) {
    if (incoming.isDeleted) {
      return const SyncModuleStats(deleted: 1);
    }
    return local == null ? const SyncModuleStats(added: 1) : const SyncModuleStats(updated: 1);
  }
}
