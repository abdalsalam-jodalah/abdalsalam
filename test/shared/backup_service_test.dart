import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/backup_codec.dart';
import 'package:abdalsalam/shared/services/backup_file_store.dart';
import 'package:abdalsalam/shared/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _RecordingFileStore extends BackupFileStore {
  final List<String> savedFileNames = <String>[];
  bool isSaveFailing = false;

  _RecordingFileStore();

  @override
  Future<String> save({required String content, required String fileName}) async {
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
    for (final table in [notesTable, todosTable]) {
      await storage.clearTable(table);
    }
    fileStore = _RecordingFileStore();
    service = buildService();
  });

  group('BackupService round trip', () {
    test('should restore records, original timestamps, and settings from a saved backup', () async {
      await seedOriginalData();
      final backup = await service.createCompressedBackup(tables: [notesTable, todosTable]);
      await storage.clearTable(notesTable);
      await storage.clearTable(todosTable);
      await storage.delete(preferenceKey);

      final result = await service.restoreFromText(backup.data!);

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
      final backup = await service.createFullBackup(tables: [notesTable]);
      await storage.clearTable(notesTable);

      final result = await service.restoreFromText(jsonEncode(backup.data));

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
      final backup = (await service.createFullBackup(tables: [notesTable])).data!;
      (backup['data'] as Map<String, dynamic>)[notesTable] = [
        {'id': 'tampered'},
      ];

      final result = await service.restore(backup: backup, replace: true);

      expect(result.error?.message, contains('checksum'));
      expect(await idsIn(notesTable), ['n1']);
    });

    test('should cancel the restore when the safety backup cannot be saved', () async {
      await seedOriginalData();
      final backup = (await service.createFullBackup(tables: [notesTable])).data!;
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
}
