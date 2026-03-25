class AppError extends Error {
  final String message;
  final String code;

  AppError(this.message, {this.code = 'APP_ERROR'});

  @override
  String toString() => '$code: $message';
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  ValidationError(super.message, {this.fieldErrors = const <String, String>{}})
      : super(code: 'VALIDATION_ERROR');
}

class NotFoundError extends AppError {
  NotFoundError(super.message) : super(code: 'NOT_FOUND');
}

class DatabaseError extends AppError {
  DatabaseError(super.message) : super(code: 'DATABASE_ERROR');
}

class ServiceError extends AppError {
  ServiceError(super.message) : super(code: 'SERVICE_ERROR');
}

class ExportError extends AppError {
  ExportError(super.message) : super(code: 'EXPORT_ERROR');
}

class ImportError extends AppError {
  ImportError(super.message) : super(code: 'IMPORT_ERROR');
}

class ImportExportError extends AppError {
  ImportExportError(super.message) : super(code: 'IMPORT_EXPORT_ERROR');
}

class NetworkError extends AppError {
  NetworkError(super.message) : super(code: 'NETWORK_ERROR');
}

class AuthError extends AppError {
  AuthError(super.message) : super(code: 'AUTH_ERROR');
}
