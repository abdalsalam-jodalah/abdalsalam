// lib/shared/services/backup_archive.dart — an encoded backup file ready to be saved or shared, with attachment counts.

import 'dart:typed_data';

class BackupArchive {
  final Uint8List bytes;
  final int attachmentCount;
  final int missingAttachmentCount;

  const BackupArchive({
    required this.bytes,
    required this.attachmentCount,
    required this.missingAttachmentCount,
  });
}
