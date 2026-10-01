import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/attachment_storage_service.dart';
import 'package:abdalsalam/shared/services/backup_attachment_bundler.dart';
import 'package:abdalsalam/shared/services/backup_codec.dart';
import 'package:abdalsalam/shared/services/backup_file_store.dart';
import 'package:abdalsalam/shared/services/backup_service.dart';
import 'package:abdalsalam/shared/services/backup_status_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _RecordingFileStore extends BackupFileStore {
  final List<String> savedFileNames = <String>[];
  final List<String> keptPrefixes = <String>[];
  int? keptCount;
  bool isSaveFailing = false;
  String? saveAsPath = '/Download/picked.zip';

  _RecordingFileStore();

  @override
  Future<String?> saveBytesAs({required Uint8List bytes, required String fileName}) async => saveAsPath;

  @override
  Future<void> share(String filePath) async {}

  @override
  Future<void> keepNewest({required String prefix, required int count}) async {
    keptPrefixes.add(prefix);
    keptCount = count;
  }

  @override
  Future<String> saveBytes({required Uint8List bytes, required String fileName}) async {
    if (isSaveFailing) {
      throw const FileSystemExceptionStub('disk full');
    }
    savedFileNames.add(fileName);
    return '/backups/$fileName';
  }
}

class FileSystemExceptionStub implements Exception {
  final String message;

  const FileSystemExceptionStub(this.message);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const notesTable = 'backup_test_notes';
  const todosTable = 'backup_test_todos';
  const visitsTable = 'backup_test_visits';
  const brokenTable = 'backup test broken';
  const preferenceKey = 'backup_test_setting';
  final storage = StorageGateway.instance;
  late _RecordingFileStore fileStore;
  late BackupService service;

  BackupService buildService({List<String> knownTables = const [notesTable, todosTable]}) {
    return BackupService(
      storage,
      LoggerService.forModule('BackupServiceTest'),
      fileStore: fileStore,
      knownTables: knownTables,
    );
  }

  Future<List<String>> idsIn(String table) async {
    final rows = await storage.getAllRecords(table: table);
    return rows.map((row) => row['id'] as String).toList()..sort();
  }

