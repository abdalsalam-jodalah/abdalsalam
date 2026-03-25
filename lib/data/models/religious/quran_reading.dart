import '../../models/base_model.dart';

class QuranReading extends BaseModel {
  final String userId;
  final int surahNumber;
  final int ayahFrom;
  final int ayahTo;
  final DateTime readAt;
  final int durationMinutes;
  final bool memorized;

  const QuranReading({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.surahNumber,
    required this.ayahFrom,
    required this.ayahTo,
    required this.readAt,
    required this.durationMinutes,
    required this.memorized,
  });

  factory QuranReading.fromJson(Map<String, dynamic> json) {
    return QuranReading(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      surahNumber: json['surahNumber'] as int,
      ayahFrom: json['ayahFrom'] as int,
      ayahTo: json['ayahTo'] as int,
      readAt: DateTime.parse(json['readAt'] as String),
      durationMinutes: json['durationMinutes'] as int,
      memorized: json['memorized'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'userId': userId,
      'surahNumber': surahNumber,
      'ayahFrom': ayahFrom,
      'ayahTo': ayahTo,
      'readAt': readAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'memorized': memorized,
    };
  }
}
