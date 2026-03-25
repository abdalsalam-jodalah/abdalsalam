class AppError extends Error {
  final String message;
  final String code;

  AppError(this.message, {this.code = 'APP_ERROR'});

  @override
  String toString() => '$code: $message';
}

class ValidationError extends AppError {
  ValidationError(super.message) : super(code: 'VALIDATION_ERROR');
}

class NotFoundError extends AppError {
  NotFoundError(super.message) : super(code: 'NOT_FOUND');
}

class DatabaseError extends AppError {
  DatabaseError(super.message) : super(code: 'DATABASE_ERROR');
}

class ImportExportError extends AppError {
  ImportExportError(super.message) : super(code: 'IMPORT_EXPORT_ERROR');
}
