// lib/features/sync/services/sync_stats_recorder.dart — accumulates per-module transfer counts for one session and builds its report.

import '../../../core/constants/sync_constants.dart';
import '../../../data/models/sync/sync_module_stats.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/services/module_table_registry.dart';

class SyncStatsRecorder {
  final Map<String, SyncModuleStats> _statsByModule = <String, SyncModuleStats>{};

  static String moduleKeyOf(String table) {
    return ModuleTableRegistry.moduleOf(table)?.name ?? SyncConstants.unknownModuleKey;
  }

  void recordDiff(String table, {required int skipped, required int conflicts}) {
    _add(table, SyncModuleStats(skipped: skipped, conflicts: conflicts));
  }

  void recordSent(String table, {required int rows, required int attachments, required int bytes}) {
    _add(table, SyncModuleStats(rowsSent: rows, attachments: attachments, bytesSent: bytes));
  }

  void recordReceived(String table, {required int rows, required int attachments, required int bytes}) {
    _add(table, SyncModuleStats(rowsReceived: rows, attachments: attachments, bytesReceived: bytes));
  }

  void recordApplied(String table, SyncModuleStats applied) {
    _add(table, SyncModuleStats(added: applied.added, updated: applied.updated, deleted: applied.deleted));
  }

  Map<String, SyncModuleStats> snapshot() => Map<String, SyncModuleStats>.unmodifiable(_statsByModule);

  SyncSessionReport buildReport({
    required DateTime startedAt,
    required DateTime endedAt,
    required String remoteDeviceLabel,
    required Duration clockSkew,
    String? safetyBackupPath,
  }) {
    return SyncSessionReport(
      startedAt: startedAt,
      endedAt: endedAt,
      remoteDeviceLabel: remoteDeviceLabel,
      clockSkew: clockSkew,
      moduleStats: snapshot(),
      safetyBackupPath: safetyBackupPath,
    );
  }

  void _add(String table, SyncModuleStats stats) {
    final key = moduleKeyOf(table);
    _statsByModule[key] = (_statsByModule[key] ?? const SyncModuleStats()) + stats;
  }
}
