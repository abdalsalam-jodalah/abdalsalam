import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../shared/infrastructure/logger_service.dart';
import 'repository_error_mapper.dart';

class RepositoryOperationGuard {
  static const RepositoryErrorMapper _errorMapper = RepositoryErrorMapper();

  final String table;
  final LoggerService logger;

  const RepositoryOperationGuard({required this.table, required this.logger});

  Future<Result<R, AppError>> run<R>(String operation, Future<R> Function() body) {
    return Result.guardAsync<R, AppError>(body, onError: (error, stackTrace) {
      logger.error('[$table] $operation failed', error: error, stackTrace: stackTrace);
      return _errorMapper.toAppError(
        table: table,
        operation: operation,
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
}
