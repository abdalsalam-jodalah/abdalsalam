// test/sync/adb_service_test.dart — verifies adb discovery, status resolution and reverse commands against a fake runner.

import 'package:abdalsalam/features/sync/services/adb_locator.dart';
import 'package:abdalsalam/features/sync/services/adb_reverse_command.dart';
import 'package:abdalsalam/features/sync/services/adb_service.dart';
import 'package:abdalsalam/features/sync/services/adb_status.dart';
import 'package:abdalsalam/features/sync/services/process_runner.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_process_runner.dart';

void main() {
  const homebrewAdb = '/opt/homebrew/bin/adb';
  const sdkAdb = '/Users/test/Library/Android/sdk/platform-tools/adb';
  const port = 47821;

  late FakeProcessRunner runner;
  late Set<String> existingFiles;

  AdbService buildService() {
    return AdbService(
      runner: runner,
      locator: AdbLocator(runner: runner, fileExists: existingFiles.contains, homeDirectory: '/Users/test'),
      logger: LoggerService.forModule('AdbServiceTest'),
    );
  }

  setUp(() {
    runner = FakeProcessRunner();
    existingFiles = <String>{};
  });

  group('locate', () {
    test('should prefer the adb found on PATH', () async {
      runner.respond('which adb', const ProcessOutcome(exitCode: 0, stdout: '/usr/bin/adb\n'));
      existingFiles.add(homebrewAdb);

      final path = await AdbLocator(
        runner: runner,
        fileExists: existingFiles.contains,
        homeDirectory: '/Users/test',
      ).locate();

      expect(path, '/usr/bin/adb');
    });

    test('should fall back to the homebrew path when which finds nothing', () async {
      existingFiles.add(homebrewAdb);

      final path = await AdbLocator(
        runner: runner,
        fileExists: existingFiles.contains,
        homeDirectory: '/Users/test',
      ).locate();

      expect(path, homebrewAdb);
    });

    test('should fall back to the Android SDK path and survive a throwing which', () async {
      runner.throwingCommands.add('which adb');
      existingFiles.add(sdkAdb);

      final path = await AdbLocator(
        runner: runner,
        fileExists: existingFiles.contains,
        homeDirectory: '/Users/test',
      ).locate();

      expect(path, sdkAdb);
    });

    test('should return null when adb is nowhere', () async {
      final path = await AdbLocator(
        runner: runner,
        fileExists: existingFiles.contains,
        homeDirectory: '/Users/test',
      ).locate();

      expect(path, isNull);
    });
  });

  group('checkStatus', () {
    setUp(() => existingFiles.add(homebrewAdb));

    test('should report adbMissing when adb cannot be found', () async {
      existingFiles.clear();

      final status = await buildService().checkStatus();

      expect(status.kind, AdbStatusKind.adbMissing);
    });

    test('should report noDevice when the list is empty', () async {
      runner.respond('$homebrewAdb devices', const ProcessOutcome(exitCode: 0, stdout: 'List of devices attached\n\n'));

      final status = await buildService().checkStatus();

      expect(status.kind, AdbStatusKind.noDevice);
    });

    test('should report unauthorized when the phone has not trusted the Mac', () async {
      runner.respond(
        '$homebrewAdb devices',
        const ProcessOutcome(exitCode: 0, stdout: 'List of devices attached\nABC\tunauthorized\n'),
      );

      final status = await buildService().checkStatus();

      expect(status.kind, AdbStatusKind.unauthorized);
    });

    test('should report offline when the device is offline', () async {
      runner.respond(
        '$homebrewAdb devices',
        const ProcessOutcome(exitCode: 0, stdout: 'List of devices attached\nABC\toffline\n'),
      );

      final status = await buildService().checkStatus();

      expect(status.kind, AdbStatusKind.offline);
    });

    test('should report ready with the serial of the first authorized device', () async {
      runner.respond(
        '$homebrewAdb devices',
        const ProcessOutcome(exitCode: 0, stdout: 'List of devices attached\nOLD\tunauthorized\nPHONE1\tdevice\n'),
      );

      final status = await buildService().checkStatus();

      expect(status, const AdbStatus.ready(deviceSerial: 'PHONE1', adbPath: homebrewAdb));
      expect(status.isReady, isTrue);
    });

    test('should report commandFailed when the process cannot be executed', () async {
      runner.throwingCommands.add('$homebrewAdb devices');

      final status = await buildService().checkStatus();

      expect(status.kind, AdbStatusKind.commandFailed);
      expect(status.isAdbAvailable, isFalse);
    });

    test('should report commandFailed when adb exits with an error', () async {
      runner.respond('$homebrewAdb devices', const ProcessOutcome(exitCode: 1, stderr: 'daemon error'));

      final status = await buildService().checkStatus();

      expect(status.kind, AdbStatusKind.commandFailed);
      expect(status.detail, 'daemon error');
    });
  });

  group('reverse', () {
    test('should run adb reverse for the port on the chosen device', () async {
      runner.respond('$homebrewAdb -s PHONE1 reverse tcp:$port tcp:$port', const ProcessOutcome(exitCode: 0));

      final result = await buildService().reverse(port, adbPath: homebrewAdb, serial: 'PHONE1');

      expect(result.isSuccess, isTrue);
      expect(runner.invocations, ['$homebrewAdb -s PHONE1 reverse tcp:$port tcp:$port']);
    });

    test('should run adb reverse without a serial when none is given', () async {
      runner.respond('$homebrewAdb reverse tcp:$port tcp:$port', const ProcessOutcome(exitCode: 0));

      final result = await buildService().reverse(port, adbPath: homebrewAdb);

      expect(result.isSuccess, isTrue);
    });

    test('should fail with the adb error text when reverse exits non-zero', () async {
      runner.respond(
        '$homebrewAdb reverse tcp:$port tcp:$port',
        const ProcessOutcome(exitCode: 1, stderr: 'no devices'),
      );

      final result = await buildService().reverse(port, adbPath: homebrewAdb);

      expect(result.isFailure, isTrue);
      expect(result.error!.message, contains('no devices'));
    });

    test('should fail without throwing when the process cannot run', () async {
      runner.throwingCommands.add('$homebrewAdb reverse tcp:$port tcp:$port');

      final result = await buildService().reverse(port, adbPath: homebrewAdb);

      expect(result.isFailure, isTrue);
    });

    test('should run adb reverse --remove for the port', () async {
      runner.respond('$homebrewAdb -s PHONE1 reverse --remove tcp:$port', const ProcessOutcome(exitCode: 0));

      final result = await buildService().removeReverse(port, adbPath: homebrewAdb, serial: 'PHONE1');

      expect(result.isSuccess, isTrue);
    });
  });

  test('should build the exact manual command text', () {
    expect(AdbReverseCommand.manualText(port), 'adb reverse tcp:$port tcp:$port');
  });
}
