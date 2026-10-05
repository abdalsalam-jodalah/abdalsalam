// lib/features/sync/services/sync_diff_engine.dart — decides per row which side is newer so only the winning rows travel.

import '../../../data/models/sync/sync_row_stamp.dart';
import 'sync_row_comparison.dart';
import 'sync_table_diff.dart';

class SyncDiffEngine {
  const SyncDiffEngine();

  SyncRowComparison compareStamps(SyncRowStamp local, SyncRowStamp remote) {
    if (local.updatedAt != remote.updatedAt) {
      final localTime = local.updatedAtTime;
      final remoteTime = remote.updatedAtTime;
      if (localTime != null && remoteTime != null) {
        if (localTime.isAfter(remoteTime)) {
          return SyncRowComparison.localNewer;
        }
        if (remoteTime.isAfter(localTime)) {
          return SyncRowComparison.remoteNewer;
        }
      } else if (localTime != null) {
        return SyncRowComparison.localNewer;
      } else if (remoteTime != null) {
        return SyncRowComparison.remoteNewer;
      }
    }
    if (local.isDeleted == remote.isDeleted) {
      return SyncRowComparison.same;
    }
    return local.isDeleted ? SyncRowComparison.localNewer : SyncRowComparison.remoteNewer;
  }

  bool shouldApplyIncoming({required SyncRowStamp? local, required SyncRowStamp incoming}) {
    return local == null || compareStamps(local, incoming) == SyncRowComparison.remoteNewer;
  }

  SyncTableDiff compare({required Map<String, SyncRowStamp> local, required Map<String, SyncRowStamp> remote}) {
    final idsToSend = <String>[];
    final idsToReceive = <String>[];
    var skippedCount = 0;
    var conflictCount = 0;
    for (final entry in local.entries) {
      final remoteStamp = remote[entry.key];
      if (remoteStamp == null) {
        idsToSend.add(entry.key);
        continue;
      }
      switch (compareStamps(entry.value, remoteStamp)) {
        case SyncRowComparison.same:
          skippedCount++;
        case SyncRowComparison.localNewer:
          idsToSend.add(entry.key);
          conflictCount++;
        case SyncRowComparison.remoteNewer:
          idsToReceive.add(entry.key);
          conflictCount++;
      }
    }
    for (final id in remote.keys) {
      if (!local.containsKey(id)) {
        idsToReceive.add(id);
      }
    }
    return SyncTableDiff(
      idsToSend: idsToSend,
      idsToReceive: idsToReceive,
      skippedCount: skippedCount,
      conflictCount: conflictCount,
    );
  }
}
