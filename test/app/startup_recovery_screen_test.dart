import 'package:abdalsalam/app/bootstrap/critical_startup_failure.dart';
import 'package:abdalsalam/app/bootstrap/startup_recovery_screen.dart';
import 'package:abdalsalam/app/bootstrap/startup_step_failure.dart';
import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CriticalStartupFailure storageFailure() => CriticalStartupFailure(
        StartupStepFailure(
          stepName: 'Storage',
          error: StorageUnavailableError('SqfliteException: disk I/O error'),
          stackTrace: StackTrace.empty,
        ),
      );

  testWidgets('should show a friendly message and the failed step, not the raw error', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StartupRecoveryScreen(error: storageFailure(), stackTrace: null, onRetry: () {}),
    ));

    expect(find.text(UserErrorMessages.storageUnavailable), findsOneWidget);
    expect(find.text('Failed step: Storage'), findsOneWidget);
    expect(find.textContaining('SqfliteException'), findsNothing);
  });

  testWidgets('should call onRetry when Try again is tapped', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: StartupRecoveryScreen(error: storageFailure(), stackTrace: null, onRetry: () => retryCount++),
    ));

    await tester.tap(find.text('Try again'));

    expect(retryCount, 1);
  });
}
