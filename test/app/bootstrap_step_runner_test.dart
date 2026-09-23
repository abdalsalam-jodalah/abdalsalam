import 'dart:async';

import 'package:abdalsalam/app/bootstrap/bootstrap_step.dart';
import 'package:abdalsalam/app/bootstrap/bootstrap_step_runner.dart';
import 'package:abdalsalam/app/bootstrap/critical_startup_failure.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BootstrapStepRunner runner;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    runner = BootstrapStepRunner(
      loggerFactory: () => LoggerService.forModule('BootstrapTest'),
      optionalStepTimeout: const Duration(milliseconds: 50),
    );
  });

  group('BootstrapStepRunner', () {
    test('should run every step in order and report no degradation', () async {
      final executed = <String>[];

      final report = await runner.runAll([
        BootstrapStep.critical('a', () async => executed.add('a')),
        BootstrapStep.optional('b', () async => executed.add('b')),
      ]);

      expect(executed, ['a', 'b']);
      expect(report.isDegraded, isFalse);
    });

    test('should keep going and report an optional step that fails', () async {
      final executed = <String>[];

      final report = await runner.runAll([
        BootstrapStep.optional('Notifications', () async => throw StateError('no permission')),
        BootstrapStep.optional('Reminders', () async => executed.add('Reminders')),
      ]);

      expect(executed, ['Reminders']);
      expect(report.degradedStepNames, ['Notifications']);
      expect(report.degradedSteps.single.error, isA<StateError>());
    });

    test('should stop and throw CriticalStartupFailure when a critical step fails', () async {
      final executed = <String>[];

      final run = runner.runAll([
        BootstrapStep.critical('Storage', () async => throw StateError('disk full')),
        BootstrapStep.optional('Settings', () async => executed.add('Settings')),
      ]);

      await expectLater(
        run,
        throwsA(isA<CriticalStartupFailure>().having((failure) => failure.failure.stepName, 'stepName', 'Storage')),
      );
      expect(executed, isEmpty);
    });

    test('should not block startup on a slow optional step and let it finish in background', () async {
      final slowStep = Completer<void>();
      final executed = <String>[];

      final report = await runner.runAll([
        BootstrapStep.optional('Notifications', () => slowStep.future),
        BootstrapStep.optional('Next', () async => executed.add('Next')),
      ]);
      slowStep.complete();
      await Future<void>.delayed(Duration.zero);

      expect(executed, ['Next']);
      expect(report.isDegraded, isFalse);
    });
  });
}
