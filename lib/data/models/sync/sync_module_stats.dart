// lib/data/models/sync/sync_module_stats.dart — what one sync session moved and changed for one module.

import 'package:equatable/equatable.dart';

import '../../../core/json/json_reader.dart';

class SyncModuleStats extends Equatable {
  static const String _source = 'SyncModuleStats';

  final int rowsSent;
  final int rowsReceived;
  final int added;
  final int updated;
  final int deleted;
  final int skipped;
  final int conflicts;
  final int attachments;
  final int bytesSent;
  final int bytesReceived;

  const SyncModuleStats({
    this.rowsSent = 0,
    this.rowsReceived = 0,
    this.added = 0,
    this.updated = 0,
    this.deleted = 0,
    this.skipped = 0,
    this.conflicts = 0,
    this.attachments = 0,
    this.bytesSent = 0,
    this.bytesReceived = 0,
  });

  factory SyncModuleStats.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _source);
    return SyncModuleStats(
      rowsSent: reader.readInt('rowsSent'),
      rowsReceived: reader.readInt('rowsReceived'),
      added: reader.readInt('added'),
      updated: reader.readInt('updated'),
      deleted: reader.readInt('deleted'),
      skipped: reader.readInt('skipped'),
      conflicts: reader.readInt('conflicts'),
      attachments: reader.readInt('attachments'),
      bytesSent: reader.readInt('bytesSent'),
      bytesReceived: reader.readInt('bytesReceived'),
    );
  }

  bool get hasTransfers => rowsSent > 0 || rowsReceived > 0;

  SyncModuleStats operator +(SyncModuleStats other) {
    return SyncModuleStats(
      rowsSent: rowsSent + other.rowsSent,
      rowsReceived: rowsReceived + other.rowsReceived,
      added: added + other.added,
      updated: updated + other.updated,
      deleted: deleted + other.deleted,
      skipped: skipped + other.skipped,
      conflicts: conflicts + other.conflicts,
      attachments: attachments + other.attachments,
      bytesSent: bytesSent + other.bytesSent,
      bytesReceived: bytesReceived + other.bytesReceived,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rowsSent': rowsSent,
      'rowsReceived': rowsReceived,
      'added': added,
      'updated': updated,
      'deleted': deleted,
      'skipped': skipped,
      'conflicts': conflicts,
      'attachments': attachments,
      'bytesSent': bytesSent,
      'bytesReceived': bytesReceived,
    };
  }

  @override
  List<Object?> get props => [
        rowsSent,
        rowsReceived,
        added,
        updated,
        deleted,
        skipped,
        conflicts,
        attachments,
        bytesSent,
        bytesReceived,
      ];
}
