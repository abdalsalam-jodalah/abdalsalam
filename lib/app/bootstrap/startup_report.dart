import 'startup_step_failure.dart';

class StartupReport {
  final List<StartupStepFailure> degradedSteps;

  const StartupReport({this.degradedSteps = const <StartupStepFailure>[]});

  bool get isDegraded => degradedSteps.isNotEmpty;

  List<String> get degradedStepNames => degradedSteps.map((failure) => failure.stepName).toList(growable: false);
}
