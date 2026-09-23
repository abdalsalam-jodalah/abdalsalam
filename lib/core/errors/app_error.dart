import 'app_error_code.dart';

class AppError extends Error {
  final String message;
  final String code;
  final Object? cause;
  final StackTrace? causeStackTrace;

  AppError(
    this.message, {
    this.code = AppErrorCode.app,
    this.cause,
    this.causeStackTrace,
  });

  @override
  String toString() => '$code: $message';
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  ValidationError(super.message, {this.fieldErrors = const <String, String>{}})
      : super(code: AppErrorCode.validation);
}

class NotFoundError extends AppError {
  NotFoundError(super.message) : super(code: AppErrorCode.notFound);
}

class DatabaseError extends AppError {
  DatabaseError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.database);
}

class CorruptDataError extends AppError {
  final String? source;
  final String? field;

  CorruptDataError(
    super.message, {
    this.source,
    this.field,
    super.cause,
    super.causeStackTrace,
  }) : super(code: AppErrorCode.corruptData);
}

class StorageUnavailableError extends AppError {
  StorageUnavailableError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.storageUnavailable);
}

class ServiceError extends AppError {
  ServiceError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.service);
}

class ExportError extends AppError {
  ExportError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.export);
}

class ImportError extends AppError {
  ImportError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.import);
}

class ImportExportError extends AppError {
  ImportExportError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.importExport);
}

class NetworkError extends AppError {
  NetworkError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.network);
}

class AuthError extends AppError {
  AuthError(super.message, {super.cause, super.causeStackTrace})
      : super(code: AppErrorCode.auth);
}
