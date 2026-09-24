import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/json/json_reader.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../data/models/religious/prayer_times_snapshot.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../data/repositories/religious/prayer_times_snapshot_repository.dart';
import '../../../data/repositories/religious/religious_entry_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/error_handler.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/services/settings_service.dart';
import 'prayer_time_service.dart';
import 'religious_settings_keys.dart';

class ReligiousTrackerService extends BaseServiceImpl<ReligiousEntry> {
  static const int dailySyncHour = 1;

  static const _uuid = Uuid();
  static const _sourceUrl = 'https://quran-radio.com/';
  static const _adhanSourceLabel = 'adhan:muslim_world_league';
  static const _adhanSource = 'adhan';
  static const _scrapedSource = 'scraped';
  static const _userAgentHeader = 'user-agent';
  static const _userAgent = 'Mozilla/5.0 (Flutter App)';
  static const _httpOk = 200;
  static const _defaultLatitude = 32.2211;
  static const _defaultLongitude = 35.2544;
  static const _defaultReminderMinutes = 10;
  static const _minimumRetentionDays = 365;
  static const _labelSearchWindow = 240;
  static const _hoursPerHalfDay = 12;
  static const _minutesPerHour = 60;
  static const _afternoonMarker = 'م';
  static const _morningMarker = 'ص';
  static const _timePattern = r'(\d{1,2}):(\d{2})\s*([صم])';
  static const _prayerLabels = <String, PrayerName>{
    'الفجر': PrayerName.fajr,
    'الظهر': PrayerName.dhuhr,
    'العصر': PrayerName.asr,
    'المغرب': PrayerName.maghrib,
    'العشاء': PrayerName.isha,
  };

  final ReligiousEntryRepository _entriesRepo;
  final PrayerTimesSnapshotRepository _timesRepo;
  final ReminderService _reminders;
  final SettingsService _settings;
  final PrayerTimeService _prayerTimeService;
  final http.Client _httpClient;
  final DateTime Function() _clock;
  final LoggerService _serviceLogger;

  ReligiousTrackerService(
    this._entriesRepo,
    this._timesRepo,
    LoggerService logger, {
    required ReminderService reminders,
    required SettingsService settings,
    required PrayerTimeService prayerTimeService,
    http.Client? httpClient,
    DateTime Function()? clock,
  })  : _reminders = reminders,
        _clock = clock ?? DateTime.now,
        _settings = settings,
        _prayerTimeService = prayerTimeService,
        _httpClient = httpClient ?? http.Client(),
        _serviceLogger = logger,
        super(_entriesRepo, logger);

  ErrorHandler get _errorHandler => ErrorHandler(_serviceLogger);

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
    final now = _clock();
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

    final now = _clock();
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
    final now = _clock();
    final dateKey = _dateKey(now);

    final existing = await _timesRepo.getByDateKey(dateKey);
    if (existing.isFailure) {
      return Failure(existing.error!);
    }

    final existingSnapshot = existing.data;
    if (!force && existingSnapshot != null) {
      return Success(existingSnapshot);
    }

    final settingsResult = await _readSettings();
    if (settingsResult.isFailure) {
      return Failure(settingsResult.error!);
    }
    final settings = settingsResult.data!;

    final isAdhan = settings.readString(ReligiousSettingsKeys.prayerTimeSource, fallback: _scrapedSource) ==
        _adhanSource;
    final sourceLabel = isAdhan ? _adhanSourceLabel : _sourceUrl;
    final timesResult = isAdhan ? await _calculateAdhanTimes(now, settings) : await _scrapeTimes(now);
    if (timesResult.isFailure) {
      _serviceLogger.warning('[ReligiousTracker] prayer time sync failed for $dateKey: ${timesResult.error}');
      return Failure(timesResult.error!);
    }

    final snapshotResult = _buildSnapshot(
      times: timesResult.data!,
      dateKey: dateKey,
      now: now,
      createdAt: existingSnapshot?.createdAt ?? now,
      sourceLabel: sourceLabel,
    );
    if (snapshotResult.isFailure) {
      _serviceLogger.warning('[ReligiousTracker] prayer time sync failed for $dateKey: ${snapshotResult.error}');
      return snapshotResult;
    }
    final snapshot = snapshotResult.data!;

