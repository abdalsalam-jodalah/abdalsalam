// lib/shared/services/backup_archive_codec.dart — reads and writes the zip container that holds a backup envelope and its attachment files.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import 'backup_keys.dart';

class BackupArchiveContents {
  final Map<String, dynamic> envelope;
  final Map<String, Uint8List> attachments;

  const BackupArchiveContents({required this.envelope, required this.attachments});
}

class BackupArchiveCodec {
  static const List<int> _zipSignature = <int>[0x50, 0x4B, 0x03, 0x04];

  const BackupArchiveCodec();

  static bool isArchive(Uint8List bytes) {
    if (bytes.length < _zipSignature.length) {
      return false;
    }
    for (var i = 0; i < _zipSignature.length; i++) {
      if (bytes[i] != _zipSignature[i]) {
        return false;
      }
    }
    return true;
  }

  Uint8List encode({required Map<String, dynamic> envelope, required Map<String, Uint8List> attachments}) {
    final archive = Archive();
    archive.addFile(ArchiveFile.string(BackupKeys.archiveBackupEntry, jsonEncode(envelope)));
    archive.addFile(ArchiveFile.string(BackupKeys.archiveManifestEntry, jsonEncode(_manifest(envelope, attachments))));
    for (final entry in attachments.entries) {
      archive.addFile(ArchiveFile.bytes(entry.key, entry.value));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  Result<BackupArchiveContents, AppError> decode(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      Map<String, dynamic>? envelope;
      final attachments = <String, Uint8List>{};
      for (final file in archive.files) {
        if (!file.isFile) {
          continue;
        }
        if (file.name == BackupKeys.archiveBackupEntry) {
          final decoded = jsonDecode(utf8.decode(file.content));
          if (decoded is! Map<String, dynamic>) {
            return Failure(ImportError('Backup root is not a JSON object'));
          }
          envelope = decoded;
        } else if (file.name.startsWith(BackupKeys.archiveAttachmentsPrefix)) {
          attachments[file.name] = file.content;
        }
      }
      if (envelope == null) {
        return Failure(ImportError('Backup archive has no ${BackupKeys.archiveBackupEntry}'));
      }
      return Success(BackupArchiveContents(envelope: envelope, attachments: attachments));
    } catch (error, stackTrace) {
      return Failure(ImportError('Backup archive is corrupt or unreadable', cause: error, causeStackTrace: stackTrace));
    }
  }

  Map<String, dynamic> _manifest(Map<String, dynamic> envelope, Map<String, Uint8List> attachments) {
    final metadata = envelope[BackupKeys.metadata];
    return <String, dynamic>{
      BackupKeys.version: BackupKeys.currentVersion,
      BackupKeys.createdAt: metadata is Map ? metadata[BackupKeys.createdAt] : null,
      BackupKeys.attachmentCount: attachments.length,
    };
  }
}
