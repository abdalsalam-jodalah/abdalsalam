import 'dart:async';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/features/settings/screens/backup_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackupService extends BackupService {
  final Result<String, AppError> createResult;
  final Result<String, AppError> saveResult;
  final Duration createDelay;

  _FakeBackupService({
    required this.createResult,
    required this.saveResult,
    this.createDelay = Duration.zero,
  }) : super(StorageGateway.instance, LoggerService.forModule('FakeBackupService'));

  @override
  Future<Result<String, AppError>> createCompressedBackup({
    required List<String> tables,
    List<String>? onlyModules,
    DateTime? start,
    DateTime? end,
  }) async {
    if (createDelay > Duration.zero) {
      await Future<void>.delayed(createDelay);
    }
    return createResult;
  }

  @override
  Future<Result<String, AppError>> saveBackupToDevice({
    required String content,
    String fileName = 'abdalsalam-backup.json',
  }) async {
    return saveResult;
  }
}

void main() {
  Widget host(BackupService service) => ProviderScope(
        overrides: [backupServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: BackupScreen()),
      );

  testWidgets('should show the friendly message, not the raw error, when creating a backup fails', (tester) async {
    await tester.pumpWidget(host(_FakeBackupService(
      createResult: Failure(DatabaseError('SqfliteException: disk full')),
      saveResult: const Success('unused'),
    )));

    await tester.tap(find.text('Create Full Backup'));
    await tester.pump();
    await tester.pump();

    expect(find.text(UserErrorMessages.database), findsOneWidget);
    expect(find.textContaining('SqfliteException'), findsNothing);

    final shareButton = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Share Last Backup'));
    expect(shareButton.onPressed, isNull);
  });

  testWidgets('should not crash when the screen is popped before the backup finishes', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        backupServiceProvider.overrideWithValue(_FakeBackupService(
          createResult: const Success('encoded-backup'),
          saveResult: const Success('/tmp/backup.b64'),
          createDelay: const Duration(milliseconds: 200),
        )),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    ));

    unawaited(navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const BackupScreen())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Full Backup'));
    await tester.pump();

    navigatorKey.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
