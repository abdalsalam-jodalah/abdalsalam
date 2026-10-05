// test/sync/support/fake_sync_data_store.dart — in-memory SyncDataStore with attachment and reminder support for sync tests.

import 'dart:typed_data';

import 'package:abdalsalam/data/models/sync/sync_row_bundle.dart';
import 'package:abdalsalam/data/models/sync/sync_row_stamp.dart';
import 'package:abdalsalam/features/sync/services/sync_data_store.dart';
import 'package:abdalsalam/features/sync/services/sync_reminder_merger.dart';
import 'package:abdalsalam/features/sync/services/sync_table_scope.dart';

class FakeSyncDataStore implements SyncDataStore {
  static const String attachmentField = 'imagePath';
  static const String attachmentEntryPrefix = 'attachments/';
  static const String localFolderPrefix = 'local/';

  final Map<String, Map<String, Map<String, dynamic>>> tables;
  final Set<String> attachmentTables;
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final List<Map<String, dynamic>> reminders = <Map<String, dynamic>>[];
  final List<Map<String, List<Map<String, dynamic>>>> appliedBatches = <Map<String, List<Map<String, dynamic>>>>[];

  FakeSyncDataStore({
    Map<String, List<Map<String, dynamic>>> rows = const <String, List<Map<String, dynamic>>>{},
    this.attachmentTables = const <String>{},
  }) : tables = <String, Map<String, Map<String, dynamic>>>{
         for (final entry in rows.entries)
           entry.key: <String, Map<String, dynamic>>{for (final row in entry.value) '${row['id']}': row},
       };

  @override
  List<String> get syncableTables => SyncTableScope.filter(tables.keys);

  @override
  bool hasAttachments(String table) => attachmentTables.contains(table);

  Map<String, Map<String, dynamic>> rowsOf(String table) => tables[table] ?? <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, SyncRowStamp>> readStamps(String table) async {
    return <String, SyncRowStamp>{
      for (final entry in rowsOf(table).entries) entry.key: SyncRowStamp.fromRow(entry.value),
    };
  }

  @override
  Future<SyncRowBundle> readRows(String table, List<String> ids) async {
    final rows = <Map<String, dynamic>>[];
    final attachments = <String, Uint8List>{};
    for (final id in ids) {
      final row = rowsOf(table)[id];
      if (row == null) {
        continue;
      }
      final path = row[attachmentField];
      if (hasAttachments(table) && path is String && files.containsKey(path)) {
        final entry = '$attachmentEntryPrefix$table/${path.split('/').last}';
        attachments[entry] = files[path]!;
        rows.add(<String, dynamic>{...row, attachmentField: entry});
      } else {
        rows.add(<String, dynamic>{...row});
      }
    }
    return SyncRowBundle(rows: rows, attachments: attachments);
  }

  @override
  Future<List<Map<String, dynamic>>> restoreAttachments(
    String table,
    List<Map<String, dynamic>> rows,
    Map<String, Uint8List> attachments,
  ) async {
    return <Map<String, dynamic>>[
      for (final row in rows)
        if (row[attachmentField] is String && attachments.containsKey(row[attachmentField]))
          _restored(row, attachments)
        else
          row,
    ];
  }

  Map<String, dynamic> _restored(Map<String, dynamic> row, Map<String, Uint8List> attachments) {
    final entry = row[attachmentField] as String;
    final path = '$localFolderPrefix${entry.split('/').last}';
    files[path] = attachments[entry]!;
    return <String, dynamic>{...row, attachmentField: path};
  }

  @override
  Future<void> applyRows(Map<String, List<Map<String, dynamic>>> rowsByTable) async {
    appliedBatches.add(<String, List<Map<String, dynamic>>>{
      for (final entry in rowsByTable.entries) entry.key: <Map<String, dynamic>>[...entry.value],
    });
    for (final entry in rowsByTable.entries) {
      final table = tables.putIfAbsent(entry.key, () => <String, Map<String, dynamic>>{});
      for (final row in entry.value) {
        table['${row['id']}'] = <String, dynamic>{...row};
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> readReminders() async => <Map<String, dynamic>>[...reminders];

  @override
  Future<int> mergeReminders(List<Map<String, dynamic>> incoming) async {
    final merged = const SyncReminderMerger().merge(local: reminders, incoming: incoming);
    reminders
      ..clear()
      ..addAll(merged.reminders);
    return merged.addedCount;
  }
}
