import 'dart:async';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/features/settings/screens/restore_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/backup_service.dart';
import 'package:abdalsalam/shared/services/restore_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleReport = RestoreReport(
  restoredTableCount: 2,
  restoredRowCount: 5,
  skippedRowCount: 1,
  restoredPreferenceCount: 3,
  skippedUnknownTables: <String>[],
  safetyBackupPath: '/backups/safety.b64',
);

class _FakeBackupService extends BackupService {
  final Result<RestoreReport, AppError> restoreResult;
  final Duration restoreDelay;
  String? lastRestoredContent;

  _FakeBackupService({
    required this.restoreResult,
    this.restoreDelay = Duration.zero,
  }) : super(StorageGateway.instance, LoggerService.forModule('FakeBackupService'));

  @override
  Future<Result<RestoreReport, AppError>> restoreFromText(String content, {bool replace = false}) async {
    lastRestoredContent = content;
    if (restoreDelay > Duration.zero) {
      await Future<void>.delayed(restoreDelay);
    }
    return restoreResult;
  }
}

void main() {
  Widget host(BackupService service) => ProviderScope(
        overrides: [backupServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: RestoreScreen()),
      );

  testWidgets('should pass the pasted contents to the service and summarise the restore', (tester) async {
    final service = _FakeBackupService(restoreResult: const Success(_sampleReport));
    await tester.pumpWidget(host(service));

    await tester.enterText(find.byType(TextField), 'ZXlKaGJHY2lPaUpJVXpJMU5pSjk=');
    await tester.tap(find.text('Restore Pasted Backup'));
    await tester.pump();
    await tester.pump();

    expect(service.lastRestoredContent, 'ZXlKaGJHY2lPaUpJVXpJMU5pSjk=');
    expect(find.textContaining('Restored 5 records from 2 tables'), findsOneWidget);
    expect(find.textContaining('Skipped 1 invalid records'), findsOneWidget);
  });

  testWidgets('should show the friendly message, not the raw error, when restore fails', (tester) async {
    await tester.pumpWidget(host(_FakeBackupService(
      restoreResult: Failure(CorruptDataError('checksum mismatch')),
    )));

    await tester.enterText(find.byType(TextField), '{"metadata": {}, "data": {}}');
    await tester.tap(find.text('Restore Pasted Backup'));
    await tester.pump();
    await tester.pump();

    expect(find.text(UserErrorMessages.corruptData), findsOneWidget);
    expect(find.textContaining('checksum mismatch'), findsNothing);
  });

  testWidgets('should not crash when the screen is popped before restore finishes', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        backupServiceProvider.overrideWithValue(_FakeBackupService(
          restoreResult: const Success(_sampleReport),
          restoreDelay: const Duration(milliseconds: 200),
        )),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    ));

    unawaited(navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const RestoreScreen())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '{"metadata": {}, "data": {}}');
    await tester.tap(find.text('Restore Pasted Backup'));
    await tester.pump();

    navigatorKey.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
