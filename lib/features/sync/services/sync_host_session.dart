// lib/features/sync/services/sync_host_session.dart — the host-side state and operations of one paired sync session.

import '../../../data/models/sync/sync_phase.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_row_bundle.dart';
import '../../../data/models/sync/sync_session_report.dart';
import 'sync_data_store.dart';
import 'sync_diff_engine.dart';
import 'sync_errors.dart';
import 'sync_manifest_builder.dart';
import 'sync_protocol.dart';
import 'sync_row_applier.dart';
import 'sync_safety_backup.dart';
import 'sync_stats_recorder.dart';
import 'sync_table_scope.dart';

typedef SyncCommitOutcome = ({SyncCommitPayload response, SyncSessionReport report});

class SyncHostSession {
  final SyncDataStore store;
  final SyncSafetyBackup safetyBackup;
  final String remoteDeviceLabel;
  final Duration clockSkew;
  final DateTime startedAt;
  final DateTime Function() _clock;
  final void Function(SyncProgressEvent event) _emit;
  final SyncDiffEngine _diffEngine = const SyncDiffEngine();
  final SyncStatsRecorder _recorder = SyncStatsRecorder();
  final Map<String, List<SyncRowBundle>> _stagedByTable = <String, List<SyncRowBundle>>{};
  final Map<String, int> _plannedToReceive = <String, int>{};
  final Map<String, int> _plannedToSend = <String, int>{};
  final Map<String, int> _receivedRows = <String, int>{};
  final Map<String, int> _sentRows = <String, int>{};

  SyncHostSession({
    required this.store,
    required this.safetyBackup,
    required this.remoteDeviceLabel,
    required this.clockSkew,
    required this.startedAt,
    required DateTime Function() clock,
    required void Function(SyncProgressEvent event) emit,
  }) : _clock = clock,
       _emit = emit;

  Future<SyncDiffResponse> diff(SyncDiffRequest request) async {
    _requireSyncable(request.table);
    final local = await SyncManifestBuilder(store).buildTable(request.table);
    final diff = _diffEngine.compare(local: local, remote: request.stamps);
    _recorder.recordDiff(request.table, skipped: diff.skippedCount, conflicts: diff.conflictCount);
    _plannedToReceive[request.table] = diff.idsToReceive.length;
    _plannedToSend[request.table] = diff.idsToSend.length;
    _emitProgress(SyncPhase.comparing, request.table, request.stamps.length, request.stamps.length);
    return SyncDiffResponse(
      idsToPush: diff.idsToReceive,
      idsToPull: diff.idsToSend,
      skippedCount: diff.skippedCount,
      conflictCount: diff.conflictCount,
    );
  }

  Future<SyncRowsPayload> pull(SyncPullRequest request) async {
    _requireSyncable(request.table);
    final bundle = await store.readRows(request.table, request.ids);
    return SyncRowsPayload(table: request.table, bundle: bundle);
  }

  void recordPullSent(SyncRowsPayload payload, int responseBytes) {
    _recorder.recordSent(
      payload.table,
      rows: payload.bundle.rows.length,
      attachments: payload.bundle.attachments.length,
      bytes: responseBytes,
    );
    final done = (_sentRows[payload.table] ?? 0) + payload.bundle.rows.length;
    _sentRows[payload.table] = done;
    _emitProgress(SyncPhase.sending, payload.table, done, _plannedToSend[payload.table] ?? done);
  }

  void stagePush(SyncRowsPayload payload, int requestBytes) {
    _requireSyncable(payload.table);
    _stagedByTable.putIfAbsent(payload.table, () => <SyncRowBundle>[]).add(payload.bundle);
    _recorder.recordReceived(
      payload.table,
      rows: payload.bundle.rows.length,
      attachments: payload.bundle.attachments.length,
      bytes: requestBytes,
    );
    final done = (_receivedRows[payload.table] ?? 0) + payload.bundle.rows.length;
    _receivedRows[payload.table] = done;
    _emitProgress(SyncPhase.receiving, payload.table, done, _plannedToReceive[payload.table] ?? done);
  }

  Future<SyncCommitOutcome> commit(SyncCommitPayload request) async {
    _emitProgress(SyncPhase.backingUp);
    final backup = await safetyBackup.create();
    if (backup.isFailure) {
      throw backup.error!;
    }
    _emitProgress(SyncPhase.applying);
    final outcomes = await SyncRowApplier(store).apply(_stagedByTable);
    for (final entry in outcomes.entries) {
      _recorder.recordApplied(entry.key, entry.value);
    }
    final localReminders = await store.readReminders();
    await store.mergeReminders(request.reminders);
    final report = _recorder.buildReport(
      startedAt: startedAt,
      endedAt: _clock(),
      remoteDeviceLabel: remoteDeviceLabel,
      clockSkew: clockSkew,
      safetyBackupPath: backup.data,
    );
    _emitProgress(SyncPhase.completed);
    return (response: SyncCommitPayload(reminders: localReminders), report: report);
  }

  void _requireSyncable(String table) {
    if (!SyncTableScope.isSyncable(table) || !store.syncableTables.contains(table)) {
      throw SyncBadRequestError('Table is not part of device sync');
    }
  }

  void _emitProgress(SyncPhase phase, [String? table, int rowsDone = 0, int rowsTotal = 0]) {
    _emit(
      SyncProgressEvent(
        phase: phase,
        table: table,
        moduleKey: table == null ? null : SyncStatsRecorder.moduleKeyOf(table),
        rowsDone: rowsDone,
        rowsTotal: rowsTotal,
      ),
    );
  }
}
