import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

enum ReviewPeriod { daily, weekly, monthly, quarterly }

class Review extends BaseModel {
  final String userId;
  final ReviewPeriod period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? wins;
  final String? challenges;
  final String? lessonsLearned;
  final String? nextFocus;
  final int? rating;
  final List<String> relatedGoalIds;

  const Review({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    this.wins,
    this.challenges,
    this.lessonsLearned,
    this.nextFocus,
    this.rating,
    this.relatedGoalIds = const <String>[],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Review');
    final createdAt = reader.requireDate('createdAt');
    return Review(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      period: reader.requireEnum('period', ReviewPeriod.values),
      periodStart: reader.requireDate('periodStart'),
      periodEnd: reader.requireDate('periodEnd'),
      wins: reader.optionalString('wins'),
      challenges: reader.optionalString('challenges'),
      lessonsLearned: reader.optionalString('lessonsLearned'),
      nextFocus: reader.optionalString('nextFocus'),
      rating: reader.optionalInt('rating'),
      relatedGoalIds: reader.readStringList('relatedGoalIds'),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'period': period.name,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'wins': wins,
        'challenges': challenges,
        'lessonsLearned': lessonsLearned,
        'nextFocus': nextFocus,
        'rating': rating,
        'relatedGoalIds': relatedGoalIds,
      };
}
