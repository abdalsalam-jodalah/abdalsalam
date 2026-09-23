import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

/// Deprecated: superseded by [QuranReading] (surah/ayah range, pagesRead, place).
/// Kept only so previously-persisted rows remain readable; use the
/// "Import legacy Quran progress" action on QuranReadingScreen to migrate.
@Deprecated('Use QuranReading instead')
class QuranProgress extends BaseModel {
  static const String _jsonSource = 'QuranProgress';

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
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return QuranProgress(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      pagesRead: reader.readInt('pagesRead'),
      minutesSpent: reader.readInt('minutesSpent'),
      loggedAt: reader.readDate('loggedAt', fallback: createdAt),
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
