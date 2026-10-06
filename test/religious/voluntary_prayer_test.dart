import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/data/models/religious/prayer_times_snapshot.dart';
import 'package:abdalsalam/data/repositories/religious/prayer_repository.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/religious_tracking_providers.dart';
import 'package:abdalsalam/features/religious/services/prayer_service.dart';
import 'package:abdalsalam/features/religious/services/religious_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'religious_fakes.dart';

PrayerLog _log(PrayerName prayer, {DateTime? at, bool onTime = true}) {
  final prayedAt = at ?? DateTime.now().subtract(const Duration(minutes: 5));
  return PrayerLog(
    id: '${prayer.name}-${prayedAt.microsecondsSinceEpoch}',
    createdAt: prayedAt,
    updatedAt: prayedAt,
    userId: 'u1',
    prayerName: prayer,
    prayedAt: prayedAt,
    onTime: onTime,
  );
}

class _CapturingPrayerService extends FakePrayerService {
  PrayerName? loggedPrayer;
  bool? loggedOnTime;
  DateTime? loggedScheduledAt;

  _CapturingPrayerService({required super.todayLogsResult})
      : super(logPrayerResult: Success(_log(PrayerName.voluntary)));

  @override
  Future<Result<PrayerLog, AppError>> logPrayer({
    required String userId,
    required PrayerName prayerName,
    required bool onTime,
    String? notes,
    DateTime? prayedAt,
    DateTime? scheduledAt,
  }) async {
    loggedPrayer = prayerName;
    loggedOnTime = onTime;
    loggedScheduledAt = scheduledAt;
    return super.logPrayer(
      userId: userId,
      prayerName: prayerName,
      onTime: onTime,
      notes: notes,
      prayedAt: prayedAt,
      scheduledAt: scheduledAt,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PrayerName', () {
    test('should keep the five daily prayers in order and exclude the voluntary prayer', () {
      expect(PrayerName.obligatory, [
        PrayerName.fajr,
        PrayerName.dhuhr,
        PrayerName.asr,
        PrayerName.maghrib,
        PrayerName.isha,
      ]);
      expect(PrayerName.obligatory, isNot(contains(PrayerName.voluntary)));
    });

    test('should treat the for God prayer as voluntary and the others as obligatory', () {
      expect(PrayerName.voluntary.isVoluntary, isTrue);
      expect(PrayerName.voluntary.isObligatory, isFalse);
      for (final prayer in PrayerName.obligatory) {
        expect(prayer.isObligatory, isTrue);
        expect(prayer.isVoluntary, isFalse);
      }
    });

    test('should label the voluntary prayer in English and Arabic', () {
      expect(PrayerName.voluntary.label, 'For God');
      expect(PrayerName.voluntary.arabicLabel, 'لله (نافلة)');
      expect(PrayerName.fajr.label, 'Fajr');
      expect(PrayerName.fajr.arabicLabel, 'الفجر');
    });

    test('should survive a JSON round trip as a prayer log', () {
      final log = _log(PrayerName.voluntary);

      final restored = PrayerLog.fromJson(log.toJson());

      expect(restored.prayerName, PrayerName.voluntary);
    });
  });

  group('scheduledTimeForPrayer', () {
    final now = DateTime(2026, 1, 1);
    final snapshot = PrayerTimesSnapshot(
      id: 's',
      createdAt: now,
      updatedAt: now,
      dateKey: '2026-01-01',
      forDate: now,
      fetchedAt: now,
      sourceUrl: 'test',
      fajr: DateTime(2026, 1, 1, 5),
      dhuhr: DateTime(2026, 1, 1, 12),
      asr: DateTime(2026, 1, 1, 15),
      maghrib: DateTime(2026, 1, 1, 17),
      isha: DateTime(2026, 1, 1, 19),
    );

    test('should have a time for each daily prayer and none for the voluntary prayer', () {
      expect(scheduledTimeForPrayer(PrayerName.fajr, snapshot), DateTime(2026, 1, 1, 5));
      expect(scheduledTimeForPrayer(PrayerName.isha, snapshot), DateTime(2026, 1, 1, 19));
      expect(scheduledTimeForPrayer(PrayerName.voluntary, snapshot), isNull);
    });
  });

