import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../infrastructure/logger_service.dart';

/// Copies user-picked files into the app's local documents directory so
/// records can reference a stable path instead of a picker-cache path that
/// may be cleared by the OS.
class AttachmentStorageService {
  static const _attachmentsDirName = 'health_attachments';
  final LoggerService logger;
  final _uuid = const Uuid();

  AttachmentStorageService({required this.logger});

  Future<String> saveAttachment(String sourcePath) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${documentsDir.path}/$_attachmentsDirName');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final extension = sourcePath.contains('.') ? sourcePath.split('.').last : '';
    final fileName = extension.isEmpty ? _uuid.v4() : '${_uuid.v4()}.$extension';
    final destinationPath = '${attachmentsDir.path}/$fileName';

    await File(sourcePath).copy(destinationPath);
    logger.info('[AttachmentStorageService] saved attachment $destinationPath');
    return destinationPath;
  }

  Future<void> deleteAttachment(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      logger.info('[AttachmentStorageService] deleted attachment $path');
    }
  }

  Future<void> deleteAttachments(List<String> paths) async {
    for (final path in paths) {
      await deleteAttachment(path);
    }
  }
}
