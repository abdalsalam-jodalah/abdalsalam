import 'dart:async';
import 'dart:typed_data';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/features/settings/screens/backup_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/backup_archive.dart';
import 'package:abdalsalam/shared/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _sampleArchive = BackupArchive(
  bytes: Uint8List.fromList(<int>[1, 2, 3]),
  attachmentCount: 0,
  missingAttachmentCount: 0,
);

class _FakeBackupService extends BackupService {
  final Result<BackupArchive, AppError> createResult;
  final Result<String?, AppError> saveAsResult;
  final Duration createDelay;
  String? sharedPath;
  Uint8List? savedAsBytes;

  _FakeBackupService({
    required this.createResult,
    this.saveAsResult = const Success('/Download/backup.zip'),
    this.createDelay = Duration.zero,
  }) : super(StorageGateway.instance, LoggerService.forModule('FakeBackupService'));

  @override
  Future<Result<BackupArchive, AppError>> createBackupArchive({
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
  Future<Result<String?, AppError>> saveBackupAs({required Uint8List bytes, required String fileName}) async {
    savedAsBytes = bytes;
    return saveAsResult;
  }

  @override
  Future<Result<String, AppError>> saveBackupToDevice({
    required Uint8List bytes,
    String fileName = 'abdalsalam-backup.zip',
  }) async {
    return const Success('/app/backup.zip');
  }

  @override
  Future<Result<void, AppError>> shareBackup(String filePath) async {
    sharedPath = filePath;
    return const Success(null);
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
    )));

    await tester.tap(find.text('Save to device'));
    await tester.pump();
    await tester.pump();

    expect(find.text(UserErrorMessages.database), findsOneWidget);
    expect(find.textContaining('SqfliteException'), findsNothing);
    expect(find.text('Backup failed'), findsOneWidget);
  });

  testWidgets('should save the backup bytes through the save-as picker and show where it went', (tester) async {
    final service = _FakeBackupService(createResult: Success(_sampleArchive));
    await tester.pumpWidget(host(service));

    await tester.tap(find.text('Save to device'));
    await tester.pump();
    await tester.pump();

    expect(service.savedAsBytes, [1, 2, 3]);
    expect(find.text('Backup saved: /Download/backup.zip'), findsOneWidget);
  });

  testWidgets('should say the save was cancelled when the picker is dismissed', (tester) async {
    await tester.pumpWidget(host(_FakeBackupService(
      createResult: Success(_sampleArchive),
      saveAsResult: const Success(null),
    )));

    await tester.tap(find.text('Save to device'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Save cancelled'), findsOneWidget);
  });

  testWidgets('should warn when attached files were missing from the backup', (tester) async {
    await tester.pumpWidget(host(_FakeBackupService(
      createResult: Success(BackupArchive(bytes: Uint8List(1), attachmentCount: 1, missingAttachmentCount: 2)),
    )));

    await tester.tap(find.text('Save to device'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('2 attached files could not be found'), findsOneWidget);
  });

  testWidgets('should save the backup into the app folder and hand that file to the share sheet', (tester) async {
    final service = _FakeBackupService(createResult: Success(_sampleArchive));
    await tester.pumpWidget(host(service));

    await tester.tap(find.text('Share backup'));
    await tester.pump();
    await tester.pump();

    expect(service.sharedPath, '/app/backup.zip');
    expect(find.text('Backup shared successfully'), findsOneWidget);
  });

  testWidgets('should not crash when the screen is popped before the backup finishes', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        backupServiceProvider.overrideWithValue(_FakeBackupService(
          createResult: Success(_sampleArchive),
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

    await tester.tap(find.text('Save to device'));
    await tester.pump();

    navigatorKey.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
