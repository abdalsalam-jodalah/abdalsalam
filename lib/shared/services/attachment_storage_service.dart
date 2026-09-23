import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import 'error_handler.dart';

/// Copies user-picked files into the app's local documents directory so
/// records can reference a stable path instead of a picker-cache path that
/// may be cleared by the OS.
class AttachmentStorageService {
  static const _serviceName = 'AttachmentStorageService';

  final String subDirectory;
  final LoggerService logger;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final _uuid = const Uuid();

  AttachmentStorageService({
    required this.logger,
    this.subDirectory = 'attachments',
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider = documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  Future<Result<String, AppError>> saveAttachment(String sourcePath) async {
    try {
      final documentsDir = await _documentsDirectoryProvider();
      final attachmentsDir = Directory('${documentsDir.path}/$subDirectory');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final extension = sourcePath.contains('.') ? sourcePath.split('.').last : '';
      final fileName = extension.isEmpty ? _uuid.v4() : '${_uuid.v4()}.$extension';
      final destinationPath = '${attachmentsDir.path}/$fileName';

      await File(sourcePath).copy(destinationPath);
      logger.info('[$_serviceName] saved attachment $destinationPath');
      return Success(destinationPath);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$_serviceName.saveAttachment', stackTrace: stackTrace));
    }
  }

  Future<Result<void, AppError>> deleteAttachment(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        logger.info('[$_serviceName] deleted attachment $path');
      }
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$_serviceName.deleteAttachment', stackTrace: stackTrace));
    }
  }

  Future<Result<void, AppError>> deleteAttachments(List<String> paths) async {
    AppError? firstFailure;
    var failedCount = 0;
    for (final path in paths) {
      final deletion = await deleteAttachment(path);
      if (deletion.isFailure) {
        failedCount++;
        firstFailure ??= deletion.error;
      }
    }
    if (firstFailure != null) {
      logger.warning('[$_serviceName] $failedCount of ${paths.length} attachments could not be deleted');
      return Failure(firstFailure);
    }
    return const Success(null);
  }
}
