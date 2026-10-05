// lib/data/models/sync/sync_row_bundle.dart — rows of one table together with the attachment files they reference.

import 'dart:typed_data';

class SyncRowBundle {
  final List<Map<String, dynamic>> rows;
  final Map<String, Uint8List> attachments;
  final int missingAttachmentCount;

  const SyncRowBundle({
    required this.rows,
    this.attachments = const <String, Uint8List>{},
    this.missingAttachmentCount = 0,
  });

  int get attachmentBytes => attachments.values.fold<int>(0, (total, bytes) => total + bytes.length);
}
