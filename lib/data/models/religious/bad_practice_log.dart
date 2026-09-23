import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class BadPracticeLog extends BaseModel {
  static const String _jsonSource = 'BadPracticeLog';

  final String userId;
  final String title;
  final DateTime occurredAt;
  final String? feelingBefore;
  final String? feelingAfter;
  final String? consequences;
  final String? notes;

  const BadPracticeLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    required this.occurredAt,
    this.feelingBefore,
    this.feelingAfter,
    this.consequences,
    this.notes,
  });

  factory BadPracticeLog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return BadPracticeLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      occurredAt: reader.readDate('occurredAt', fallback: createdAt),
      feelingBefore: reader.optionalString('feelingBefore'),
      feelingAfter: reader.optionalString('feelingAfter'),
      consequences: reader.optionalString('consequences'),
      notes: reader.optionalString('notes'),
    );
  }

  BadPracticeLog copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    String? title,
    DateTime? occurredAt,
    String? feelingBefore,
    String? feelingAfter,
    String? consequences,
    String? notes,
  }) {
    return BadPracticeLog(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      occurredAt: occurredAt ?? this.occurredAt,
      feelingBefore: feelingBefore ?? this.feelingBefore,
      feelingAfter: feelingAfter ?? this.feelingAfter,
      consequences: consequences ?? this.consequences,
      notes: notes ?? this.notes,
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
      'title': title,
      'occurredAt': occurredAt.toIso8601String(),
      'feelingBefore': feelingBefore,
      'feelingAfter': feelingAfter,
      'consequences': consequences,
      'notes': notes,
    };
  }
}
