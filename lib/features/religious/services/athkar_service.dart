import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/json/json_reader.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/athkar_content.dart';
import '../../../data/models/religious/athkar_log.dart';
import '../../../data/repositories/religious/athkar_content_repository.dart';
import '../../../data/repositories/religious/athkar_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/error_handler.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/services/settings_service.dart';
import 'athkar_content_loader.dart';
import 'religious_settings_keys.dart';

class AthkarService extends BaseServiceImpl<AthkarContent> {
  static const _uuid = Uuid();
  static const _customSortOrder = 1000;

  final AthkarLogRepository _logsRepo;
  final AthkarContentLoader _loader;
  final ReminderService _reminders;
  final SettingsService _settings;

  bool _seeded = false;
  Map<String, ({String start, String end})>? _timeWindows;

  AthkarService(
    super.repository,
    this._logsRepo,
    super.logger, {
    required ReminderService reminders,
    required SettingsService settings,
    AthkarContentLoader? loader,
  })  : _loader = loader ?? AthkarContentLoader(logger),
        _reminders = reminders,
        _settings = settings;

  AthkarContentRepository get _repo => repository as AthkarContentRepository;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  @override
  String get serviceName => 'AthkarService';

  @override
  String get version => '1.0.0';

  @override
  AthkarContent fromJson(Map<String, dynamic> json) => AthkarContent.fromJson(json);

  Future<Result<void, AppError>> ensureSeeded() async {
    if (_seeded) {
      return const Success(null);
    }
    final bundled = await _loader.loadBundled();
    if (bundled.isFailure) {
      logger.warning('[$serviceName] seeding skipped, bundled athkar unavailable: ${bundled.error}');
      return Failure(bundled.error!);
    }
    final seeded = await _repo.seedFromAsset(bundled.data!);
    if (seeded.isFailure) {
      logger.warning('[$serviceName] seeding failed: ${seeded.error}');
      return Failure(seeded.error!);
    }
    final windows = await _loader.loadTimeWindows();
    if (windows.isFailure) {
      logger.warning('[$serviceName] time windows unavailable: ${windows.error}');
      return Failure(windows.error!);
    }
    _timeWindows = windows.data;
    _seeded = true;
    return const Success(null);
  }

