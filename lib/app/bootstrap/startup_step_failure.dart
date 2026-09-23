class StartupStepFailure {
  final String stepName;
  final Object error;
  final StackTrace stackTrace;

  const StartupStepFailure({
    required this.stepName,
    required this.error,
    required this.stackTrace,
  });
}
