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

  factory SleepLog.fromJson(Map<String, dynamic> json) => SleepLog(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        sleepStart: DateTime.parse(json['sleepStart'] as String),
        sleepEnd: DateTime.parse(json['sleepEnd'] as String),
        nightWakeCount: (json['nightWakeCount'] as num?)?.toInt() ?? 0,
        feelingBeforeSleep: (json['feelingBeforeSleep'] as num?)?.toInt(),
        feelingBeforeSleepNote: json['feelingBeforeSleepNote'] as String?,
        feelingOnWakeup: (json['feelingOnWakeup'] as num?)?.toInt(),
        feelingOnWakeupNote: json['feelingOnWakeupNote'] as String?,
        feelingDuringDay: (json['feelingDuringDay'] as num?)?.toInt(),
        feelingDuringDayNote: json['feelingDuringDayNote'] as String?,
        lastCaffeineTime:
            json['lastCaffeineTime'] == null ? null : DateTime.parse(json['lastCaffeineTime'] as String),
        notes: json['notes'] as String?,
      );

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
