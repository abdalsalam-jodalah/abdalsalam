import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../../core/errors/app_error.dart';
import '../infrastructure/logger_service.dart';

class ErrorHandler {
  final LoggerService logger;

  const ErrorHandler(this.logger);

  AppError mapException(
    Object error, {
    required String context,
    StackTrace? stackTrace,
  }) {
    final mapped = _mapByType(error, stackTrace);
    logger.error('[$context] ${mapped.code}: ${mapped.message}', error: error, stackTrace: stackTrace);
    return mapped;
  }

  AppError _mapByType(Object error, StackTrace? stackTrace) {
    if (error is AppError) {
      return error;
    }
    if (error is DatabaseException) {
      return DatabaseError(error.toString(), cause: error, causeStackTrace: stackTrace);
    }
    if (error is FormatException || error is TypeError) {
      return CorruptDataError(error.toString(), cause: error, causeStackTrace: stackTrace);
    }
    if (error is TimeoutException ||
        error is SocketException ||
        error is HttpException ||
        error is http.ClientException) {
      return NetworkError(error.toString(), cause: error, causeStackTrace: stackTrace);
    }
    return ServiceError(error.toString(), cause: error, causeStackTrace: stackTrace);
  }
}
