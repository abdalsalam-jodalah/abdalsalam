// lib/features/sync/services/sync_errors.dart — typed failures raised by device sync pairing and protocol handling.

import '../../../core/errors/app_error.dart';

class SyncPinRejectedError extends AuthError {
  final int remainingAttempts;

  SyncPinRejectedError(this.remainingAttempts) : super('The pairing PIN is incorrect');
}

class SyncLockedOutError extends AuthError {
  SyncLockedOutError() : super('Too many wrong PINs; restart the link on the other device');
}

class SyncSessionBusyError extends AuthError {
  SyncSessionBusyError() : super('Another sync session is already in progress');
}

class SyncUnauthorizedError extends AuthError {
  SyncUnauthorizedError() : super('The sync session is missing or has expired');
}

class SyncBadRequestError extends ServiceError {
  SyncBadRequestError(super.message);
}

class SyncVersionMismatchError extends ServiceError {
  SyncVersionMismatchError() : super('The other device runs an incompatible sync version');
}
