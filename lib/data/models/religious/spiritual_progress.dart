import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class SpiritualProgress extends BaseModel {
  static const String _jsonSource = 'SpiritualProgress';

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
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return SpiritualProgress(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      date: reader.readDate('date', fallback: createdAt),
      goodDeeds: reader.readStringList('goodDeeds'),
      badDeeds: reader.readStringList('badDeeds'),
      reflectionNotes: reader.readString('reflectionNotes'),
      mood: reader.readString('mood'),
      overallRating: reader.readInt('overallRating'),
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
