import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/prayer_times_snapshot.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../data/repositories/religious/prayer_times_snapshot_repository.dart';
import '../../../data/repositories/religious/religious_entry_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/services/settings_service.dart';

class ReligiousTrackerService extends BaseServiceImpl<ReligiousEntry> {
  static const _uuid = Uuid();
  static const _sourceUrl = 'https://quran-radio.com/';

  final ReligiousEntryRepository _entriesRepo;
  final PrayerTimesSnapshotRepository _timesRepo;
  final ReminderService _reminders;
  final SettingsService _settings;
  final http.Client _httpClient;
  final LoggerService _serviceLogger;

  ReligiousTrackerService(
    this._entriesRepo,
    this._timesRepo,
    LoggerService logger, {
    required ReminderService reminders,
    required SettingsService settings,
    http.Client? httpClient,
  })  : _reminders = reminders,
        _settings = settings,
        _httpClient = httpClient ?? http.Client(),
        _serviceLogger = logger,
        super(_entriesRepo, logger);

  @override
  String get serviceName => 'ReligiousTrackerService';

  @override
  String get version => '1.0.0';

  @override
  ReligiousEntry fromJson(Map<String, dynamic> json) {
    return ReligiousEntry.fromJson(json);
  }

  Future<Result<ReligiousEntry, AppError>> logEntry({
    required String userId,
    required ReligiousEntryType type,
    required String title,
    required int count,
    String? details,
    String? prayerName,
    DateTime? reminderAt,
  }) async {
    final now = DateTime.now();
    final entry = ReligiousEntry(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      type: type,
      loggedAt: now,
      title: title,
      details: details,
      count: count,
      reminderAt: reminderAt,
      prayerName: prayerName,
    );

    final created = await create(entry);
    if (created.isFailure) {
      return Failure(created.error!);
    }

    await _scheduleReminderIfEnabled(entry);
    return Success(entry);
  }

  Future<Result<List<ReligiousEntry>, AppError>> getTodayEntries(String userId) async {
    final all = await _entriesRepo.getByUserId(userId);
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final now = DateTime.now();
    final today = all.data!
        .where(
          (entry) =>
              entry.loggedAt.year == now.year &&
              entry.loggedAt.month == now.month &&
              entry.loggedAt.day == now.day,
        )
        .toList(growable: false);
    return Success(today);
  }

  Future<Result<List<ReligiousEntry>, AppError>> getHistory(String userId) {
    return _entriesRepo.getByUserId(userId);
  }

  Future<Result<PrayerTimesSnapshot, AppError>> syncPrayerTimesForToday({
    bool force = false,
  }) async {
    final now = DateTime.now();
    final dateKey = _dateKey(now);

    final existing = await _timesRepo.getByDateKey(dateKey);
    if (existing.isFailure) {
      return Failure(existing.error!);
    }

    if (!force && existing.data != null) {
      return Success(existing.data!);
    }

    try {
      final response = await _httpClient.get(
        Uri.parse(_sourceUrl),
        headers: const <String, String>{
          'user-agent': 'Mozilla/5.0 (Flutter App)',
        },
      );
      if (response.statusCode != 200) {
        return Failure(NetworkError('Failed to fetch prayer times (status ${response.statusCode})'));
      }

      final parsed = _parsePrayerTimes(response.body, now);
      if (parsed == null) {
        return Failure(ValidationError('Unable to parse prayer times from source page'));
      }

      final snapshot = PrayerTimesSnapshot(
        id: dateKey,
        createdAt: now,
        updatedAt: now,
        dateKey: dateKey,
        forDate: DateTime(now.year, now.month, now.day),
        fetchedAt: now,
        sourceUrl: _sourceUrl,
        fajr: parsed['fajr']!,
        dhuhr: parsed['dhuhr']!,
        asr: parsed['asr']!,
        maghrib: parsed['maghrib']!,
        isha: parsed['isha']!,
      );

      final created = await _timesRepo.create(snapshot);
      if (created.isFailure) {
        return Failure(created.error!);
      }

      _serviceLogger.info('[ReligiousTracker] prayer times synced for $dateKey from $_sourceUrl');
      await _schedulePrayerTimeReminders(snapshot);
      return Success(snapshot);
    } catch (e, st) {
      _serviceLogger.error('[ReligiousTracker] prayer time sync failed', error: e, stackTrace: st);
      return Failure(NetworkError(e.toString()));
    }
  }

  Future<Result<PrayerTimesSnapshot, AppError>> getTodayPrayerTimes() async {
    final now = DateTime.now();
    final dateKey = _dateKey(now);
    final existing = await _timesRepo.getByDateKey(dateKey);
    if (existing.isFailure) {
      return Failure(existing.error!);
    }
    if (existing.data != null) {
      return Success(existing.data!);
    }
    return syncPrayerTimesForToday();
  }

