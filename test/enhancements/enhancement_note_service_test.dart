import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/enhancements/enhancement_note.dart';
import 'package:abdalsalam/data/repositories/enhancements/enhancement_note_repository.dart';
import 'package:abdalsalam/features/enhancements/services/enhancement_note_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late EnhancementNoteService service;

  EnhancementNote note(
    String id, {
    String title = 'Idea',
    EnhancementPriority priority = EnhancementPriority.medium,
    bool isDone = false,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    final created = createdAt ?? DateTime(2026, 10, 1);
    return EnhancementNote(
      id: id,
      createdAt: created,
      updatedAt: created,
      userId: 'user1',
      title: title,
      priority: priority,
      isDone: isDone,
      completedAt: completedAt,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_enhancement_note_service_test.db');
    await DatabaseSchemaInitializer.initialize(storage);
    await storage.clearTable('app_enhancement_notes');
    service = EnhancementNoteService(
      EnhancementNoteRepositoryImpl(storage, LoggerService.forModule('EnhancementNoteRepositoryTest')),
      LoggerService.forModule('EnhancementNoteServiceTest'),
    );
  });

  group('EnhancementNoteService validation', () {
    test('should reject a note without a title', () async {
      final result = await service.create(note('a', title: '   '));

      expect(result.error, isA<ValidationError>());
    });

    test('should accept a note with a title', () async {
      final result = await service.create(note('a'));

      expect(result.isSuccess, isTrue);
    });
  });

  group('EnhancementNoteService.setDone', () {
    test('should mark a note done and stamp the completion time', () async {
      await service.create(note('a'));

      await service.setDone(note('a'), isDone: true);

      final stored = (await service.getById('a')).data!;
      expect(stored.isDone, isTrue);
      expect(stored.completedAt, isNotNull);
    });

    test('should reopen a note and clear its completion time', () async {
      await service.create(note('a', isDone: true, completedAt: DateTime(2026, 10, 2)));

      await service.setDone(note('a', isDone: true, completedAt: DateTime(2026, 10, 2)), isDone: false);

      final stored = (await service.getById('a')).data!;
      expect(stored.isDone, isFalse);
      expect(stored.completedAt, isNull);
    });
  });

  group('EnhancementNoteService.sortForDisplay', () {
    test('should list open notes before done ones', () {
      final sorted = EnhancementNoteService.sortForDisplay([
        note('done', isDone: true, completedAt: DateTime(2026, 10, 5)),
        note('open'),
      ]);

      expect(sorted.map((item) => item.id), ['open', 'done']);
    });

    test('should put higher priority first, then the newest', () {
      final sorted = EnhancementNoteService.sortForDisplay([
        note('low', priority: EnhancementPriority.low, createdAt: DateTime(2026, 10, 9)),
        note('high-old', priority: EnhancementPriority.high, createdAt: DateTime(2026, 10, 1)),
        note('high-new', priority: EnhancementPriority.high, createdAt: DateTime(2026, 10, 3)),
        note('medium'),
      ]);

      expect(sorted.map((item) => item.id), ['high-new', 'high-old', 'medium', 'low']);
    });

    test('should show the most recently completed note first among done ones', () {
      final sorted = EnhancementNoteService.sortForDisplay([
        note('first', isDone: true, completedAt: DateTime(2026, 10, 2)),
        note('second', isDone: true, completedAt: DateTime(2026, 10, 6)),
      ]);

      expect(sorted.map((item) => item.id), ['second', 'first']);
    });
  });

  group('EnhancementNoteService.getStatistics', () {
    test('should count open and done notes and ignore deleted ones', () async {
      await service.create(note('open'));
      await service.create(note('done', isDone: true, completedAt: DateTime(2026, 10, 2)));
      await service.create(note('gone'));
      await service.softDelete('gone');

      final stats = (await service.getStatistics()).data!;

      expect(stats['totalNotes'], 2);
      expect(stats['openNotes'], 1);
      expect(stats['doneNotes'], 1);
    });
  });
}
