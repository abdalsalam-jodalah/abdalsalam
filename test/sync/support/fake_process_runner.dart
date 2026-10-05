// test/sync/support/fake_process_runner.dart — ProcessRunner fake that records calls and replies from a scripted table.

import 'package:abdalsalam/features/sync/services/process_runner.dart';

class FakeProcessRunner implements ProcessRunner {
  final Map<String, ProcessOutcome> responses = <String, ProcessOutcome>{};
  final Set<String> throwingCommands = <String>{};
  final List<String> invocations = <String>[];

  void respond(String commandLine, ProcessOutcome outcome) => responses[commandLine] = outcome;

  @override
  Future<ProcessOutcome> run(String executable, List<String> arguments) async {
    final commandLine = [executable, ...arguments].join(' ');
    invocations.add(commandLine);
    if (throwingCommands.contains(commandLine)) {
      throw Exception('cannot run $commandLine');
    }
    return responses[commandLine] ?? const ProcessOutcome(exitCode: 1);
  }
}
