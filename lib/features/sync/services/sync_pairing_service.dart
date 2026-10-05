// lib/features/sync/services/sync_pairing_service.dart — issues the pairing PIN, validates it and owns the single session token.

import 'dart:convert';
import 'dart:math';

import '../../../core/constants/sync_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import 'sync_errors.dart';

class SyncPairingService {
  static const int _pinRadix = 10;
  static const int _byteValueCount = 256;

  final Random _random;
  final DateTime Function() _clock;
  final int pinLength;
  final int maxFailedAttempts;
  final Duration sessionIdleTimeout;

  String? _pin;
  String? _token;
  int _failedAttempts = 0;
  DateTime _lastActivityAt = DateTime.fromMillisecondsSinceEpoch(0);

  SyncPairingService({
    Random? random,
    DateTime Function()? clock,
    this.pinLength = SyncConstants.pinLength,
    this.maxFailedAttempts = SyncConstants.maxFailedPinAttempts,
    this.sessionIdleTimeout = SyncConstants.sessionIdleTimeout,
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now;

  String? get pin => _pin;

  bool get isLockedOut => _failedAttempts >= maxFailedAttempts;

  bool get hasActiveSession {
    if (_token != null && _clock().difference(_lastActivityAt) > sessionIdleTimeout) {
      _token = null;
    }
    return _token != null;
  }

  String startPairing() {
    final digits = StringBuffer();
    for (var index = 0; index < pinLength; index++) {
      digits.write(_random.nextInt(_pinRadix));
    }
    _pin = digits.toString();
    _token = null;
    _failedAttempts = 0;
    return _pin!;
  }

  void stopPairing() {
    _pin = null;
    _token = null;
    _failedAttempts = 0;
  }

  Result<String, AppError> verifyPin(String candidate) {
    final expected = _pin;
    if (expected == null) {
      return Failure(SyncUnauthorizedError());
    }
    if (isLockedOut) {
      return Failure(SyncLockedOutError());
    }
    if (hasActiveSession) {
      return Failure(SyncSessionBusyError());
    }
    if (!_constantTimeEquals(expected, candidate)) {
      _failedAttempts++;
      return Failure(isLockedOut ? SyncLockedOutError() : SyncPinRejectedError(maxFailedAttempts - _failedAttempts));
    }
    _failedAttempts = 0;
    _token = _generateToken();
    _lastActivityAt = _clock();
    return Success(_token!);
  }

  bool isValidToken(String? candidate) {
    if (candidate == null || !hasActiveSession || !_constantTimeEquals(_token!, candidate)) {
      return false;
    }
    _lastActivityAt = _clock();
    return true;
  }

  void endSession() {
    _token = null;
  }

  String _generateToken() {
    final bytes = List<int>.generate(SyncConstants.sessionTokenByteLength, (_) => _random.nextInt(_byteValueCount));
    return base64UrlEncode(bytes);
  }

  bool _constantTimeEquals(String expected, String candidate) {
    var difference = expected.length ^ candidate.length;
    final length = min(expected.length, candidate.length);
    for (var index = 0; index < length; index++) {
      difference |= expected.codeUnitAt(index) ^ candidate.codeUnitAt(index);
    }
    return difference == 0;
  }
}
