// lib/features/sync/services/sync_data_store.dart — the storage abstraction device sync reads from and writes to.

import 'dart:typed_data';

import '../../../data/models/sync/sync_row_bundle.dart';
import '../../../data/models/sync/sync_row_stamp.dart';

abstract interface class SyncDataStore {
  List<String> get syncableTables;

  bool hasAttachments(String table);

  Future<Map<String, SyncRowStamp>> readStamps(String table);

  Future<SyncRowBundle> readRows(String table, List<String> ids);

  Future<List<Map<String, dynamic>>> restoreAttachments(
    String table,
    List<Map<String, dynamic>> rows,
    Map<String, Uint8List> attachments,
  );

  Future<void> applyRows(Map<String, List<Map<String, dynamic>>> rowsByTable);

  Future<List<Map<String, dynamic>>> readReminders();

  Future<int> mergeReminders(List<Map<String, dynamic>> incoming);
}
