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

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
        reminderTimes: (json['reminderTimes'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        prescribedBy: json['prescribedBy'] as String?,
        notes: json['notes'] as String?,
        refillDate: json['refillDate'] == null ? null : DateTime.parse(json['refillDate'] as String),
        displayOrder: json['displayOrder'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        timing: json['timing'] != null 
            ? MedicationTiming.values.firstWhere(
                (e) => e.name == json['timing'],
                orElse: () => MedicationTiming.anytime,
              )
            : MedicationTiming.anytime,
        weekDays: json['weekDays'] != null
            ? (json['weekDays'] as List<dynamic>)
                .map((e) => WeekDay.values.firstWhere(
                      (day) => day.name == e,
                      orElse: () => WeekDay.monday,
                    ))
                .toList()
            : const [],
      );

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
