// lib/features/sync/services/sync_table_diff.dart — which row ids one side sends, receives or skips for a table.

import 'package:equatable/equatable.dart';

class SyncTableDiff extends Equatable {
  final List<String> idsToSend;
  final List<String> idsToReceive;
  final int skippedCount;
  final int conflictCount;

  const SyncTableDiff({
    required this.idsToSend,
    required this.idsToReceive,
    required this.skippedCount,
    required this.conflictCount,
  });

  @override
  List<Object?> get props => [idsToSend, idsToReceive, skippedCount, conflictCount];
}
