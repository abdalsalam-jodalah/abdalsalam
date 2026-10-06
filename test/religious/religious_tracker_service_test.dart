import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/data/models/religious/prayer_times_snapshot.dart';
import 'package:abdalsalam/data/models/religious/religious_entry.dart';
import 'package:abdalsalam/data/repositories/religious/prayer_times_snapshot_repository.dart';
import 'package:abdalsalam/data/repositories/religious/religious_entry_repository.dart';
import 'package:abdalsalam/features/religious/services/prayer_time_service.dart';
import 'package:abdalsalam/features/religious/services/prayer_times_cache_service.dart';
import 'package:abdalsalam/features/religious/services/religious_tracker_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'religious_fakes.dart';

class FailingSnapshotRepository extends PrayerTimesSnapshotRepository {
  FailingSnapshotRepository(super.storage, super.logger);

  @override
  Future<Result<PrayerTimesSnapshot?, AppError>> getByDateKey(String dateKey) async {
    return Failure(DatabaseError('snapshot table unreadable'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const scrapedHtml = '<div>الفجر 4:30 ص</div><div>الظهر 12:15 م</div><div>العصر 3:45 م</div>'
      '<div>المغرب 6:50 م</div><div>العشاء 8:10 م</div>';
  final storage = StorageGateway.instance;
  late LoggerService logger;
  late SettingsService settings;
  late PrayerTimesSnapshotRepository snapshotRepository;
  late FakeReminderService reminders;

  http.Response htmlResponse(String body) {
    return http.Response.bytes(
      utf8.encode(body),
      200,
      headers: const <String, String>{'content-type': 'text/html; charset=utf-8'},
    );
  }

  ReligiousTrackerService buildService({
    http.Client? httpClient,
    PrayerTimesSnapshotRepository? timesRepository,
    DateTime Function()? clock,
  }) {
    return ReligiousTrackerService(
      ReligiousEntryRepository(storage, logger),
      timesRepository ?? snapshotRepository,
      logger,
      reminders: reminders,
      settings: settings,
      prayerTimeService: PrayerTimeService(
        logger: logger,
        cache: PrayerTimesCacheService(storage: storage, logger: logger),
      ),
      httpClient: httpClient ?? MockClient((request) async => htmlResponse(scrapedHtml)),
      clock: clock,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_religious_tracker_service_test.db');
    await DatabaseSchemaInitializer.initialize(storage);
    await storage.clearTable('religious_entries');
    await storage.clearTable('prayer_times_snapshots');
    await storage.save(key: 'prayer_times_cache', value: <String, dynamic>{});
    logger = LoggerService.forModule('ReligiousTrackerServiceTest');
    settings = SettingsService(storage);
    await settings.resetToDefaults();
    snapshotRepository = PrayerTimesSnapshotRepository(storage, logger);
    reminders = FakeReminderService();
  });

  group('ReligiousTrackerService', () {
    test('should parse scraped prayer times into 24-hour times', () async {
      final service = buildService();
      final date = DateTime(2026, 9, 23);

      final result = await service.previewSource(source: 'scraped', date: date);

      expect(result.isSuccess, isTrue);
      expect(result.data, <String, DateTime>{
        PrayerName.fajr.name: DateTime(2026, 9, 23, 4, 30),
        PrayerName.dhuhr.name: DateTime(2026, 9, 23, 12, 15),
        PrayerName.asr.name: DateTime(2026, 9, 23, 15, 45),
        PrayerName.maghrib.name: DateTime(2026, 9, 23, 18, 50),
        PrayerName.isha.name: DateTime(2026, 9, 23, 20, 10),
      });
    });

    test('should return a network failure when the source responds with an error', () async {
      final service = buildService(httpClient: MockClient((request) async => http.Response('', 500)));

      final result = await service.syncPrayerTimesForToday(force: true);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<NetworkError>());
      expect((await snapshotRepository.getAll()).data, isEmpty);
    });

    test('should return a corrupt data failure when the source page cannot be parsed', () async {
      final service = buildService(
        httpClient: MockClient((request) async => htmlResponse('<div>no times</div>')),
      );

      final result = await service.previewSource(source: 'scraped');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<CorruptDataError>());
    });

    test('should map a thrown http error to a failure instead of throwing', () async {
      final service = buildService(
        httpClient: MockClient((request) async => throw http.ClientException('offline')),
      );

      final result = await service.previewSource(source: 'scraped');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<NetworkError>());
    });

    test('should calculate adhan times when stored settings have the wrong types', () async {
      await settings.updateSetting('prayerLocationLatitude', 'not-a-number');
      await settings.updateSetting('prayerMethod', 42);
      final service = buildService();

      final result = await service.previewSource(source: 'adhan', date: DateTime(2026, 9, 23));

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(PrayerName.obligatory.length));
    });

    test('should persist the synced snapshot from the adhan source', () async {
      await settings.updateSetting('prayerTimeSource', 'adhan');
      final service = buildService();

      final result = await service.syncPrayerTimesForToday(force: true);

      expect(result.isSuccess, isTrue);
      final stored = (await snapshotRepository.getAll()).data!;
      expect(stored.single.id, result.data!.id);
    });

    test('should keep the synced snapshot when reminder scheduling fails', () async {
      reminders.shouldFail = true;
      final service = buildService(clock: () => DateTime(2026, 9, 23, 3));

      final result = await service.syncPrayerTimesForToday(force: true);

      expect(reminders.attemptedScheduleCount, greaterThan(0));
      expect(result.isSuccess, isTrue);
      expect((await snapshotRepository.getAll()).data, hasLength(1));
    });

    test('should return failure when the snapshot repository fails', () async {
      final service = buildService(timesRepository: FailingSnapshotRepository(storage, logger));

      final result = await service.getTodayPrayerTimes();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });

    test('should save the entry even when its reminder cannot be scheduled', () async {
      reminders.shouldFail = true;
      final service = buildService();

      final result = await service.logEntry(
        userId: 'local-user',
        type: ReligiousEntryType.athkar,
        title: 'Morning athkar',
        count: 1,
        reminderAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(result.isSuccess, isTrue);
      expect((await service.getHistory('local-user')).data, hasLength(1));
    });

    test('should reject an invalid entry without saving it', () async {
      final service = buildService();

      final result = await service.logEntry(
        userId: 'local-user',
        type: ReligiousEntryType.prayer,
        title: '',
        count: 1,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ValidationError>());
      expect((await service.getHistory('local-user')).data, isEmpty);
    });
  });
}