  Future<void> seedOriginalData() async {
    await storage.upsertRecord(
      table: notesTable,
      id: 'n1',
      record: {'title': 'first', 'createdAt': '2020-01-01T00:00:00.000', 'updatedAt': '2020-02-02T00:00:00.000'},
      isPreservingUpdatedAt: true,
    );
    await storage.upsertRecord(table: todosTable, id: 't1', record: {'title': 'task'});
    await storage.save(key: preferenceKey, value: {'theme': 'dark'});
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_backup_service_test.db');
    await storage.delete(BackupStatusService.storageKey);
    for (final table in [notesTable, todosTable, visitsTable]) {
      await storage.clearTable(table);
    }
    fileStore = _RecordingFileStore();
    service = buildService();
  });

  group('BackupService round trip', () {
    test('should restore records, original timestamps, and settings from a saved backup', () async {
      await seedOriginalData();
      final backup = await service.createBackupArchive(tables: [notesTable, todosTable]);
      await storage.clearTable(notesTable);
      await storage.clearTable(todosTable);
      await storage.delete(preferenceKey);

      final result = await service.restoreFromBytes(backup.data!.bytes);

      expect(result.isSuccess, isTrue);
      expect(result.data!.restoredRowCount, 2);
      expect(result.data!.safetyBackupPath, startsWith('/backups/abdalsalam-pre-restore-'));
      final restoredNote = await storage.getRecord(table: notesTable, id: 'n1');
      expect(restoredNote?['createdAt'], '2020-01-01T00:00:00.000');
      expect(restoredNote?['updatedAt'], '2020-02-02T00:00:00.000');
      expect(await storage.get<Map<String, dynamic>>(preferenceKey), {'theme': 'dark'});
    });

    test('should accept a backup pasted as raw JSON', () async {
      await seedOriginalData();
      final backup = await service.createBackupPackage(tables: [notesTable]);
      await storage.clearTable(notesTable);

      final result = await service.restoreFromText(jsonEncode(backup.data!.envelope));

      expect(result.isSuccess, isTrue);
      expect(await idsIn(notesTable), ['n1']);
    });

    test('should accept a legacy 1.0.0 backup without settings', () async {
      final data = {
        notesTable: [
          {'id': 'legacy', 'title': 'old'},
        ],
      };
      final legacyBackup = {
        'metadata': {'version': '1.0.0', 'checksum': const BackupCodec().checksum(data), 'tables': [notesTable]},
        'data': data,
      };

      final result = await service.restore(backup: legacyBackup);

      expect(result.isSuccess, isTrue);
      expect(await idsIn(notesTable), ['legacy']);
    });
  });

  group('BackupService rejects bad backups without changing data', () {
    test('should reject garbage text', () async {
      await seedOriginalData();

      final result = await service.restoreFromText('definitely not a backup');

      expect(result.error, isA<ImportError>());
      expect(await idsIn(notesTable), ['n1']);
      expect(fileStore.savedFileNames, isEmpty);
    });

    test('should reject a backup whose checksum does not match', () async {
      await seedOriginalData();
      final backup = (await service.createBackupPackage(tables: [notesTable])).data!.envelope;
      (backup['data'] as Map<String, dynamic>)[notesTable] = [
        {'id': 'tampered'},
      ];

      final result = await service.restore(backup: backup, replace: true);

      expect(result.error?.message, contains('checksum'));
      expect(await idsIn(notesTable), ['n1']);
    });

    test('should cancel the restore when the safety backup cannot be saved', () async {
      await seedOriginalData();
      final backup = (await service.createBackupPackage(tables: [notesTable])).data!.envelope;
      fileStore.isSaveFailing = true;
      await storage.clearTable(notesTable);

      final result = await service.restore(backup: backup);

      expect(result.error?.message, contains('safety backup'));
      expect(await idsIn(notesTable), isEmpty);
    });

    test('should roll back every table when a write fails part-way', () async {
      await seedOriginalData();
      final data = {
        notesTable: [
          {'id': 'replacement'},
        ],
        brokenTable: [
          {'id': 'x'},
        ],
      };
      final backup = {
        'metadata': {'version': '1.0.0', 'checksum': const BackupCodec().checksum(data)},
        'data': data,
      };
      service = buildService(knownTables: const [notesTable, todosTable, brokenTable]);

      final result = await service.restore(backup: backup, replace: true);

      expect(result.error, isA<ImportError>());
      expect(await idsIn(notesTable), ['n1']);
    });
  });

  group('BackupService partial content', () {
    test('should skip rows without an id and unknown tables, and report them', () async {
      final data = {
        notesTable: [
          {'id': 'ok'},
          {'title': 'no id'},
          'not an object',
        ],
        'some_future_table': [
          {'id': 'z'},
        ],
      };
      final backup = {
        'metadata': {'version': '1.0.0', 'checksum': const BackupCodec().checksum(data)},
        'data': data,
      };

      final result = await service.restore(backup: backup);

      expect(result.data!.restoredRowCount, 1);
      expect(result.data!.skippedRowCount, 2);
      expect(result.data!.skippedUnknownTables, ['some_future_table']);
      expect(await idsIn(notesTable), ['ok']);
    });
  });

  group('BackupService backup contents', () {
    test('should leave caches and run markers out of the backup but keep real settings', () async {
      await storage.save(key: preferenceKey, value: {'theme': 'dark'});
      await storage.save(key: 'weather_data', value: {'temp': 30});
      await storage.save(key: 'prayer_times_cache', value: {'fajr': '04:00'});

      final package = (await service.createBackupPackage(tables: [notesTable])).data!;

      final preferences = package.envelope['preferences'] as Map<String, dynamic>;
      expect(preferences, contains(preferenceKey));
      expect(preferences, isNot(contains('weather_data')));
      expect(preferences, isNot(contains('prayer_times_cache')));
    });

    test('should still restore a 1.1.0 base64 backup delivered as file bytes', () async {
      final data = {
        notesTable: [
          {'id': 'old', 'title': 'from 1.1.0'},
        ],
      };
      final preferences = <String, dynamic>{};
      final oldBackup = {
        'metadata': {
          'version': '1.1.0',
          'checksum': const BackupCodec().checksum(data),
          'preferencesChecksum': const BackupCodec().checksum(preferences),
        },
        'data': data,
        'preferences': preferences,
      };

      final result = await service.restoreFromBytes(Uint8List.fromList(utf8.encode(const BackupCodec().encode(oldBackup))));

      expect(result.isSuccess, isTrue);
      expect(await idsIn(notesTable), ['old']);
    });

    test('should reject corrupt zip bytes without changing data', () async {
      await seedOriginalData();
      final corrupt = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 1, 2, 3, 4, 5]);

      final result = await service.restoreFromBytes(corrupt);

      expect(result.error, isA<ImportError>());
      expect(await idsIn(notesTable), ['n1']);
    });
  });

  group('BackupService attachments', () {
    late Directory sourceRoot;
    late Directory restoreRoot;

    AttachmentStorageService storageIn(Directory root) => AttachmentStorageService(
          logger: LoggerService.forModule('AttachmentTest'),
          subDirectory: 'visit_files',
          documentsDirectoryProvider: () async => root,
        );

    BackupService serviceWith(AttachmentStorageService attachments) => BackupService(
          storage,
          LoggerService.forModule('BackupServiceTest'),
          fileStore: fileStore,
          knownTables: const [visitsTable],
          attachmentBundler: BackupAttachmentBundler([
            AttachmentBinding(table: visitsTable, field: 'attachmentPaths', isList: true, storage: attachments),
          ]),
        );

    setUp(() {
      sourceRoot = Directory.systemTemp.createTempSync('backup_source_');
      restoreRoot = Directory.systemTemp.createTempSync('backup_restore_');
    });

    tearDown(() {
      sourceRoot.deleteSync(recursive: true);
      restoreRoot.deleteSync(recursive: true);
    });

    test('should carry attachment files into a new location and rewrite record paths', () async {
      final sourceStorage = storageIn(sourceRoot);
      final original = File('${sourceRoot.path}/scan.pdf')..writeAsBytesSync([9, 8, 7]);
      final savedPath = (await sourceStorage.saveAttachment(original.path)).data!;
      await storage.upsertRecord(table: visitsTable, id: 'v1', record: {'attachmentPaths': [savedPath], 'title': 'visit'});
      final archive = (await serviceWith(sourceStorage).createBackupArchive(tables: [visitsTable])).data!;
      await storage.clearTable(visitsTable);
      File(savedPath).deleteSync();

      final result = await serviceWith(storageIn(restoreRoot)).restoreFromBytes(archive.bytes);

      expect(archive.attachmentCount, 1);
      expect(result.data!.restoredAttachmentCount, 1);
      expect(result.data!.missingAttachmentCount, 0);
      final restored = await storage.getRecord(table: visitsTable, id: 'v1');
      final restoredPath = (restored!['attachmentPaths'] as List).single as String;
      expect(restoredPath, startsWith(restoreRoot.path));
      expect(File(restoredPath).readAsBytesSync(), [9, 8, 7]);
    });

    test('should report a missing attachment file and still back up the record', () async {
      await storage.upsertRecord(
        table: visitsTable,
        id: 'v2',
        record: {'attachmentPaths': ['${sourceRoot.path}/gone.pdf']},
      );

      final archive = (await serviceWith(storageIn(sourceRoot)).createBackupArchive(tables: [visitsTable])).data!;
      await storage.clearTable(visitsTable);
      final result = await serviceWith(storageIn(restoreRoot)).restoreFromBytes(archive.bytes);

      expect(archive.attachmentCount, 0);
      expect(archive.missingAttachmentCount, 1);
      expect(result.isSuccess, isTrue);
      expect(await idsIn(visitsTable), ['v2']);
    });

    test('should store a file shared by two records only once', () async {
      final sourceStorage = storageIn(sourceRoot);
      final original = File('${sourceRoot.path}/shared.png')..writeAsBytesSync([1, 2]);
      final savedPath = (await sourceStorage.saveAttachment(original.path)).data!;
      await storage.upsertRecord(table: visitsTable, id: 'a', record: {'attachmentPaths': [savedPath]});
      await storage.upsertRecord(table: visitsTable, id: 'b', record: {'attachmentPaths': [savedPath]});

      final archive = (await serviceWith(sourceStorage).createBackupArchive(tables: [visitsTable])).data!;

      expect(archive.attachmentCount, 1);
    });
  });

  group('BackupService backup status', () {
    Future<DateTime?> lastExportedAt() async => (await BackupStatusService(storage).read()).lastExportedAt;

    test('should record an export when the backup is saved through the picker', () async {
      await service.saveBackupAs(bytes: Uint8List(1), fileName: 'b.zip');

      expect(await lastExportedAt(), isNotNull);
    });

    test('should not record an export when the picker is dismissed', () async {
      fileStore.saveAsPath = null;

      await service.saveBackupAs(bytes: Uint8List(1), fileName: 'b.zip');

      expect(await lastExportedAt(), isNull);
    });

    test('should record an export when the backup is handed to the share sheet', () async {
      await service.shareBackup('/backups/b.zip');

      expect(await lastExportedAt(), isNotNull);
    });

    test('should not record an export for a plain save into the app folder', () async {
      await service.saveBackupToDevice(bytes: Uint8List(1), fileName: 'b.zip');

      expect(await lastExportedAt(), isNull);
    });

    test('should name automatic backups distinctly and keep only the latest five', () async {
      final result = await service.createAutomaticBackup();

      expect(result.data, startsWith('/backups/abdalsalam-auto-'));
      expect(fileStore.keptPrefixes, ['abdalsalam-auto-']);
      expect(fileStore.keptCount, 5);
    });

    test('should not count an automatic backup as an export outside the app', () async {
      await service.createAutomaticBackup();

      expect(await lastExportedAt(), isNull);
    });
  });
}
