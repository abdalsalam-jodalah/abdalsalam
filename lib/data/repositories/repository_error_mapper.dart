import '../../core/errors/app_error.dart';

class RepositoryErrorMapper {
  const RepositoryErrorMapper();

  AppError toAppError({
    required String table,
    required String operation,
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (error is AppError) {
      return error;
    }
    return DatabaseError('[$table] $operation failed', cause: error, causeStackTrace: stackTrace);
  }
}
