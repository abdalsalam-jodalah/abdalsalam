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
    return Review(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      period: ReviewPeriod.values.byName(json['period'] as String),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      wins: json['wins'] as String?,
      challenges: json['challenges'] as String?,
      lessonsLearned: json['lessonsLearned'] as String?,
      nextFocus: json['nextFocus'] as String?,
      rating: json['rating'] as int?,
      relatedGoalIds: (json['relatedGoalIds'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
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
