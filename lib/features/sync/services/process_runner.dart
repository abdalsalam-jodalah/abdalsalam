// lib/features/sync/services/process_runner.dart — abstraction over running an external command, so adb can be faked in tests.

class ProcessOutcome {
  final int exitCode;
  final String stdout;
  final String stderr;

  const ProcessOutcome({required this.exitCode, this.stdout = '', this.stderr = ''});

  bool get isSuccess => exitCode == 0;
}

abstract interface class ProcessRunner {
  Future<ProcessOutcome> run(String executable, List<String> arguments);
}
