import '../../models/base_model.dart';

class BloodTest extends BaseModel {
  final String userId;
  final String testType;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final Map<String, dynamic> results;
  final String? notes;
  final DateTime? nextTestDate;
  final String? facility;

  const BloodTest({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.testType,
    required this.scheduledDate,
    required this.completedDate,
    required this.results,
    required this.notes,
    required this.nextTestDate,
    required this.facility,
  });

  BloodTest copyWith({
    String? userId,
    String? testType,
    DateTime? scheduledDate,
    DateTime? completedDate,
    Map<String, dynamic>? results,
    String? notes,
    DateTime? nextTestDate,
    String? facility,
    DateTime? updatedAt,
  }) =>
      BloodTest(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId ?? this.userId,
        testType: testType ?? this.testType,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        completedDate: completedDate ?? this.completedDate,
        results: results ?? this.results,
        notes: notes ?? this.notes,
        nextTestDate: nextTestDate ?? this.nextTestDate,
        facility: facility ?? this.facility,
      );

  factory BloodTest.fromJson(Map<String, dynamic> json) => BloodTest(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        testType: json['testType'] as String,
        scheduledDate: DateTime.parse(json['scheduledDate'] as String),
        completedDate: json['completedDate'] == null ? null : DateTime.parse(json['completedDate'] as String),
        results: (json['results'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
        notes: json['notes'] as String?,
        nextTestDate: json['nextTestDate'] == null ? null : DateTime.parse(json['nextTestDate'] as String),
        facility: json['facility'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'testType': testType,
        'scheduledDate': scheduledDate.toIso8601String(),
        'completedDate': completedDate?.toIso8601String(),
        'results': results,
        'notes': notes,
        'nextTestDate': nextTestDate?.toIso8601String(),
        'facility': facility,
      };
}
