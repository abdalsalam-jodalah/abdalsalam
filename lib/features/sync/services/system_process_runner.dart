// lib/features/sync/services/system_process_runner.dart — ProcessRunner backed by dart:io Process.run with a timeout.

import 'dart:io';

import '../../../core/constants/adb_constants.dart';
import 'process_runner.dart';

class SystemProcessRunner implements ProcessRunner {
  final Duration timeout;

  const SystemProcessRunner({this.timeout = AdbConstants.commandTimeout});

  @override
  Future<ProcessOutcome> run(String executable, List<String> arguments) async {
    final result = await Process.run(executable, arguments).timeout(timeout);
    return ProcessOutcome(exitCode: result.exitCode, stdout: '${result.stdout}', stderr: '${result.stderr}');
  }
}
