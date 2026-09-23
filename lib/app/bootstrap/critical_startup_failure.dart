import 'startup_step_failure.dart';

class CriticalStartupFailure implements Exception {
  final StartupStepFailure failure;

  const CriticalStartupFailure(this.failure);

  @override
  String toString() => 'Startup step "${failure.stepName}" failed: ${failure.error}';
}