  Future<Result<List<AthkarContent>, AppError>> getMerged({AthkarCategory? category}) async {
    final seeded = await ensureSeeded();
    if (seeded.isFailure) {
      return Failure(seeded.error!);
    }
    if (category != null) {
      return _repo.getByCategory(category);
    }
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }
    final sorted = [...all.data!]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Success(sorted);
  }

  Future<Result<AthkarContent, AppError>> addCustomAthkar({
    required String arabicText,
    String? transliteration,
    String? translation,
    required AthkarCategory category,
    required int targetCount,
    String? reference,
  }) async {
    final now = DateTime.now();
    final entity = AthkarContent(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      category: category,
      arabicText: arabicText,
      transliteration: transliteration,
      translation: translation,
      targetCount: targetCount,
      reference: reference,
      isBuiltIn: false,
      isCustom: true,
      sortOrder: _customSortOrder,
    );
    return create(entity);
  }

  Future<Result<void, AppError>> deleteCustomAthkar(String id) async {
    final existing = await getById(id);
    if (existing.isFailure) {
      return Failure(existing.error!);
    }
    final content = existing.data;
    if (content == null) {
      return const Success(null);
    }
    if (content.isBuiltIn) {
      return Failure(
        ValidationError(
          'Cannot delete a built-in athkar entry',
          fieldErrors: const <String, String>{'id': 'built-in entries are read-only'},
        ),
      );
    }
    return softDelete(id);
  }

  Future<Result<List<AthkarCategory>, AppError>> getCategoriesForNow() async {
    final seeded = await ensureSeeded();
    if (seeded.isFailure) {
      return Failure(seeded.error!);
    }
    final windows = _timeWindows ?? <String, ({String start, String end})>{};
    final now = TimeOfDayMinutes.fromDateTime(DateTime.now());

    final due = <AthkarCategory>[];
    for (final category in AthkarCategory.values) {
      final window = windows[category.name];
      if (window == null) {
        continue;
      }
      final start = TimeOfDayMinutes.tryParse(window.start);
      final end = TimeOfDayMinutes.tryParse(window.end);
      if (start == null || end == null) {
        logger.warning('[$serviceName] ignoring invalid time window for ${category.name}');
        continue;
      }
      if (now.minutes >= start.minutes && now.minutes <= end.minutes) {
        due.add(category);
      }
    }
    return Success(due);
  }

  Future<Result<AthkarLog, AppError>> logCompletion({
    required String userId,
    required AthkarContent content,
    required int countDone,
    String? notes,
  }) async {
    final now = DateTime.now();
    final entity = AthkarLog(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      athkarContentId: content.id,
      category: content.category,
      countDone: countDone,
      targetCount: content.targetCount,
      completedAt: now,
      notes: notes,
    );
    return _logsRepo.create(entity);
  }

  Future<Result<void, AppError>> scheduleSuggestionReminders({required String userId}) async {
    final seeded = await ensureSeeded();
    if (seeded.isFailure) {
      return Failure(seeded.error!);
    }

    final Map<String, dynamic> storedSettings;
    try {
      storedSettings = await _settings.getSettings();
    } catch (error, stackTrace) {
      return Failure(
        _errorHandler.mapException(error, context: '$serviceName.scheduleSuggestionReminders', stackTrace: stackTrace),
      );
    }
    final settings = JsonReader(storedSettings, source: ReligiousSettingsKeys.readerSource);
    final notificationsEnabled = settings.readBool(ReligiousSettingsKeys.notificationsEnabled, fallback: true);
    final athkarRemindersEnabled = settings.readBool(ReligiousSettingsKeys.athkarRemindersEnabled, fallback: true);
    if (!notificationsEnabled || !athkarRemindersEnabled) {
      return const Success(null);
    }

    final windows = _timeWindows ?? <String, ({String start, String end})>{};
    final today = DateTime.now();

    for (final entry in windows.entries) {
      final start = TimeOfDayMinutes.tryParse(entry.value.start);
      final category = AthkarCategory.values.asNameMap()[entry.key];
      if (start == null || category == null) {
        logger.warning('[$serviceName] ignoring invalid reminder window "${entry.key}"');
        continue;
      }
      final scheduledAt = DateTime(
        today.year,
        today.month,
        today.day,
        start.hour,
        start.minute,
      );
      if (scheduledAt.isBefore(DateTime.now())) {
        continue;
      }
      final payload = ReminderPayload(
        module: ReminderModule.religious,
        targetId: 'athkar-${entry.key}-${today.year}${today.month}${today.day}',
        title: '${_categoryLabel(category)} Athkar',
        body: 'Time for your ${_categoryLabel(category).toLowerCase()} athkar',
        scheduledAt: scheduledAt,
      );
      try {
        await _reminders.schedule(payload);
      } catch (error, stackTrace) {
        return Failure(
          _errorHandler.mapException(error, context: '$serviceName.scheduleSuggestionReminders', stackTrace: stackTrace),
        );
      }
    }
    return const Success(null);
  }

  String _categoryLabel(AthkarCategory category) {
    return switch (category) {
      AthkarCategory.morning => 'Morning',
      AthkarCategory.evening => 'Evening',
      AthkarCategory.afterPrayer => 'After Prayer',
      AthkarCategory.sleep => 'Sleep',
      AthkarCategory.wakingUp => 'Waking Up',
      AthkarCategory.custom => 'Custom',
    };
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final allResult = await _repo.getActive();
    if (allResult.isFailure) {
      return Failure(allResult.error!);
    }
    final logsResult = await _logsRepo.getAll();
    if (logsResult.isFailure) {
      return Failure(logsResult.error!);
    }
    return Success(<String, dynamic>{
      'totalContent': allResult.data!.length,
      'totalLogs': logsResult.data!.length,
    });
  }

  @override
  Result<void, AppError> validate(AthkarContent entity) {
    if (entity.arabicText.trim().isEmpty) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{'arabicText': 'arabicText is required'},
        ),
      );
    }
    if (entity.targetCount <= 0) {
      return Failure(
        ValidationError(
          'Validation failed',
          fieldErrors: const <String, String>{
            'targetCount': 'targetCount must be greater than zero',
          },
        ),
      );
    }
    return const Success(null);
  }
}

class TimeOfDayMinutes {
  static const _separator = ':';
  static const _minutesPerHour = 60;
  static const _hoursPerDay = 24;

  final int minutes;

  const TimeOfDayMinutes(this.minutes);

  int get hour => minutes ~/ _minutesPerHour;

  int get minute => minutes % _minutesPerHour;

  static TimeOfDayMinutes? tryParse(String value) {
    final parts = value.split(_separator);
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour >= _hoursPerDay || minute < 0 || minute >= _minutesPerHour) {
      return null;
    }
    return TimeOfDayMinutes(hour * _minutesPerHour + minute);
  }

  factory TimeOfDayMinutes.fromDateTime(DateTime dateTime) {
    return TimeOfDayMinutes(dateTime.hour * _minutesPerHour + dateTime.minute);
  }
}
