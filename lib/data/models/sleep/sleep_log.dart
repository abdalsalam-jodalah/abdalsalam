import '../../../core/json/json_reader.dart';
import '../base_model.dart';

class SleepLog extends BaseModel {
  final String userId;
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final int nightWakeCount;
  final int? feelingBeforeSleep;
  final String? feelingBeforeSleepNote;
  final int? feelingOnWakeup;
  final String? feelingOnWakeupNote;
  final int? feelingDuringDay;
  final String? feelingDuringDayNote;
  final DateTime? lastCaffeineTime;
  final String? notes;

  const SleepLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.sleepStart,
    required this.sleepEnd,
    this.nightWakeCount = 0,
    this.feelingBeforeSleep,
    this.feelingBeforeSleepNote,
    this.feelingOnWakeup,
    this.feelingOnWakeupNote,
    this.feelingDuringDay,
    this.feelingDuringDayNote,
    this.lastCaffeineTime,
    this.notes,
  });

  Duration get duration => sleepEnd.difference(sleepStart);

  SleepLog copyWith({
    String? userId,
    DateTime? sleepStart,
    DateTime? sleepEnd,
    int? nightWakeCount,
    int? feelingBeforeSleep,
    String? feelingBeforeSleepNote,
    int? feelingOnWakeup,
    String? feelingOnWakeupNote,
    int? feelingDuringDay,
    String? feelingDuringDayNote,
    DateTime? lastCaffeineTime,
    String? notes,
    DateTime? updatedAt,
  }) =>
      SleepLog(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId ?? this.userId,
        sleepStart: sleepStart ?? this.sleepStart,
        sleepEnd: sleepEnd ?? this.sleepEnd,
        nightWakeCount: nightWakeCount ?? this.nightWakeCount,
        feelingBeforeSleep: feelingBeforeSleep ?? this.feelingBeforeSleep,
        feelingBeforeSleepNote: feelingBeforeSleepNote ?? this.feelingBeforeSleepNote,
        feelingOnWakeup: feelingOnWakeup ?? this.feelingOnWakeup,
        feelingOnWakeupNote: feelingOnWakeupNote ?? this.feelingOnWakeupNote,
        feelingDuringDay: feelingDuringDay ?? this.feelingDuringDay,
        feelingDuringDayNote: feelingDuringDayNote ?? this.feelingDuringDayNote,
        lastCaffeineTime: lastCaffeineTime ?? this.lastCaffeineTime,
        notes: notes ?? this.notes,
      );

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'SleepLog');
    final createdAt = reader.requireDate('createdAt');
    return SleepLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      sleepStart: reader.requireDate('sleepStart'),
      sleepEnd: reader.requireDate('sleepEnd'),
      nightWakeCount: reader.readInt('nightWakeCount'),
      feelingBeforeSleep: reader.optionalInt('feelingBeforeSleep'),
      feelingBeforeSleepNote: reader.optionalString('feelingBeforeSleepNote'),
      feelingOnWakeup: reader.optionalInt('feelingOnWakeup'),
      feelingOnWakeupNote: reader.optionalString('feelingOnWakeupNote'),
      feelingDuringDay: reader.optionalInt('feelingDuringDay'),
      feelingDuringDayNote: reader.optionalString('feelingDuringDayNote'),
      lastCaffeineTime: reader.optionalDate('lastCaffeineTime'),
      notes: reader.optionalString('notes'),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'sleepStart': sleepStart.toIso8601String(),
        'sleepEnd': sleepEnd.toIso8601String(),
        'nightWakeCount': nightWakeCount,
        'feelingBeforeSleep': feelingBeforeSleep,
        'feelingBeforeSleepNote': feelingBeforeSleepNote,
        'feelingOnWakeup': feelingOnWakeup,
        'feelingOnWakeupNote': feelingOnWakeupNote,
        'feelingDuringDay': feelingDuringDay,
        'feelingDuringDayNote': feelingDuringDayNote,
        'lastCaffeineTime': lastCaffeineTime?.toIso8601String(),
        'notes': notes,
      };
}
