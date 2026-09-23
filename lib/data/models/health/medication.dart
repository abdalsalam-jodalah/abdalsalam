import '../../../core/errors/app_error.dart';
import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

enum MedicationTiming {
  beforeMeal,
  withMeal,
  afterMeal,
  beforeBed,
  anytime,
}

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class Medication extends BaseModel {
  static const String _weekDaysKey = 'weekDays';

  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> reminderTimes; // Format: "HH:mm"
  final String? prescribedBy;
  final String? notes;
  final DateTime? refillDate;
  final int displayOrder; // For custom ordering in the list
  @override
  final bool isActive; // Quick toggle for pausing medication
  final MedicationTiming timing; // When to take it (before/with/after meal, etc.)
  final List<WeekDay> weekDays; // For weekly medications - which days

  const Medication({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.reminderTimes,
    this.prescribedBy,
    this.notes,
    this.refillDate,
    this.displayOrder = 0,
    this.isActive = true,
    this.timing = MedicationTiming.anytime,
    this.weekDays = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Medication');
    final createdAt = reader.requireDate('createdAt');
    return Medication(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      name: reader.requireString('name'),
      dosage: reader.readString('dosage'),
      frequency: reader.readString('frequency'),
      startDate: reader.readDate('startDate', fallback: createdAt),
      endDate: reader.optionalDate('endDate'),
      reminderTimes: reader.readStringList('reminderTimes'),
      prescribedBy: reader.optionalString('prescribedBy'),
      notes: reader.optionalString('notes'),
      refillDate: reader.optionalDate('refillDate'),
      displayOrder: reader.readInt('displayOrder'),
      isActive: reader.readBool('isActive', fallback: true),
      timing: reader.readEnum('timing', MedicationTiming.values, fallback: MedicationTiming.anytime),
      weekDays: _readWeekDays(reader),
    );
  }

  static List<WeekDay> _readWeekDays(JsonReader reader) {
    final names = reader.readStringList(_weekDaysKey);
    final days = [
      for (final name in names) ...WeekDay.values.where((day) => day.name == name),
    ];
    if (days.length != names.length) {
      throw CorruptDataError(
        'Medication: unknown value in "$_weekDaysKey"',
        source: 'Medication',
        field: _weekDaysKey,
      );
    }
    return days;
  }

  Medication copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? reminderTimes,
    String? prescribedBy,
    String? notes,
    DateTime? refillDate,
    int? displayOrder,
    bool? isActive,
    MedicationTiming? timing,
    List<WeekDay>? weekDays,
  }) =>
      Medication(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        reminderTimes: reminderTimes ?? this.reminderTimes,
        prescribedBy: prescribedBy ?? this.prescribedBy,
        notes: notes ?? this.notes,
        refillDate: refillDate ?? this.refillDate,
        displayOrder: displayOrder ?? this.displayOrder,
        isActive: isActive ?? this.isActive,
        timing: timing ?? this.timing,
        weekDays: weekDays ?? this.weekDays,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'reminderTimes': reminderTimes,
        'prescribedBy': prescribedBy,
        'notes': notes,
        'refillDate': refillDate?.toIso8601String(),
        'displayOrder': displayOrder,
        'isActive': isActive,
        'timing': timing.name,
        'weekDays': weekDays.map((e) => e.name).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        dosage,
        frequency,
        startDate,
        endDate,
        reminderTimes,
        prescribedBy,
        notes,
        refillDate,
        displayOrder,
        isActive,
        timing,
        weekDays,
      ];

  String get timingLabel {
    switch (timing) {
      case MedicationTiming.beforeMeal:
        return 'Before meal';
      case MedicationTiming.withMeal:
        return 'With meal';
      case MedicationTiming.afterMeal:
        return 'After meal';
      case MedicationTiming.beforeBed:
        return 'Before bed';
      case MedicationTiming.anytime:
        return 'Anytime';
    }
  }

  String get weekDaysLabel {
    if (weekDays.isEmpty) return 'All days';
    if (weekDays.length == 7) return 'All days';
    return weekDays.map((d) => _weekDayShort(d)).join(', ');
  }

  String _weekDayShort(WeekDay day) {
    switch (day) {
      case WeekDay.monday:
        return 'Mon';
      case WeekDay.tuesday:
        return 'Tue';
      case WeekDay.wednesday:
        return 'Wed';
      case WeekDay.thursday:
        return 'Thu';
      case WeekDay.friday:
        return 'Fri';
      case WeekDay.saturday:
        return 'Sat';
      case WeekDay.sunday:
        return 'Sun';
    }
  }
}
