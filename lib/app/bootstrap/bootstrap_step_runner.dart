import 'dart:async';

import '../../shared/infrastructure/logger_service.dart';
import 'bootstrap_step.dart';
import 'critical_startup_failure.dart';
import 'startup_report.dart';
import 'startup_step_failure.dart';

class BootstrapStepRunner {
  final LoggerService Function() loggerFactory;
  final Duration optionalStepTimeout;

  const BootstrapStepRunner({
    required this.loggerFactory,
    this.optionalStepTimeout = BootstrapStep.optionalStepTimeout,
  });

  Future<StartupReport> runAll(List<BootstrapStep> steps) async {
    final degradedSteps = <StartupStepFailure>[];
    for (final step in steps) {
      final stopwatch = Stopwatch()..start();
      final execution = step.run();
      try {
        if (step.isCritical) {
          await execution;
        } else {
          await execution.timeout(optionalStepTimeout);
        }
        loggerFactory().info('[Bootstrap] ${step.name} finished in ${stopwatch.elapsedMilliseconds}ms');
      } on TimeoutException {
        loggerFactory().warning(
          '[Bootstrap] ${step.name} is still running after ${optionalStepTimeout.inSeconds}s; continuing in background',
        );
        _watchInBackground(step, execution, stopwatch);
      } catch (error, stackTrace) {
        final failure = StartupStepFailure(stepName: step.name, error: error, stackTrace: stackTrace);
        loggerFactory().error(
          '[Bootstrap] ${step.name} failed after ${stopwatch.elapsedMilliseconds}ms '
          '(${step.isCritical ? 'critical' : 'optional'})',
          error: error,
          stackTrace: stackTrace,
        );
        if (step.isCritical) {
          throw CriticalStartupFailure(failure);
        }
        degradedSteps.add(failure);
      }
    }
    return StartupReport(degradedSteps: degradedSteps);
  }

  void _watchInBackground(BootstrapStep step, Future<void> execution, Stopwatch stopwatch) {
    unawaited(execution.then(
      (_) => loggerFactory().info('[Bootstrap] ${step.name} finished in background after ${stopwatch.elapsedMilliseconds}ms'),
      onError: (Object error, StackTrace stackTrace) => loggerFactory().error(
        '[Bootstrap] ${step.name} failed in background after ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      ),
    ));
  }
}
