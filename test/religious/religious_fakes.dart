import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/athkar_content.dart';
import 'package:abdalsalam/data/models/religious/athkar_log.dart';
import 'package:abdalsalam/data/models/religious/bad_practice_log.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/data/models/religious/prayer_times_snapshot.dart';
import 'package:abdalsalam/data/models/religious/quran_progress.dart';
import 'package:abdalsalam/data/models/religious/quran_reading.dart';
import 'package:abdalsalam/data/models/religious/religious_entry.dart';
import 'package:abdalsalam/data/repositories/religious/athkar_log_repository.dart';
import 'package:abdalsalam/data/repositories/religious/prayer_repository.dart';
import 'package:abdalsalam/data/repositories/religious/quran_reading_repository.dart';
import 'package:abdalsalam/features/religious/services/athkar_service.dart';
import 'package:abdalsalam/features/religious/services/bad_practice_service.dart';
import 'package:abdalsalam/features/religious/services/prayer_service.dart';
import 'package:abdalsalam/features/religious/services/prayer_times_cache_service.dart';
import 'package:abdalsalam/features/religious/services/quran_legacy_import_report.dart';
import 'package:abdalsalam/features/religious/services/quran_legacy_import_service.dart';
import 'package:abdalsalam/features/religious/services/quran_reading_service.dart';
import 'package:abdalsalam/features/religious/services/quran_service.dart';
import 'package:abdalsalam/features/religious/services/religious_service.dart';
import 'package:abdalsalam/features/religious/services/religious_tracker_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReminderService extends Fake implements ReminderService {
  final List<ReminderPayload> scheduled = [];
  int attemptedScheduleCount = 0;
  bool shouldFail;

  FakeReminderService({this.shouldFail = false});

  @override
  Future<void> schedule(ReminderPayload payload) async {
    attemptedScheduleCount++;
    if (shouldFail) {
      throw StateError('notifications unavailable');
    }
    scheduled.add(payload);
  }

  @override
  void handleNotificationTap(ReminderPayload payload) {}
}

class FakeAssetBundle extends CachingAssetBundle {
  final String? content;

  FakeAssetBundle(this.content);

