import 'dart:convert';

import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/financial_export_enricher.dart';
import 'package:abdalsalam/shared/services/module_export_service.dart';
import 'package:abdalsalam/shared/services/module_table_registry.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late ModuleExportService service;

  Archive unzip(List<int> bytes) => ZipDecoder().decodeBytes(bytes);

  String textOf(Archive archive, String name) => utf8.decode(archive.findFile(name)!.content);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_module_export_service_test.db');
    await DatabaseSchemaInitializer.initialize(storage);
    for (final table in DatabaseSchemaInitializer.tables) {
      await storage.clearTable(table);
    }
    service = ModuleExportService(
      storage,
      LoggerService.forModule('ModuleExportServiceTest'),
      enrichers: const [FinancialExportEnricher()],
    );
    await storage.upsertRecord(table: 'accounts', id: 'acc1', record: {'name': 'Cash'});
    await storage.upsertRecord(table: 'categories', id: 'cat1', record: {'name': 'Food'});
    await storage.upsertRecord(
      table: 'transactions',
      id: 't1',
      record: {'accountId': 'acc1', 'categoryId': 'cat1', 'amount': 12.5, 'description': 'غداء, مطعم'},
    );
    await storage.upsertRecord(table: 'prayer_logs', id: 'p1', record: {'prayer': 'fajr'});
    await storage.upsertRecord(
      table: 'prayer_logs',
      id: 'p2',
      record: {'prayer': 'dhuhr', 'deletedAt': '2026-01-01T00:00:00.000'},
    );
    await storage.upsertRecord(table: 'credentials', id: 'c1', record: {'encryptedPassword': 'iv:secret'});
  });

  group('ModuleExportService', () {
    test('should write JSON and CSV only for the selected modules', () async {
      final result = await service.export(modules: {DataModule.financial});

      final archive = unzip(result.data!.bytes);
      expect(archive.findFile('financial/financial.json'), isNotNull);
      expect(archive.findFile('financial/transactions.csv'), isNotNull);
      expect(archive.findFile('religious/religious.json'), isNull);
      expect(archive.findFile('manifest.json'), isNotNull);
    });

    test('should name accounts and categories in the transactions CSV and keep Arabic text intact', () async {
      final result = await service.export(modules: {DataModule.financial});

      final csv = textOf(unzip(result.data!.bytes), 'financial/transactions.csv');
      expect(csv, contains('accountName'));
      expect(csv, contains('Cash'));
      expect(csv, contains('Food'));
      expect(csv, contains('"غداء, مطعم"'));
    });

    test('should start CSV files with a UTF-8 byte order mark so spreadsheets read Arabic', () async {
      final result = await service.export(modules: {DataModule.financial});

      final bytes = unzip(result.data!.bytes).findFile('financial/transactions.csv')!.content;
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    });

    test('should leave soft-deleted records out by default', () async {
      final result = await service.export(modules: {DataModule.religious});

      final json = jsonDecode(textOf(unzip(result.data!.bytes), 'religious/religious.json')) as Map<String, dynamic>;
      final prayerLogs = (json['tables'] as Map<String, dynamic>)['prayer_logs'] as List;
      expect(prayerLogs.map((row) => (row as Map)['id']), ['p1']);
      expect(result.data!.recordCountByModule[DataModule.religious], 1);
    });

    test('should include soft-deleted records when asked', () async {
      final result = await service.export(modules: {DataModule.religious}, includeDeleted: true);

      final json = jsonDecode(textOf(unzip(result.data!.bytes), 'religious/religious.json')) as Map<String, dynamic>;
      final prayerLogs = (json['tables'] as Map<String, dynamic>)['prayer_logs'] as List;
      expect(prayerLogs.length, 2);
    });

    test('should never export stored credentials', () async {
      final result = await service.export(modules: {DataModule.security});

      final json = jsonDecode(textOf(unzip(result.data!.bytes), 'security/security.json')) as Map<String, dynamic>;
      expect((json['tables'] as Map<String, dynamic>).containsKey('credentials'), isFalse);
      expect(unzip(result.data!.bytes).findFile('security/credentials.csv'), isNull);
    });

    test('should skip CSV files for tables with no records but keep them in the JSON', () async {
      final result = await service.export(modules: {DataModule.religious});

      final archive = unzip(result.data!.bytes);
      final json = jsonDecode(textOf(archive, 'religious/religious.json')) as Map<String, dynamic>;
      expect((json['tables'] as Map<String, dynamic>)['quran_readings'], isEmpty);
      expect(archive.findFile('religious/quran_readings.csv'), isNull);
    });

    test('should count stored records per module', () async {
      final counts = await service.countRecordsByModule();

      expect(counts[DataModule.financial], 3);
      expect(counts[DataModule.religious], 2);
      expect(counts[DataModule.security], 1);
      expect(counts[DataModule.habits], 0);
    });

    test('should build a sortable timestamped file name', () {
      expect(ModuleExportService.fileName(DateTime(2026, 10, 1, 9, 5)), 'abdalsalam-export-20261001-0905.zip');
    });
  });
}
