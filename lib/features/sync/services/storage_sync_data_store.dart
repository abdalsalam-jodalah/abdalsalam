// lib/features/sync/services/storage_sync_data_store.dart — SyncDataStore backed by StorageGateway and the backup attachment bundler.

import 'dart:typed_data';

import '../../../core/constants/sync_constants.dart';
import '../../../data/models/sync/sync_row_bundle.dart';
import '../../../data/models/sync/sync_row_stamp.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../shared/services/backup_attachment_bundler.dart';
import 'sync_data_store.dart';
import 'sync_reminder_merger.dart';
import 'sync_table_scope.dart';

class StorageSyncDataStore implements SyncDataStore {
  final StorageGateway storage;
  final BackupAttachmentBundler attachmentBundler;
  final SyncReminderMerger _reminderMerger = const SyncReminderMerger();

  @override
  final List<String> syncableTables;

  StorageSyncDataStore({required this.storage, required this.attachmentBundler, List<String>? tables})
    : syncableTables = SyncTableScope.filter(tables ?? SyncTableScope.defaultTables);

  @override
  bool hasAttachments(String table) => attachmentBundler.bindings.any((binding) => binding.table == table);

  @override
  Future<Map<String, SyncRowStamp>> readStamps(String table) async {
    final rows = await storage.getAllRecords(table: table);
    return <String, SyncRowStamp>{for (final row in rows) '${row['id']}': SyncRowStamp.fromRow(row)};
  }

  @override
  Future<SyncRowBundle> readRows(String table, List<String> ids) async {
    final rows = <Map<String, dynamic>>[];
    for (final id in ids) {
      final row = await storage.getRecord(table: table, id: id);
      if (row != null) {
        rows.add(row);
      }
    }
    final bundle = await attachmentBundler.bundle(<String, List<Map<String, dynamic>>>{table: rows});
    return SyncRowBundle(
      rows: bundle.rows[table] ?? rows,
      attachments: bundle.files,
      missingAttachmentCount: bundle.missingCount,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> restoreAttachments(
    String table,
    List<Map<String, dynamic>> rows,
    Map<String, Uint8List> attachments,
  ) async {
    final outcome = await attachmentBundler.restore(<String, List<Map<String, dynamic>>>{table: rows}, attachments);
    return outcome.rows[table] ?? rows;
  }

  @override
  Future<void> applyRows(Map<String, List<Map<String, dynamic>>> rowsByTable) {
    return storage.runInTransaction(() async {
      for (final entry in rowsByTable.entries) {
        for (final row in entry.value) {
          await storage.upsertRecord(table: entry.key, id: '${row['id']}', record: row, isPreservingUpdatedAt: true);
        }
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> readReminders() async {
    final stored = await storage.get<List<dynamic>>(SyncConstants.remindersPreferenceKey);
    return _reminderMerger.normalize(stored);
  }

  @override
  Future<int> mergeReminders(List<Map<String, dynamic>> incoming) async {
    final local = await readReminders();
    final merged = _reminderMerger.merge(local: local, incoming: incoming);
    if (merged.addedCount > 0) {
      await storage.save(key: SyncConstants.remindersPreferenceKey, value: merged.reminders);
    }
    return merged.addedCount;
  }
}
