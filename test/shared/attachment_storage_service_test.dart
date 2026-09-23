import 'dart:io';

import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/services/attachment_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AttachmentStorageService', () {
    late Directory documentsDirectory;
    late AttachmentStorageService service;

    setUp(() async {
      documentsDirectory = await Directory.systemTemp.createTemp('attachment_storage_service_test');
      service = AttachmentStorageService(
        logger: LoggerService.forModule('AttachmentStorageServiceTest'),
        subDirectory: 'attachments',
        documentsDirectoryProvider: () async => documentsDirectory,
      );
    });

    tearDown(() async {
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    test('should copy the source file into the attachments directory', () async {
      final source = File('${documentsDirectory.path}/scan.pdf');
      await source.writeAsString('content');

      final result = await service.saveAttachment(source.path);

      final savedPath = result.getOrThrow();
      expect(savedPath, startsWith('${documentsDirectory.path}/attachments/'));
      expect(savedPath, endsWith('.pdf'));
      expect(await File(savedPath).readAsString(), 'content');
    });

    test('should return a failure when the source file does not exist', () async {
      final result = await service.saveAttachment('${documentsDirectory.path}/missing.png');

      expect(result.isFailure, isTrue);
    });

    test('should return a failure when the documents directory is unavailable', () async {
      final unavailable = AttachmentStorageService(
        logger: LoggerService.forModule('AttachmentStorageServiceTest'),
        documentsDirectoryProvider: () async => throw const FileSystemException('no documents directory'),
      );

      final result = await unavailable.saveAttachment('${documentsDirectory.path}/any.png');

      expect(result.isFailure, isTrue);
    });

    test('should delete existing attachments and ignore missing ones', () async {
      final existing = File('${documentsDirectory.path}/old.png');
      await existing.writeAsString('old');

      final result = await service.deleteAttachments(<String>[
        existing.path,
        '${documentsDirectory.path}/already-gone.png',
      ]);

      expect(result.isSuccess, isTrue);
      expect(await existing.exists(), isFalse);
    });
  });
}
