import '../../models/base_model.dart';

/// Deprecated: superseded by [QuranReading] (surah/ayah range, pagesRead, place).
/// Kept only so previously-persisted rows remain readable; use the
/// "Import legacy Quran progress" action on QuranReadingScreen to migrate.
@Deprecated('Use QuranReading instead')
class QuranProgress extends BaseModel {
  final String userId;
  final int pagesRead;
  final int minutesSpent;
  final DateTime loggedAt;

  const QuranProgress({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.pagesRead,
    required this.minutesSpent,
    required this.loggedAt,
  });

  factory QuranProgress.fromJson(Map<String, dynamic> json) {
    return QuranProgress(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      pagesRead: json['pagesRead'] as int,
      minutesSpent: json['minutesSpent'] as int,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }

  QuranProgress copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    int? pagesRead,
    int? minutesSpent,
    DateTime? loggedAt,
  }) {
    return QuranProgress(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      pagesRead: pagesRead ?? this.pagesRead,
      minutesSpent: minutesSpent ?? this.minutesSpent,
      loggedAt: loggedAt ?? this.loggedAt,
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
      'pagesRead': pagesRead,
      'minutesSpent': minutesSpent,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }
}
