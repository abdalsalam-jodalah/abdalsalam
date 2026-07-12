import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/athkar_content.dart';
import '../../../data/models/religious/athkar_log.dart';
import '../../../data/repositories/religious/athkar_content_repository.dart';
import '../../../data/repositories/religious/athkar_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/services/settings_service.dart';
import 'athkar_content_loader.dart';

class AthkarService extends BaseServiceImpl<AthkarContent> {
  static const _uuid = Uuid();

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
  })  : _loader = loader ?? AthkarContentLoader(),
        _reminders = reminders,
        _settings = settings;

  AthkarContentRepository get _repo => repository as AthkarContentRepository;

  @override
  String get serviceName => 'AthkarService';

  @override
  String get version => '1.0.0';

  @override
  AthkarContent fromJson(Map<String, dynamic> json) => AthkarContent.fromJson(json);

  Future<void> ensureSeeded() async {
    if (_seeded) {
      return;
    }
    final bundled = await _loader.loadBundled();
    await _repo.seedFromAsset(bundled);
    _timeWindows = await _loader.loadTimeWindows();
    _seeded = true;
  }

  Future<Result<List<AthkarContent>, AppError>> getMerged({AthkarCategory? category}) async {
    await ensureSeeded();
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
      sortOrder: 1000,
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

  Future<List<AthkarCategory>> getCategoriesForNow() async {
    await ensureSeeded();
    final windows = _timeWindows ?? <String, ({String start, String end})>{};
    final now = TimeOfDayMinutes.fromDateTime(DateTime.now());

    final due = <AthkarCategory>[];
    for (final category in AthkarCategory.values) {
      final window = windows[category.name];
      if (window == null) {
        continue;
      }
      final start = TimeOfDayMinutes.parse(window.start);
      final end = TimeOfDayMinutes.parse(window.end);
      if (now.minutes >= start.minutes && now.minutes <= end.minutes) {
        due.add(category);
      }
    }
    return due;
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

  Future<void> scheduleSuggestionReminders({required String userId}) async {
    await ensureSeeded();
    final settings = await _settings.getSettings();
    final notificationsEnabled = (settings['notificationsEnabled'] as bool?) ?? true;
    final athkarRemindersEnabled = (settings['religiousAthkarRemindersEnabled'] as bool?) ?? true;
    if (!notificationsEnabled || !athkarRemindersEnabled) {
      return;
    }

    final windows = _timeWindows ?? <String, ({String start, String end})>{};
    final today = DateTime.now();

    for (final entry in windows.entries) {
      final start = TimeOfDayMinutes.parse(entry.value.start);
      final scheduledAt = DateTime(
        today.year,
        today.month,
        today.day,
        start.minutes ~/ 60,
        start.minutes % 60,
      );
      if (scheduledAt.isBefore(DateTime.now())) {
        continue;
      }
      final category = AthkarCategory.values.byName(entry.key);
      await _reminders.schedule(
        ReminderPayload(
          module: ReminderModule.religious,
          targetId: 'athkar-${entry.key}-${today.year}${today.month}${today.day}',
          title: '${_categoryLabel(category)} Athkar',
          body: 'Time for your ${_categoryLabel(category).toLowerCase()} athkar',
          scheduledAt: scheduledAt,
        ),
      );
    }
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
  final int minutes;

  const TimeOfDayMinutes(this.minutes);

  factory TimeOfDayMinutes.parse(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDayMinutes(hour * 60 + minute);
  }

  factory TimeOfDayMinutes.fromDateTime(DateTime dateTime) {
    return TimeOfDayMinutes(dateTime.hour * 60 + dateTime.minute);
  }
}
