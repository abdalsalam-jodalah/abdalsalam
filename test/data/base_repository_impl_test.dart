import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/json/json_reader.dart';
import 'package:abdalsalam/data/models/base_model.dart';
import 'package:abdalsalam/data/repositories/base_repository_impl.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SampleItem extends BaseModel {
  final String title;
  final bool isUnserializable;

  const SampleItem({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.title,
    this.isUnserializable = false,
  });

  factory SampleItem.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SampleItem');
    return SampleItem(
      id: reader.requireString('id'),
      createdAt: reader.requireDate('createdAt'),
      updatedAt: reader.requireDate('updatedAt'),
      deletedAt: reader.optionalDate('deletedAt'),
      title: reader.requireString('title'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    if (isUnserializable) {
      throw StateError('cannot serialize');
    }
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'title': title,
    };
  }
}

class SampleRepository extends BaseRepositoryImpl<SampleItem> {
  const SampleRepository(super.storage, super.logger);

  @override
  String get tableName => 'base_repository_samples';

  @override
  SampleItem fromJson(Map<String, dynamic> json) => SampleItem.fromJson(json);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late SampleRepository repository;

  SampleItem item(String id, {String title = 'ok', bool isUnserializable = false, DateTime? createdAt}) {
    final timestamp = createdAt ?? DateTime(2026, 1, 1);
    return SampleItem(
      id: id,
      createdAt: timestamp,
      updatedAt: timestamp,
      title: title,
      isUnserializable: isUnserializable,
    );
  }

  Future<void> insertRowMissingTitle(String id) async {
    await storage.upsertRecord(
      table: repository.tableName,
      id: id,
      record: {'createdAt': '2026-01-01T00:00:00.000', 'updatedAt': '2026-01-01T00:00:00.000'},
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_base_repository_impl_test.db');
    repository = SampleRepository(storage, LoggerService.forModule('BaseRepositoryTest'));
    await storage.clearTable(repository.tableName);
    storage.integrityReporter.clearReports();
  });

  group('BaseRepositoryImpl reads', () {
    test('should return valid items and skip a row that cannot be parsed', () async {
      await repository.create(item('good'));
      await insertRowMissingTitle('broken');

      final result = await repository.getAll();

      expect(result.data?.map((entity) => entity.id), ['good']);
      expect(storage.integrityReporter.reports.single.recordId, 'broken');
    });

    test('should return CorruptDataError from getById for an unparseable row', () async {
      await insertRowMissingTitle('broken');

      final result = await repository.getById('broken');

      expect(result.error, isA<CorruptDataError>());
    });

    test('should return null from getById when the row does not exist', () async {
      final result = await repository.getById('missing');

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('should sort items newest first', () async {
      await repository.create(item('old', createdAt: DateTime(2025)));
      await repository.create(item('new', createdAt: DateTime(2026)));

      final result = await repository.getAll();

      expect(result.data?.map((entity) => entity.id), ['new', 'old']);
    });

    test('should count rows without parsing them', () async {
      await repository.create(item('good'));
      await insertRowMissingTitle('broken');

      expect((await repository.count()).data, 2);
      expect((await repository.countActive()).data, 1);
    });
  });

  group('BaseRepositoryImpl writes', () {
    test('should return a DatabaseError without raw exception text when a write fails', () async {
      final result = await repository.create(item('x', isUnserializable: true));

      expect(result.error, isA<DatabaseError>());
      expect(result.error?.message, isNot(contains('cannot serialize')));
      expect(result.error?.cause, isA<StateError>());
    });

    test('should roll back the whole bulk create when one entity fails', () async {
      final result = await repository.createBulk([item('a'), item('b', isUnserializable: true)]);

      expect(result.isFailure, isTrue);
      expect((await repository.count()).data, 0);
    });

    test('should return NotFoundError when updating a missing entity', () async {
      final result = await repository.update(item('missing'));

      expect(result.error, isA<NotFoundError>());
    });

    test('should soft delete and restore', () async {
      await repository.create(item('a'));

      await repository.softDelete('a');
      expect((await repository.getDeleted()).data?.single.id, 'a');

      await repository.restore('a');
      expect((await repository.getActive()).data?.single.id, 'a');
    });

    test('should return NotFoundError when soft deleting a missing entity', () async {
      final result = await repository.softDelete('missing');

      expect(result.error, isA<NotFoundError>());
    });
  });
}
