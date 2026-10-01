// lib/shared/services/backup_package.dart — a backup envelope together with the attachment files it references.

import 'dart:typed_data';

class BackupPackage {
  final Map<String, dynamic> envelope;
  final Map<String, Uint8List> attachments;
  final int missingAttachmentCount;

  const BackupPackage({
    required this.envelope,
    required this.attachments,
    required this.missingAttachmentCount,
  });
}