    if (existingSnapshot == null) {
      final createResult = await _timesRepo.create(snapshot);
      if (createResult.isFailure) {
        return Failure(createResult.error!);
      }
    } else {
      final updateResult = await _timesRepo.update(snapshot);
      if (updateResult.isFailure) {
        return Failure(updateResult.error!);
      }
    }

    _serviceLogger.info('[ReligiousTracker] prayer times synced for $dateKey from $sourceLabel');
    await _enforcePrayerTimesRetention(settings);
    await _schedulePrayerTimeReminders(snapshot, settings);
    return Success(snapshot);
  }

  Future<Result<PrayerTimesSnapshot, AppError>> getTodayPrayerTimes() async {
    final now = _clock();
    final dateKey = _dateKey(now);
    final existing = await _timesRepo.getByDateKey(dateKey);
    if (existing.isFailure) {
      return Failure(existing.error!);
    }
    final snapshot = existing.data;
    if (snapshot != null) {
      return Success(snapshot);
    }
    return syncPrayerTimesForToday();
  }

  Future<Result<Map<String, DateTime>, AppError>> previewSource({
    required String source,
    double? latitude,
    double? longitude,
    DateTime? date,
  }) async {
    final targetDate = date ?? _clock();
    if (source != _adhanSource) {
      return _scrapeTimes(targetDate);
    }

    final settingsResult = await _readSettings();
    if (settingsResult.isFailure) {
      return Failure(settingsResult.error!);
    }
    return _calculateAdhanTimes(
      targetDate,
      settingsResult.data!,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<Result<void, AppError>> ensurePrayerTimesFresh() async {
    if (_clock().hour < dailySyncHour) {
      return const Success(null);
    }
    final synced = await syncPrayerTimesForToday();
    return synced.map<void>((_) {});
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

  Future<Result<JsonReader, AppError>> _readSettings() {
    return Result.guardAsync<JsonReader, AppError>(
      () async => JsonReader(await _settings.getSettings(), source: ReligiousSettingsKeys.readerSource),
      onError: (error, stackTrace) => _errorHandler.mapException(
        error,
        context: 'ReligiousTracker.readSettings',
        stackTrace: stackTrace,
      ),
    );
  }

  Future<Result<Map<String, DateTime>, AppError>> _scrapeTimes(DateTime date) async {
    final http.Response response;
    try {
      response = await _httpClient.get(
        Uri.parse(_sourceUrl),
        headers: const <String, String>{_userAgentHeader: _userAgent},
      );
    } catch (error, stackTrace) {
      return Failure(
        _errorHandler.mapException(error, context: 'ReligiousTracker.scrapeTimes', stackTrace: stackTrace),
      );
    }

    if (response.statusCode != _httpOk) {
      final error = NetworkError('Failed to fetch prayer times (status ${response.statusCode})');
      _serviceLogger.warning('[ReligiousTracker] $error');
      return Failure(error);
    }

    final parsed = _parsePrayerTimes(response.body, date);
    if (parsed == null) {
      final error = CorruptDataError('Unable to parse prayer times from source page', source: _sourceUrl);
      _serviceLogger.warning('[ReligiousTracker] $error');
      return Failure(error);
    }
    return Success(parsed);
  }

  Future<Result<Map<String, DateTime>, AppError>> _calculateAdhanTimes(
    DateTime date,
    JsonReader settings, {
    double? latitude,
    double? longitude,
  }) {
    return _prayerTimeService.calculatePrayerTimes(
      date: date,
      latitude: latitude ??
          settings.readDouble(ReligiousSettingsKeys.prayerLocationLatitude, fallback: _defaultLatitude),
      longitude: longitude ??
          settings.readDouble(ReligiousSettingsKeys.prayerLocationLongitude, fallback: _defaultLongitude),
      method: settings.readString(ReligiousSettingsKeys.prayerMethod, fallback: PrayerTimeService.defaultMethod),
    );
  }

  Result<PrayerTimesSnapshot, AppError> _buildSnapshot({
    required Map<String, DateTime> times,
    required String dateKey,
    required DateTime now,
    required DateTime createdAt,
    required String sourceLabel,
  }) {
    for (final prayer in PrayerName.values) {
      if (!times.containsKey(prayer.name)) {
        return Failure(
          CorruptDataError(
            'Prayer times from $sourceLabel are missing ${prayer.name}',
            source: sourceLabel,
            field: prayer.name,
          ),
        );
      }
    }

    return Success(
      PrayerTimesSnapshot(
        id: dateKey,
        createdAt: createdAt,
        updatedAt: now,
        dateKey: dateKey,
        forDate: DateTime(now.year, now.month, now.day),
        fetchedAt: now,
        sourceUrl: sourceLabel,
        fajr: times[PrayerName.fajr.name]!,
        dhuhr: times[PrayerName.dhuhr.name]!,
        asr: times[PrayerName.asr.name]!,
        maghrib: times[PrayerName.maghrib.name]!,
        isha: times[PrayerName.isha.name]!,
      ),
    );
  }

  Future<Result<void, AppError>> _scheduleReminder(ReminderPayload payload) {
    return Result.guardAsync<void, AppError>(
      () => _reminders.schedule(payload),
      onError: (error, stackTrace) => _errorHandler.mapException(
        error,
        context: 'ReligiousTracker.scheduleReminder',
        stackTrace: stackTrace,
      ),
    );
  }

  Future<void> _schedulePrayerTimeReminders(PrayerTimesSnapshot snapshot, JsonReader settings) async {
    if (!settings.readBool(ReligiousSettingsKeys.prayerRemindersEnabled, fallback: true)) {
      return;
    }
    final minutes = settings.readInt(
      ReligiousSettingsKeys.defaultReminderMinutes,
      fallback: _defaultReminderMinutes,
    );

    final prayers = <String, DateTime>{
      'Fajr': snapshot.fajr,
      'Dhuhr': snapshot.dhuhr,
      'Asr': snapshot.asr,
      'Maghrib': snapshot.maghrib,
      'Isha': snapshot.isha,
    };

    for (final entry in prayers.entries) {
      final reminderAt = entry.value.subtract(Duration(minutes: minutes));
      if (reminderAt.isBefore(_clock())) {
        continue;
      }
      final scheduled = await _scheduleReminder(
        ReminderPayload(
          module: ReminderModule.religious,
          targetId: 'prayer-${snapshot.dateKey}-${entry.key.toLowerCase()}',
          title: '${entry.key} prayer reminder',
          body: '${entry.key} prayer is in $minutes minutes',
          scheduledAt: reminderAt,
        ),
      );
      if (scheduled.isFailure) {
        _serviceLogger.warning('[ReligiousTracker] ${entry.key} reminder for ${snapshot.dateKey} not scheduled');
      }
    }
  }

  Future<void> _scheduleReminderIfEnabled(ReligiousEntry entry) async {
    final reminderAt = entry.reminderAt;
    if (reminderAt == null || reminderAt.isBefore(_clock())) {
      return;
    }

    final settingsResult = await _readSettings();
    if (settingsResult.isFailure) {
      _serviceLogger.warning('[ReligiousTracker] reminder for ${entry.id} not scheduled: settings unavailable');
      return;
    }
    final settings = settingsResult.data!;

    final notificationsEnabled = settings.readBool(ReligiousSettingsKeys.notificationsEnabled, fallback: true);
    final moduleEnabled = settings.readBool(ReligiousSettingsKeys.remindersEnabled, fallback: true);
    if (!notificationsEnabled || !moduleEnabled) {
      return;
    }

    final typeKey = switch (entry.type) {
      ReligiousEntryType.prayer => ReligiousSettingsKeys.prayerRemindersEnabled,
      ReligiousEntryType.quranReading => ReligiousSettingsKeys.quranRemindersEnabled,
      ReligiousEntryType.badEvent => ReligiousSettingsKeys.badEventRemindersEnabled,
      ReligiousEntryType.athkar => ReligiousSettingsKeys.athkarRemindersEnabled,
      ReligiousEntryType.nightPrayer => ReligiousSettingsKeys.nightRemindersEnabled,
    };
    if (!settings.readBool(typeKey, fallback: true)) {
      return;
    }

    final scheduled = await _scheduleReminder(
      ReminderPayload(
        module: ReminderModule.religious,
        targetId: entry.id,
        title: 'Religious reminder',
        body: entry.title,
        scheduledAt: reminderAt,
      ),
    );
    if (scheduled.isFailure) {
      _serviceLogger.warning('[ReligiousTracker] reminder for ${entry.id} not scheduled');
    }
  }

  Map<String, DateTime>? _parsePrayerTimes(String html, DateTime date) {
    final result = <String, DateTime>{};
    for (final entry in _prayerLabels.entries) {
      final time = _extractTimeForLabel(html, entry.key, date);
      if (time == null) {
        return null;
      }
      result[entry.value.name] = time;
    }
    return result;
  }

  DateTime? _extractTimeForLabel(String html, String label, DateTime date) {
    final index = html.indexOf(label);
    if (index < 0) {
      return null;
    }

    final to = (index + _labelSearchWindow).clamp(0, html.length);
    final match = RegExp(_timePattern).firstMatch(html.substring(index, to));
    if (match == null) {
      return null;
    }

    final parsedHour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final marker = match.group(3);
    if (parsedHour == null || minute == null || parsedHour > _hoursPerHalfDay || minute >= _minutesPerHour) {
      return null;
    }

    var hour = parsedHour;
    if (marker == _afternoonMarker && hour < _hoursPerHalfDay) {
      hour += _hoursPerHalfDay;
    }
    if (marker == _morningMarker && hour == _hoursPerHalfDay) {
      hour = 0;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Future<void> _enforcePrayerTimesRetention(JsonReader settings) async {
    final configured = settings.readInt(
      ReligiousSettingsKeys.prayerTimesRetentionDays,
      fallback: _minimumRetentionDays,
    );
    final retentionDays = configured < _minimumRetentionDays ? _minimumRetentionDays : configured;

    final all = await _timesRepo.getAll();
    if (all.isFailure) {
      _serviceLogger.warning('[ReligiousTracker] prayer times retention skipped: ${all.error}');
      return;
    }

    final cutoff = _clock().subtract(Duration(days: retentionDays));
    for (final snapshot in all.data!) {
      if (!snapshot.forDate.isBefore(cutoff)) {
        continue;
      }
      final deleted = await _timesRepo.delete(snapshot.id);
      if (deleted.isFailure) {
        _serviceLogger.warning('[ReligiousTracker] failed to prune prayer times ${snapshot.id}: ${deleted.error}');
      }
    }
  }
}

class ReligiousPrayerSyncScheduler {
  final ReligiousTrackerService service;
  final LoggerService logger;
  Timer? _timer;

  ReligiousPrayerSyncScheduler({required this.service, required this.logger});

  void start() {
    _scheduleNext();
    unawaited(Future<void>(() async {
      final result = await service.ensurePrayerTimesFresh();
      if (result.isFailure) {
        logger.warning('[ReligiousSync] startup sync failed: ${result.error}');
      }
    }));
  }

  void dispose() {
    _timer?.cancel();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, ReligiousTrackerService.dailySyncHour);
    final target = now.isBefore(next) ? next : next.add(const Duration(days: 1));
    final delay = target.difference(now);

    logger.info('[ReligiousSync] next daily sync at ${target.toIso8601String()}');
    _timer = Timer(delay, () async {
      final result = await service.syncPrayerTimesForToday(force: true);
      if (result.isFailure) {
        logger.warning('[ReligiousSync] daily sync failed: ${result.error}');
      }
      _scheduleNext();
    });
  }
}
