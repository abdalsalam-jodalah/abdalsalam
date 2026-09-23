class BootstrapStep {
  static const Duration optionalStepTimeout = Duration(seconds: 10);

  final String name;
  final bool isCritical;
  final Future<void> Function() run;

  const BootstrapStep.critical(this.name, this.run) : isCritical = true;

  const BootstrapStep.optional(this.name, this.run) : isCritical = false;
}
