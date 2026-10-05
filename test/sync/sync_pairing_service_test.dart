// test/sync/sync_pairing_service_test.dart — verifies PIN generation, session tokens and the wrong-PIN lockout.

import 'dart:math';

import 'package:abdalsalam/core/constants/sync_constants.dart';
import 'package:abdalsalam/features/sync/services/sync_errors.dart';
import 'package:abdalsalam/features/sync/services/sync_pairing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late SyncPairingService pairing;
  late String pin;

  String wrongPinFor(String correct) => correct == '000000' ? '111111' : '000000';

  setUp(() {
    now = DateTime(2026, 10, 6, 9);
    pairing = SyncPairingService(random: Random(7), clock: () => now);
    pin = pairing.startPairing();
  });

  test('should generate a numeric PIN of the configured length', () {
    expect(pin, matches(RegExp('^\\d{${SyncConstants.pinLength}}\$')));
    expect(pairing.pin, pin);
  });

  test('should return a session token when the PIN is correct', () {
    final result = pairing.verifyPin(pin);

    expect(result.isSuccess, isTrue);
    expect(pairing.isValidToken(result.data), isTrue);
  });

  test('should reject a wrong PIN and report the remaining attempts', () {
    final result = pairing.verifyPin(wrongPinFor(pin));

    expect(result.error, isA<SyncPinRejectedError>());
    expect((result.error as SyncPinRejectedError).remainingAttempts, SyncConstants.maxFailedPinAttempts - 1);
  });

  test('should lock out after the maximum number of wrong PINs even when the right PIN follows', () {
    for (var attempt = 0; attempt < SyncConstants.maxFailedPinAttempts; attempt++) {
      pairing.verifyPin(wrongPinFor(pin));
    }

    final result = pairing.verifyPin(pin);

    expect(pairing.isLockedOut, isTrue);
    expect(result.error, isA<SyncLockedOutError>());
  });

  test('should clear the lockout when pairing is restarted', () {
    for (var attempt = 0; attempt < SyncConstants.maxFailedPinAttempts; attempt++) {
      pairing.verifyPin(wrongPinFor(pin));
    }

    final newPin = pairing.startPairing();

    expect(pairing.isLockedOut, isFalse);
    expect(pairing.verifyPin(newPin).isSuccess, isTrue);
  });

  test('should refuse a second session while one is active', () {
    pairing.verifyPin(pin);

    final result = pairing.verifyPin(pin);

    expect(result.error, isA<SyncSessionBusyError>());
  });

  test('should accept a new session after the previous one ended', () {
    final first = pairing.verifyPin(pin).data;
    pairing.endSession();

    expect(pairing.isValidToken(first), isFalse);
    expect(pairing.verifyPin(pin).isSuccess, isTrue);
  });

  test('should expire an idle session so a new device can connect', () {
    final token = pairing.verifyPin(pin).data;
    now = now.add(SyncConstants.sessionIdleTimeout + const Duration(seconds: 1));

    expect(pairing.isValidToken(token), isFalse);
    expect(pairing.verifyPin(pin).isSuccess, isTrue);
  });

  test('should reject unknown and missing tokens', () {
    pairing.verifyPin(pin);

    expect(pairing.isValidToken('not-the-token'), isFalse);
    expect(pairing.isValidToken(null), isFalse);
  });

  test('should reject every PIN after pairing is stopped', () {
    pairing.stopPairing();

    expect(pairing.pin, isNull);
    expect(pairing.verifyPin(pin).error, isA<SyncUnauthorizedError>());
  });
}