  @override
  Future<ByteData> load(String key) async {
    final value = content;
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

class FakePrayerTimesCacheService extends Fake implements PrayerTimesCacheService {
  Result<Map<String, DateTime>?, AppError> readResult;
  Result<void, AppError> writeResult;
  final List<Map<String, DateTime>> written = [];

  FakePrayerTimesCacheService({
    this.readResult = const Success(null),
    this.writeResult = const Success(null),
  });

  @override
  Future<Result<Map<String, DateTime>?, AppError>> getForDate(DateTime date, String method) async {
    return readResult;
  }

  @override
  Future<Result<void, AppError>> cacheForDate({
    required DateTime date,
    required String method,
    required Map<String, DateTime> times,
  }) async {
    written.add(times);
    return writeResult;
  }
}

class FakePrayerRepository extends Fake implements PrayerRepository {
  Result<List<PrayerLog>, AppError> byUserIdResult;

  FakePrayerRepository({required this.byUserIdResult});

  @override
  Future<Result<List<PrayerLog>, AppError>> getByUserId(String userId) async => byUserIdResult;
}

class FakePrayerService extends Fake implements PrayerService {
  Result<List<PrayerLog>, AppError> todayLogsResult;
  Result<PrayerLog, AppError> logPrayerResult;

  FakePrayerService({required this.todayLogsResult, required this.logPrayerResult});

  @override
  Future<Result<List<PrayerLog>, AppError>> getTodayLogs(String userId) async => todayLogsResult;

  @override
  Duration computeDelta({required DateTime prayedAt, required DateTime scheduledAt}) =>
      prayedAt.difference(scheduledAt);

  @override
  Future<Result<PrayerLog, AppError>> logPrayer({
    required String userId,
    required PrayerName prayerName,
    required bool onTime,
    String? notes,
    DateTime? prayedAt,
    DateTime? scheduledAt,
  }) async =>
      logPrayerResult;
}

class FakeReligiousService extends Fake implements ReligiousService {
  Result<Map<String, dynamic>, AppError> statisticsResult;

  FakeReligiousService({required this.statisticsResult});

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async => statisticsResult;
}

class FakeAthkarLogRepository extends Fake implements AthkarLogRepository {
  Result<List<AthkarLog>, AppError> byUserIdResult;

  FakeAthkarLogRepository({required this.byUserIdResult});

  @override
  Future<Result<List<AthkarLog>, AppError>> getByUserId(String userId) async => byUserIdResult;
}

class FakeAthkarService extends Fake implements AthkarService {
  Result<List<AthkarContent>, AppError> mergedResult;
  Result<AthkarLog, AppError> logCompletionResult;
  Result<AthkarContent, AppError> addCustomAthkarResult;
  Result<void, AppError> deleteCustomAthkarResult;

  FakeAthkarService({
    required this.mergedResult,
    required this.logCompletionResult,
    required this.addCustomAthkarResult,
    required this.deleteCustomAthkarResult,
  });

  @override
  Future<Result<List<AthkarContent>, AppError>> getMerged({AthkarCategory? category}) async =>
      mergedResult;

  @override
  Future<Result<AthkarLog, AppError>> logCompletion({
    required String userId,
    required AthkarContent content,
    required int countDone,
    String? notes,
  }) async =>
      logCompletionResult;

  @override
  Future<Result<AthkarContent, AppError>> addCustomAthkar({
    required String arabicText,
    String? transliteration,
    String? translation,
    required AthkarCategory category,
    required int targetCount,
    String? reference,
  }) async =>
      addCustomAthkarResult;

  @override
  Future<Result<void, AppError>> deleteCustomAthkar(String id) async => deleteCustomAthkarResult;

  @override
  Future<Result<void, AppError>> scheduleSuggestionReminders({required String userId}) async =>
      const Success(null);
}

class FakeQuranReadingRepository extends Fake implements QuranReadingRepository {
  Result<List<QuranReading>, AppError> byUserIdResult;
  Result<List<QuranReading>, AppError> byDateRangeResult;

  FakeQuranReadingRepository({required this.byUserIdResult, required this.byDateRangeResult});

  @override
  Future<Result<List<QuranReading>, AppError>> getByUserId(String userId) async =>
      byUserIdResult;

  @override
  Future<Result<List<QuranReading>, AppError>> getByDateRange(DateTime start, DateTime end) async =>
      byDateRangeResult;
}

class FakeQuranReadingService extends Fake implements QuranReadingService {
  Result<List<QuranReading>, AppError> todayReadingsResult;
  Result<QuranReading, AppError> logReadingResult;
  Result<List<QuranReading>, AppError> byDateRangeResult;

  FakeQuranReadingService({
    required this.todayReadingsResult,
    required this.logReadingResult,
    required this.byDateRangeResult,
  });

  @override
  Future<Result<List<QuranReading>, AppError>> getTodayReadings(String userId) async =>
      todayReadingsResult;

  @override
  Future<Result<List<QuranReading>, AppError>> getByDateRange(DateTime start, DateTime end) async =>
      byDateRangeResult;

  @override
  Future<Result<QuranReading, AppError>> logReading({
    required String userId,
    required int surahNumber,
    required int ayahFrom,
    required int ayahTo,
    required int durationMinutes,
    required int pagesRead,
    required bool memorized,
    String? place,
    DateTime? readAt,
  }) async =>
      logReadingResult;
}

class FakeQuranLegacyImportService extends Fake implements QuranLegacyImportService {
  Result<QuranLegacyImportReport, AppError> importResult;

  FakeQuranLegacyImportService({required this.importResult});

  @override
  Future<Result<QuranLegacyImportReport, AppError>> importLegacyProgress() async => importResult;
}

class FakeReligiousTrackerService extends Fake implements ReligiousTrackerService {
  Result<PrayerTimesSnapshot, AppError> todayPrayerTimesResult;
  Result<Map<String, DateTime>, AppError> previewSourceResult;
  Result<List<ReligiousEntry>, AppError> historyResult;
  Result<ReligiousEntry, AppError> logEntryResult;
  Result<PrayerTimesSnapshot, AppError> syncResult;

  FakeReligiousTrackerService({
    required this.todayPrayerTimesResult,
    required this.previewSourceResult,
    required this.historyResult,
    required this.logEntryResult,
    required this.syncResult,
  });

  @override
  Future<Result<PrayerTimesSnapshot, AppError>> getTodayPrayerTimes() async =>
      todayPrayerTimesResult;

  @override
  Future<Result<Map<String, DateTime>, AppError>> previewSource({
    required String source,
    double? latitude,
    double? longitude,
    DateTime? date,
  }) async =>
      previewSourceResult;

  @override
  Future<Result<List<ReligiousEntry>, AppError>> getHistory(String userId) async => historyResult;

  @override
  Future<Result<ReligiousEntry, AppError>> logEntry({
    required String userId,
    required ReligiousEntryType type,
    required String title,
    required int count,
    String? details,
    String? prayerName,
    DateTime? reminderAt,
  }) async =>
      logEntryResult;

  @override
  Future<Result<PrayerTimesSnapshot, AppError>> syncPrayerTimesForToday({bool force = false}) async =>
      syncResult;
}

class FakeQuranService extends Fake implements QuranService {
  Result<List<QuranProgress>, AppError> todayProgressResult;
  Result<QuranProgress, AppError> logProgressResult;

  FakeQuranService({required this.todayProgressResult, required this.logProgressResult});

  @override
  Future<Result<List<QuranProgress>, AppError>> getTodayProgress(String userId) async =>
      todayProgressResult;

  @override
  Future<Result<QuranProgress, AppError>> logProgress({
    required String userId,
    required int pagesRead,
    required int minutesSpent,
  }) async =>
      logProgressResult;
}

class FakeBadPracticeService extends Fake implements BadPracticeService {
  Result<List<BadPracticeLog>, AppError> historyResult;
  Result<BadPracticeLog, AppError> logEventResult;

  FakeBadPracticeService({required this.historyResult, required this.logEventResult});

  @override
  Future<Result<List<BadPracticeLog>, AppError>> getHistory(String userId) async => historyResult;

  @override
  Future<Result<BadPracticeLog, AppError>> logEvent({
    required String userId,
    required String title,
    required DateTime occurredAt,
    String? feelingBefore,
    String? feelingAfter,
    String? consequences,
    String? notes,
  }) async =>
      logEventResult;
}
