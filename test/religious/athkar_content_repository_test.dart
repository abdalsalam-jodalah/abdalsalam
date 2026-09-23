import 'package:abdalsalam/data/models/religious/athkar_content.dart';
import 'package:abdalsalam/data/repositories/religious/athkar_content_repository.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class UnserializableAthkarContent extends AthkarContent {
  UnserializableAthkarContent(String id)
      : super(
          id: id,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          category: AthkarCategory.morning,
          arabicText: 'text',
          targetCount: 1,
          isBuiltIn: true,
          isCustom: false,
          sortOrder: 0,
        );

  @override
  Map<String, dynamic> toJson() => throw StateError('cannot serialize');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late AthkarContentRepository repository;

  AthkarContent entry(String id, {AthkarCategory category = AthkarCategory.morning}) {
    return AthkarContent(
      id: id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      category: category,
      arabicText: 'text $id',
      targetCount: 3,
      isBuiltIn: true,
      isCustom: false,
      sortOrder: 0,
    );
  }

  Future<void> insertCorruptRow(String id) async {
    await storage.upsertRecord(
      table: repository.tableName,
      id: id,
      record: {'createdAt': '2026-01-01T00:00:00.000', 'category': AthkarCategory.morning.name},
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_athkar_content_repository_test.db');
    repository = AthkarContentRepository(storage, LoggerService.forModule('AthkarContentRepositoryTest'));
    await storage.clearTable(repository.tableName);
    storage.integrityReporter.clearReports();
  });

  group('AthkarContentRepository.getByCategory', () {
    test('should skip a corrupt row instead of failing the query', () async {
      await repository.create(entry('good'));
      await insertCorruptRow('broken');

      final result = await repository.getByCategory(AthkarCategory.morning);

      expect(result.data?.map((item) => item.id), ['good']);
      expect(storage.integrityReporter.reports.single.recordId, 'broken');
    });
  });

  group('AthkarContentRepository.seedFromAsset', () {
    test('should insert only entries that do not exist yet', () async {
      await repository.create(entry('existing'));

      final result = await repository.seedFromAsset([entry('existing'), entry('new')]);

      expect(result.isSuccess, isTrue);
      expect((await repository.count()).data, 2);
    });

    test('should keep seeding and leave a corrupt existing row untouched', () async {
      await insertCorruptRow('broken');

      final result = await repository.seedFromAsset([entry('broken'), entry('new')]);

      expect(result.isSuccess, isTrue);
      expect((await repository.count()).data, 2);
      expect((await storage.getRecord(table: repository.tableName, id: 'broken'))?['arabicText'], isNull);
    });

    test('should roll back every insert when one entry fails', () async {
      final result = await repository.seedFromAsset([entry('first'), UnserializableAthkarContent('bad')]);

      expect(result.isFailure, isTrue);
      expect((await repository.count()).data, 0);
    });
  });
}
