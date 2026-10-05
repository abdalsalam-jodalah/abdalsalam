// lib/features/sync/services/sync_error_codec.dart — translates sync failures to HTTP responses and back.

import 'dart:io';

import '../../../core/errors/app_error.dart';
import 'sync_errors.dart';
import 'sync_protocol.dart';

class SyncErrorCodes {
  const SyncErrorCodes._();

  static const String pinRejected = 'PIN_REJECTED';
  static const String lockedOut = 'LOCKED_OUT';
  static const String sessionBusy = 'SESSION_BUSY';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String badRequest = 'BAD_REQUEST';
  static const String versionMismatch = 'VERSION_MISMATCH';
  static const String payloadTooLarge = 'PAYLOAD_TOO_LARGE';
  static const String internal = 'INTERNAL';
}

class SyncErrorResponse {
  final int statusCode;
  final SyncErrorBody body;

  const SyncErrorResponse(this.statusCode, this.body);
}

class SyncErrorCodec {
  const SyncErrorCodec();

  SyncErrorResponse encode(Object error) {
    return switch (error) {
      SyncPinRejectedError() => SyncErrorResponse(
        HttpStatus.unauthorized,
        SyncErrorBody(
          code: SyncErrorCodes.pinRejected,
          message: error.message,
          remainingAttempts: error.remainingAttempts,
        ),
      ),
      SyncLockedOutError() => _response(HttpStatus.locked, SyncErrorCodes.lockedOut, error.message),
      SyncSessionBusyError() => _response(HttpStatus.conflict, SyncErrorCodes.sessionBusy, error.message),
      SyncUnauthorizedError() => _response(HttpStatus.unauthorized, SyncErrorCodes.unauthorized, error.message),
      SyncVersionMismatchError() => _response(HttpStatus.badRequest, SyncErrorCodes.versionMismatch, error.message),
      SyncBadRequestError() => _response(HttpStatus.badRequest, SyncErrorCodes.badRequest, error.message),
      FormatException() => _response(HttpStatus.badRequest, SyncErrorCodes.badRequest, error.message),
      _ => _response(
        HttpStatus.internalServerError,
        SyncErrorCodes.internal,
        'The other device failed to process the request',
      ),
    };
  }

  SyncErrorResponse payloadTooLarge() {
    return _response(HttpStatus.requestEntityTooLarge, SyncErrorCodes.payloadTooLarge, 'The request is too large');
  }

  AppError decode(SyncErrorBody body) {
    return switch (body.code) {
      SyncErrorCodes.pinRejected => SyncPinRejectedError(body.remainingAttempts),
      SyncErrorCodes.lockedOut => SyncLockedOutError(),
      SyncErrorCodes.sessionBusy => SyncSessionBusyError(),
      SyncErrorCodes.unauthorized => SyncUnauthorizedError(),
      SyncErrorCodes.versionMismatch => SyncVersionMismatchError(),
      SyncErrorCodes.badRequest => SyncBadRequestError(body.message),
      _ => ServiceError(body.message),
    };
  }

  SyncErrorResponse _response(int statusCode, String code, String message) {
    return SyncErrorResponse(statusCode, SyncErrorBody(code: code, message: message));
  }
}
