// lib/features/sync/services/sync_history_store.dart — persists the most recent sync reports through StorageGateway.

import '../../../core/constants/sync_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../data/models/sync/sync_session_report.dart';
import '../../../shared/infrastructure/serial_task_queue.dart';
import '../../../shared/infrastructure/storage_gateway.dart';

class SyncHistoryStore {
  final StorageGateway storage;
  final int maxEntries;
  final SerialTaskQueue _queue = SerialTaskQueue();

  SyncHistoryStore(this.storage, {this.maxEntries = SyncConstants.historyLimit});

  Future<List<SyncSessionReport>> readAll() => _queue.run(_read);

  Future<void> add(SyncSessionReport report) {
    return _queue.run(() async {
      final reports = <SyncSessionReport>[report, ...await _read()];
      await _write(reports.take(maxEntries).toList(growable: false));
    });
  }

  Future<void> clear() => _queue.run(() => storage.delete(SyncConstants.historyPreferenceKey));

  Future<List<SyncSessionReport>> _read() async {
    final List<dynamic>? stored;
    try {
      stored = await storage.get<List<dynamic>>(SyncConstants.historyPreferenceKey);
    } on CorruptDataError {
      return const <SyncSessionReport>[];
    }
    final reports = <SyncSessionReport>[];
    for (final item in stored ?? const <dynamic>[]) {
      if (item is! Map) {
        continue;
      }
      try {
        reports.add(SyncSessionReport.fromJson(Map<String, dynamic>.from(item)));
      } on AppError {
        continue;
      }
    }
    return reports;
  }

  Future<void> _write(List<SyncSessionReport> reports) {
    return storage.save(
      key: SyncConstants.historyPreferenceKey,
      value: reports.map((report) => report.toJson()).toList(growable: false),
    );
  }
}