  Future<void> ensurePrayerTimesFresh() async {
    final now = DateTime.now();
    if (now.hour < 1) {
      return;
    }
    await syncPrayerTimesForToday();
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _entriesRepo.getAll();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final data = all.data!;
    return Success(<String, dynamic>{
      'totalLogs': data.length,
      'totalPrayersLogged': data
          .where((e) => e.type == ReligiousEntryType.prayer)
          .fold<int>(0, (sum, e) => sum + e.count),
      'totalQuranPages': data
          .where((e) => e.type == ReligiousEntryType.quranReading)
          .fold<int>(0, (sum, e) => sum + e.count),
      'athkarCount': data
          .where((e) => e.type == ReligiousEntryType.athkar)
          .fold<int>(0, (sum, e) => sum + e.count),
      'nightPrayerCount': data
          .where((e) => e.type == ReligiousEntryType.nightPrayer)
          .fold<int>(0, (sum, e) => sum + e.count),
    });
  }

  @override
  Result<void, AppError> validate(ReligiousEntry entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.title.trim().isEmpty) {
      return Failure(ValidationError('title is required'));
    }
    if (entity.count <= 0) {
      return Failure(ValidationError('count must be greater than zero'));
    }
    return const Success(null);
  }

  Future<void> _schedulePrayerTimeReminders(PrayerTimesSnapshot snapshot) async {
    final settings = await _settings.getSettings();
    final minutes = (settings['religiousDefaultReminderMinutes'] as int?) ?? 10;
    final prayerEnabled = (settings['religiousPrayerRemindersEnabled'] as bool?) ?? true;
    if (!prayerEnabled) {
      return;
    }

    final prayers = <String, DateTime>{
      'Fajr': snapshot.fajr,
      'Dhuhr': snapshot.dhuhr,
      'Asr': snapshot.asr,
      'Maghrib': snapshot.maghrib,
      'Isha': snapshot.isha,
    };

    for (final entry in prayers.entries) {
      final reminderAt = entry.value.subtract(Duration(minutes: minutes));
      if (reminderAt.isBefore(DateTime.now())) {
        continue;
      }
      await _reminders.schedule(
        ReminderPayload(
          module: ReminderModule.religious,
          targetId: 'prayer-${snapshot.dateKey}-${entry.key.toLowerCase()}',
          title: '${entry.key} prayer reminder',
          body: '${entry.key} prayer is in $minutes minutes',
          scheduledAt: reminderAt,
        ),
      );
    }
  }

  Future<void> _scheduleReminderIfEnabled(ReligiousEntry entry) async {
    if (entry.reminderAt == null || entry.reminderAt!.isBefore(DateTime.now())) {
      return;
    }

    final settings = await _settings.getSettings();
    final notificationsEnabled = (settings['notificationsEnabled'] as bool?) ?? true;
    final moduleEnabled = (settings['religiousRemindersEnabled'] as bool?) ?? true;

    if (!notificationsEnabled || !moduleEnabled) {
      return;
    }

    final typeEnabled = switch (entry.type) {
      ReligiousEntryType.prayer => (settings['religiousPrayerRemindersEnabled'] as bool?) ?? true,
      ReligiousEntryType.quranReading => (settings['religiousQuranRemindersEnabled'] as bool?) ?? true,
      ReligiousEntryType.badEvent => (settings['religiousBadEventRemindersEnabled'] as bool?) ?? true,
      ReligiousEntryType.athkar => (settings['religiousAthkarRemindersEnabled'] as bool?) ?? true,
      ReligiousEntryType.nightPrayer => (settings['religiousNightRemindersEnabled'] as bool?) ?? true,
    };

    if (!typeEnabled) {
      return;
    }

    await _reminders.schedule(
      ReminderPayload(
        module: ReminderModule.religious,
        targetId: entry.id,
        title: 'Religious reminder',
        body: entry.title,
        scheduledAt: entry.reminderAt!,
      ),
    );
  }

  Map<String, DateTime>? _parsePrayerTimes(String html, DateTime date) {
    final result = <String, DateTime>{};

    final labels = <String, String>{
      'الفجر': 'fajr',
      'الظهر': 'dhuhr',
      'العصر': 'asr',
      'المغرب': 'maghrib',
      'العشاء': 'isha',
    };

    for (final entry in labels.entries) {
      final time = _extractTimeForLabel(html, entry.key, date);
      if (time == null) {
        return null;
      }
      result[entry.value] = time;
    }

    return result;
  }

  DateTime? _extractTimeForLabel(String html, String label, DateTime date) {
    final index = html.indexOf(label);
    if (index < 0) {
      return null;
    }

    final from = index;
    final to = (index + 240).clamp(0, html.length);
    final window = html.substring(from, to);

    final pattern = RegExp(r'(\d{1,2}):(\d{2})\s*([صم])');
    final match = pattern.firstMatch(window);
    if (match == null) {
      return null;
    }

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final marker = match.group(3)!;

    if (marker == 'م' && hour < 12) {
      hour += 12;
    }
    if (marker == 'ص' && hour == 12) {
      hour = 0;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

class ReligiousPrayerSyncScheduler {
  final ReligiousTrackerService service;
  final LoggerService logger;
  Timer? _timer;

  ReligiousPrayerSyncScheduler({required this.service, required this.logger});

  void start() {
    _scheduleNext();
    Future<void>(() async {
      await service.ensurePrayerTimesFresh();
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, 1);
    final target = now.isBefore(next) ? next : next.add(const Duration(days: 1));
    final delay = target.difference(now);

    logger.info('[ReligiousSync] next daily sync at ${target.toIso8601String()}');
    _timer = Timer(delay, () async {
      await service.syncPrayerTimesForToday(force: true);
      _scheduleNext();
    });
  }
}
