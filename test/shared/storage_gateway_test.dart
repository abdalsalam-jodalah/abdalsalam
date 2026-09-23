import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const databaseName = 'test_storage_gateway_test.db';
  const table = 'gateway_test_records';
  final storage = StorageGateway.instance;

  Future<Database> openRawDatabase() async {
    final databasesPath = await databaseFactory.getDatabasesPath();
    return databaseFactory.openDatabase('$databasesPath/$databaseName');
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: databaseName);
    await storage.clearTable(table);
    storage.integrityReporter.clearReports();
  });

  group('StorageGateway records', () {
    test('should create an unknown table on first use instead of failing', () async {
      await storage.upsertRecord(table: 'gateway_brand_new_table', id: 'a', record: {'name': 'x'});

      final record = await storage.getRecord(table: 'gateway_brand_new_table', id: 'a');

      expect(record?['name'], 'x');
    });

    test('should keep the createdAt passed in the record', () async {
      await storage.upsertRecord(table: table, id: 'a', record: {'createdAt': '2020-01-01T00:00:00.000'});

      final record = await storage.getRecord(table: table, id: 'a');

      expect(record?['createdAt'], '2020-01-01T00:00:00.000');
    });

    test('should keep the existing createdAt when an update omits it', () async {
      await storage.upsertRecord(table: table, id: 'a', record: {'createdAt': '2020-01-01T00:00:00.000', 'v': 1});
      await storage.upsertRecord(table: table, id: 'a', record: {'v': 2});

      final record = await storage.getRecord(table: table, id: 'a');

      expect(record?['createdAt'], '2020-01-01T00:00:00.000');
      expect(record?['v'], 2);
    });

    test('should count, delete, and clear records', () async {
      await storage.upsertRecord(table: table, id: 'a', record: {});
      await storage.upsertRecord(table: table, id: 'b', record: {});
      expect(await storage.countRecords(table: table), 2);

      await storage.deleteRecord(table: table, id: 'a');
      expect(await storage.countRecords(table: table), 1);

      await storage.clearTable(table);
      expect(await storage.countRecords(table: table), 0);
    });

    test('should filter by userId', () async {
      await storage.upsertRecord(table: table, id: 'a', record: {}, userId: 'u1');
      await storage.upsertRecord(table: table, id: 'b', record: {}, userId: 'u2');

      final records = await storage.getAllRecords(table: table, userId: 'u1');

      expect(records.map((record) => record['id']), ['a']);
    });
  });

  group('StorageGateway corrupt data', () {
    Future<void> insertCorruptRow(String id) async {
      final database = await openRawDatabase();
      await database.insert(table, {'id': id, 'data': '{not json'});
    }

    test('should skip and report a corrupt row but return the valid ones', () async {
      await storage.upsertRecord(table: table, id: 'good', record: {'v': 1});
      await insertCorruptRow('bad');

      final records = await storage.getAllRecords(table: table);

      expect(records.map((record) => record['id']), ['good']);
      expect(storage.integrityReporter.corruptRecordCount, 1);
      expect(storage.integrityReporter.reports.single.recordId, 'bad');
    });

    test('should leave the corrupt row in the database', () async {
      await insertCorruptRow('bad');

      await storage.getAllRecords(table: table);

      expect(await storage.countRecords(table: table), 1);
    });

    test('should throw CorruptDataError when reading a single corrupt row', () async {
      await insertCorruptRow('bad');

      expect(storage.getRecord(table: table, id: 'bad'), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when a stored preference has the wrong type', () async {
      await storage.save(key: 'gateway_pref', value: 'text');

      expect(storage.get<Map<String, dynamic>>('gateway_pref'), throwsA(isA<CorruptDataError>()));
    });
  });

  group('StorageGateway.runInTransaction', () {
    test('should commit all writes when the action succeeds', () async {
      await storage.runInTransaction(() async {
        await storage.upsertRecord(table: table, id: 'a', record: {});
        await storage.upsertRecord(table: table, id: 'b', record: {});
      });

      expect(await storage.countRecords(table: table), 2);
    });

    test('should roll back every write when the action throws', () async {
      await storage.upsertRecord(table: table, id: 'existing', record: {});

      await expectLater(
        storage.runInTransaction(() async {
          await storage.clearTable(table);
          await storage.upsertRecord(table: table, id: 'a', record: {});
          throw StateError('abort');
        }),
        throwsA(isA<StateError>()),
      );

      final records = await storage.getAllRecords(table: table);
      expect(records.map((record) => record['id']), ['existing']);
    });
  });
}
