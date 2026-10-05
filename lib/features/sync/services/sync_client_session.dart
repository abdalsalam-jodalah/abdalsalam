// lib/features/sync/services/sync_client_session.dart — drives one sync run from the connecting device against a host.

import '../../../core/constants/sync_constants.dart';
import '../../../data/models/sync/sync_phase.dart';
import '../../../data/models/sync/sync_progress_event.dart';
import '../../../data/models/sync/sync_row_bundle.dart';
import '../../../data/models/sync/sync_session_report.dart';
import 'sync_data_store.dart';
import 'sync_http_transport.dart';
import 'sync_manifest_builder.dart';
import 'sync_protocol.dart';
import 'sync_row_applier.dart';
import 'sync_safety_backup.dart';
import 'sync_stats_recorder.dart';

class SyncClientSession {
  static const int _halfDivisor = 2;

  final SyncDataStore store;
  final SyncSafetyBackup safetyBackup;
  final SyncHttpTransport transport;
  final String deviceLabel;
  final DateTime Function() _clock;
  final void Function(SyncProgressEvent event) _emit;
  final SyncStatsRecorder _recorder = SyncStatsRecorder();
  final Map<String, List<SyncRowBundle>> _stagedByTable = <String, List<SyncRowBundle>>{};

  SyncClientSession({
    required this.store,
    required this.safetyBackup,
    required this.transport,
    required this.deviceLabel,
    required DateTime Function() clock,
    required void Function(SyncProgressEvent event) emit,
  }) : _clock = clock,
       _emit = emit;

  Future<SyncSessionReport> run(String pin) async {
    final startedAt = _clock();
    _emit(const SyncProgressEvent(phase: SyncPhase.connecting));
    final hello = await _hello(pin, startedAt);
    try {
      final plans = await _compare(hello.response.tables);
      await _send(plans);
      await _receive(plans);
      final backupPath = await _applyLocally();
      await _finalize();
      _emit(const SyncProgressEvent(phase: SyncPhase.completed));
      return _recorder.buildReport(
        startedAt: startedAt,
        endedAt: _clock(),
        remoteDeviceLabel: hello.response.deviceLabel,
        clockSkew: hello.clockSkew,
        safetyBackupPath: backupPath,
      );
    } catch (_) {
      await _abortQuietly();
      rethrow;
    }
  }

  Future<({SyncHelloResponse response, Duration clockSkew})> _hello(String pin, DateTime startedAt) async {
    final reply = await transport.post(
      SyncEndpoints.hello,
      SyncHelloRequest(
        pin: pin,
        deviceLabel: deviceLabel,
        clientTimeMilliseconds: startedAt.millisecondsSinceEpoch,
        protocolVersion: SyncConstants.protocolVersion,
      ).toJson(),
    );
    final response = SyncHelloResponse.fromJson(reply.json);
    transport.token = response.token;
    final roundTrip = _clock().difference(startedAt);
    final midpoint = startedAt.millisecondsSinceEpoch + roundTrip.inMilliseconds ~/ _halfDivisor;
    return (response: response, clockSkew: Duration(milliseconds: response.serverTimeMilliseconds - midpoint));
  }

  Future<Map<String, SyncDiffResponse>> _compare(List<String> hostTables) async {
    final manifest = await SyncManifestBuilder(store).build();
    final plans = <String, SyncDiffResponse>{};
    for (final table in store.syncableTables.where(hostTables.contains)) {
      final stamps = manifest.stampsOf(table);
      final reply = await transport.post(SyncEndpoints.diff, SyncDiffRequest(table: table, stamps: stamps).toJson());
      final plan = SyncDiffResponse.fromJson(reply.json);
      plans[table] = plan;
      _recorder.recordDiff(table, skipped: plan.skippedCount, conflicts: plan.conflictCount);
      _emitProgress(SyncPhase.comparing, table, stamps.length, stamps.length);
    }
    return plans;
  }

  Future<void> _send(Map<String, SyncDiffResponse> plans) async {
    for (final entry in plans.entries) {
      final ids = entry.value.idsToPush;
      var done = 0;
      for (final batch in _batches(entry.key, ids)) {
        final bundle = await store.readRows(entry.key, batch);
        final reply = await transport.post(
          SyncEndpoints.push,
          SyncRowsPayload(table: entry.key, bundle: bundle).toJson(),
        );
        _recorder.recordSent(
          entry.key,
          rows: bundle.rows.length,
          attachments: bundle.attachments.length,
          bytes: reply.requestBytes,
        );
        done += batch.length;
        _emitProgress(SyncPhase.sending, entry.key, done, ids.length);
      }
    }
  }

  Future<void> _receive(Map<String, SyncDiffResponse> plans) async {
    for (final entry in plans.entries) {
      final ids = entry.value.idsToPull;
      var done = 0;
      for (final batch in _batches(entry.key, ids)) {
        final reply = await transport.post(SyncEndpoints.pull, SyncPullRequest(table: entry.key, ids: batch).toJson());
        final payload = SyncRowsPayload.fromJson(reply.json);
        _stagedByTable.putIfAbsent(entry.key, () => <SyncRowBundle>[]).add(payload.bundle);
        _recorder.recordReceived(
          entry.key,
          rows: payload.bundle.rows.length,
          attachments: payload.bundle.attachments.length,
          bytes: reply.responseBytes,
        );
        done += batch.length;
        _emitProgress(SyncPhase.receiving, entry.key, done, ids.length);
      }
    }
  }

  Future<String?> _applyLocally() async {
    _emit(const SyncProgressEvent(phase: SyncPhase.backingUp));
    final backup = await safetyBackup.create();
    if (backup.isFailure) {
      throw backup.error!;
    }
    _emit(const SyncProgressEvent(phase: SyncPhase.applying));
    final outcomes = await SyncRowApplier(store).apply(_stagedByTable);
    for (final entry in outcomes.entries) {
      _recorder.recordApplied(entry.key, entry.value);
    }
    return backup.data;
  }

  Future<void> _finalize() async {
    _emit(const SyncProgressEvent(phase: SyncPhase.finalizing));
    final reminders = await store.readReminders();
    final reply = await transport.post(SyncEndpoints.commit, SyncCommitPayload(reminders: reminders).toJson());
    await store.mergeReminders(SyncCommitPayload.fromJson(reply.json).reminders);
  }

  Future<void> _abortQuietly() async {
    try {
      await transport.post(SyncEndpoints.abort, const <String, dynamic>{});
    } catch (_) {
      return;
    }
  }

  Iterable<List<String>> _batches(String table, List<String> ids) sync* {
    final size = store.hasAttachments(table) ? SyncConstants.attachmentRowBatchSize : SyncConstants.rowBatchSize;
    for (var start = 0; start < ids.length; start += size) {
      yield ids.sublist(start, start + size > ids.length ? ids.length : start + size);
    }
  }

  void _emitProgress(SyncPhase phase, String table, int rowsDone, int rowsTotal) {
    _emit(
      SyncProgressEvent(
        phase: phase,
        table: table,
        moduleKey: SyncStatsRecorder.moduleKeyOf(table),
        rowsDone: rowsDone,
        rowsTotal: rowsTotal,
      ),
    );
  }
}
