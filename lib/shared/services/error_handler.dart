import '../../core/errors/app_error.dart';
import '../infrastructure/logger_service.dart';

class ErrorHandler {
  final LoggerService logger;

  const ErrorHandler(this.logger);

  AppError mapException(
    Object error, {
    String context = 'Unknown context',
    StackTrace? stackTrace,
  }) {
    if (error is AppError) {
      logger.warning('[ErrorHandler] [$context] ${error.toString()}');
      return error;
    }

    final message = error.toString();
    final mapped = _byMessage(message);
    logger.error('[ErrorHandler] [$context] ${mapped.toString()}', error: error, stackTrace: stackTrace);
    return mapped;
  }

  String toUserMessage(AppError error) {
    switch (error.code) {
      case 'VALIDATION_ERROR':
        if (error is ValidationError && error.fieldErrors.isNotEmpty) {
          return error.fieldErrors.values.first;
        }
        return 'Please review the highlighted fields and try again.';
      case 'NOT_FOUND':
        return 'The requested item could not be found.';
      case 'NETWORK_ERROR':
        return 'No internet connection. Your action was queued and will sync later.';
      case 'AUTH_ERROR':
        return 'Authentication is required for this action.';
      case 'EXPORT_ERROR':
        return 'Export failed. Please try again.';
      case 'IMPORT_ERROR':
        return 'Import failed. Please verify the selected file.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  AppError _byMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('socket') || lower.contains('network')) {
      return NetworkError(message);
    }
    if (lower.contains('auth') || lower.contains('permission denied')) {
      return AuthError(message);
    }
    if (lower.contains('not found')) {
      return NotFoundError(message);
    }
    if (lower.contains('validation') || lower.contains('invalid')) {
      return ValidationError(message);
    }
    if (lower.contains('import')) {
      return ImportError(message);
    }
    if (lower.contains('export')) {
      return ExportError(message);
    }
    if (lower.contains('database') || lower.contains('sqlite')) {
      return DatabaseError(message);
    }
    return ServiceError(message);
  }
}
