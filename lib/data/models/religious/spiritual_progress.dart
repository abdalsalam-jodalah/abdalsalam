import '../../models/base_model.dart';

class SpiritualProgress extends BaseModel {
  final String userId;
  final DateTime date;
  final List<String> goodDeeds;
  final List<String> badDeeds;
  final String reflectionNotes;
  final String mood;
  final int overallRating;

  const SpiritualProgress({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.date,
    required this.goodDeeds,
    required this.badDeeds,
    required this.reflectionNotes,
    required this.mood,
    required this.overallRating,
  });

  factory SpiritualProgress.fromJson(Map<String, dynamic> json) {
    return SpiritualProgress(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      goodDeeds: (json['goodDeeds'] as List<dynamic>).cast<String>(),
      badDeeds: (json['badDeeds'] as List<dynamic>).cast<String>(),
      reflectionNotes: json['reflectionNotes'] as String,
      mood: json['mood'] as String,
      overallRating: json['overallRating'] as int,
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
      'date': date.toIso8601String(),
      'goodDeeds': goodDeeds,
      'badDeeds': badDeeds,
      'reflectionNotes': reflectionNotes,
      'mood': mood,
      'overallRating': overallRating,
    };
  }
}
