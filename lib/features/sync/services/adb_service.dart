// lib/features/sync/services/adb_service.dart — checks adb and the connected phone, and manages the adb reverse tunnel.

import '../../../core/constants/adb_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import 'adb_device.dart';
import 'adb_device_parser.dart';
import 'adb_locator.dart';
import 'adb_reverse_command.dart';
import 'adb_status.dart';
import 'process_runner.dart';

class AdbService {
  final ProcessRunner runner;
  final AdbLocator locator;
  final LoggerService logger;
  final AdbDeviceParser _parser = const AdbDeviceParser();

  AdbService({required this.runner, required this.locator, required this.logger});

  Future<AdbStatus> checkStatus() async {
    final adbPath = await locator.locate();
    if (adbPath == null) {
      return const AdbStatus.adbMissing();
    }
    final ProcessOutcome outcome;
    try {
      outcome = await runner.run(adbPath, const <String>[AdbConstants.devicesCommand]);
    } catch (error) {
      logger.warning('[AdbService] could not run adb at $adbPath: $error');
      return AdbStatus.commandFailed(adbPath: adbPath, detail: '$error');
    }
    if (!outcome.isSuccess) {
      return AdbStatus.commandFailed(adbPath: adbPath, detail: outcome.stderr.trim());
    }
    return _statusOf(_parser.parse(outcome.stdout), adbPath);
  }

  Future<Result<void, AppError>> reverse(int port, {required String adbPath, String? serial}) {
    return _run(adbPath, AdbReverseCommand.add(port, serial: serial));
  }

  Future<Result<void, AppError>> removeReverse(int port, {required String adbPath, String? serial}) {
    return _run(adbPath, AdbReverseCommand.remove(port, serial: serial));
  }

  AdbStatus _statusOf(List<AdbDevice> devices, String adbPath) {
    for (final device in devices) {
      if (device.state == AdbDeviceState.ready) {
        return AdbStatus.ready(deviceSerial: device.serial, adbPath: adbPath);
      }
    }
    if (devices.any((device) => device.state == AdbDeviceState.unauthorized)) {
      return AdbStatus.unauthorized(adbPath: adbPath);
    }
    if (devices.any((device) => device.state == AdbDeviceState.offline)) {
      return AdbStatus.offline(adbPath: adbPath);
    }
    return AdbStatus.noDevice(adbPath: adbPath);
  }

  Future<Result<void, AppError>> _run(String adbPath, List<String> arguments) async {
    try {
      final outcome = await runner.run(adbPath, arguments);
      if (outcome.isSuccess) {
        return const Success<void, AppError>(null);
      }
      return Failure(ServiceError(_failureMessage(arguments, outcome)));
    } catch (error, stackTrace) {
      logger.warning('[AdbService] adb ${arguments.join(' ')} failed: $error');
      return Failure(
        ServiceError('adb ${arguments.join(' ')} could not run', cause: error, causeStackTrace: stackTrace),
      );
    }
  }

  String _failureMessage(List<String> arguments, ProcessOutcome outcome) {
    final detail = outcome.stderr.trim().isNotEmpty ? outcome.stderr.trim() : outcome.stdout.trim();
    return 'adb ${arguments.join(' ')} exited with ${outcome.exitCode}${detail.isEmpty ? '' : ': $detail'}';
  }
}
