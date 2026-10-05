// lib/data/models/sync/sync_progress_event.dart — one live progress update emitted while a sync session runs.

import 'package:equatable/equatable.dart';

import 'sync_phase.dart';

class SyncProgressEvent extends Equatable {
  final SyncPhase phase;
  final String? table;
  final String? moduleKey;
  final int rowsDone;
  final int rowsTotal;

  const SyncProgressEvent({
    required this.phase,
    this.table,
    this.moduleKey,
    this.rowsDone = 0,
    this.rowsTotal = 0,
  });

  @override
  List<Object?> get props => [phase, table, moduleKey, rowsDone, rowsTotal];
}