  group('statistics with voluntary prayers', () {
    late PrayerService prayerService;
    late ReligiousService religiousService;
    late PrayerRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_voluntary_prayer_test.db');
      await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
      await StorageGateway.instance.clearTable('prayer_logs');
      final logger = LoggerService.forModule('VoluntaryPrayerTest');
      repository = PrayerRepositoryImpl(StorageGateway.instance, logger);
      prayerService = PrayerService(repository, logger);
      religiousService = ReligiousService(repository, logger, reminders: FakeReminderService());
    });

    Future<void> saveAll(List<PrayerLog> logs) async {
      for (final log in logs) {
        await repository.create(log);
      }
    }

    test('should not count voluntary prayers toward the on time percentage', () async {
      await saveAll([_log(PrayerName.fajr, onTime: false), _log(PrayerName.voluntary, onTime: true)]);

      final stats = (await prayerService.getStatistics()).data!;

      expect(stats['totalLogs'], 2);
      expect(stats['voluntaryCount'], 1);
      expect(stats['onTimePercent'], 0.0);
    });

    test('should report voluntary prayers in the per prayer counts', () async {
      await saveAll([_log(PrayerName.voluntary), _log(PrayerName.voluntary, at: DateTime.now().subtract(const Duration(minutes: 9)))]);

      final byPrayer = (await religiousService.getStatistics()).data!['byPrayer'] as Map<String, dynamic>;

      expect(byPrayer['voluntary'], 2);
      expect(byPrayer['fajr'], 0);
    });

    test('should not give a streak from voluntary prayers alone', () async {
      await saveAll([_log(PrayerName.voluntary)]);

      final stats = (await religiousService.getStatistics()).data!;

      expect(stats['currentStreak'], 0);
      expect(stats['completionRate'], 0);
    });

    test('should still give a streak for the five daily prayers when voluntary ones are also logged', () async {
      final today = DateTime.now();
      final at = DateTime(today.year, today.month, today.day);
      await saveAll([
        for (final (index, prayer) in PrayerName.obligatory.indexed) _log(prayer, at: at.add(Duration(minutes: index + 1))),
        _log(PrayerName.voluntary, at: at.add(const Duration(minutes: 30))),
      ]);

      final stats = (await religiousService.getStatistics()).data!;

      expect(stats['currentStreak'], 1);
      expect(stats['completionRate'], 100);
    });

    test('should not complete a day with four daily prayers plus a voluntary one', () async {
      final today = DateTime.now();
      final at = DateTime(today.year, today.month, today.day);
      await saveAll([
        for (final (index, prayer) in PrayerName.obligatory.take(4).indexed) _log(prayer, at: at.add(Duration(minutes: index + 1))),
        _log(PrayerName.voluntary, at: at.add(const Duration(minutes: 30))),
      ]);

      final stats = (await religiousService.getStatistics()).data!;

      expect(stats['currentStreak'], 0);
    });
  });

  group('prayer providers', () {
    ProviderContainer container(_CapturingPrayerService service) {
      final created = ProviderContainer(
        overrides: [
          prayerServiceProvider.overrideWithValue(service),
          prayerRepositoryProvider.overrideWithValue(FakePrayerRepository(byUserIdResult: const Success(<PrayerLog>[]))),
          todayPrayerTimesProvider.overrideWith((ref) async => throw StateError('prayer times must not be read')),
        ],
      );
      addTearDown(created.dispose);
      return created;
    }

    test('should count only the daily prayers toward the prayers today count', () async {
      final service = _CapturingPrayerService(
        todayLogsResult: Success([_log(PrayerName.fajr), _log(PrayerName.dhuhr), _log(PrayerName.voluntary), _log(PrayerName.voluntary)]),
      );
      final providers = container(service);
      await providers.read(prayerLogsControllerProvider.future);

      expect(providers.read(prayerCountProvider), 2);
      expect(providers.read(voluntaryPrayerCountProvider), 2);
    });

    test('should log a voluntary prayer without reading prayer times and always as on time', () async {
      final service = _CapturingPrayerService(todayLogsResult: const Success(<PrayerLog>[]));
      final providers = container(service);
      await providers.read(prayerLogsControllerProvider.future);

      final error = await providers
          .read(prayerLogsControllerProvider.notifier)
          .addPrayer(prayer: PrayerName.voluntary, prayedAt: DateTime.now().subtract(const Duration(hours: 3)));

      expect(error, isNull);
      expect(service.loggedPrayer, PrayerName.voluntary);
      expect(service.loggedScheduledAt, isNull);
      expect(service.loggedOnTime, isTrue);
    });
  });
}
