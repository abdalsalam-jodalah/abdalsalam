import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';
import 'athkar_content.dart';

class AthkarLog extends BaseModel {
  static const String _jsonSource = 'AthkarLog';
  static const int _defaultTargetCount = 1;

  final String userId;
  final String athkarContentId;
  final AthkarCategory category;
  final int countDone;
  final int targetCount;
  final DateTime completedAt;
  final String? notes;

  const AthkarLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.athkarContentId,
    required this.category,
    required this.countDone,
    required this.targetCount,
    required this.completedAt,
    this.notes,
  });

  factory AthkarLog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return AthkarLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      athkarContentId: reader.requireString('athkarContentId'),
      category: reader.readEnum('category', AthkarCategory.values, fallback: AthkarCategory.custom),
      countDone: reader.readInt('countDone'),
      targetCount: reader.readInt('targetCount', fallback: _defaultTargetCount),
      completedAt: reader.readDate('completedAt', fallback: createdAt),
      notes: reader.optionalString('notes'),
    );
  }

  AthkarLog copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    String? athkarContentId,
    AthkarCategory? category,
    int? countDone,
    int? targetCount,
    DateTime? completedAt,
    String? notes,
  }) {
    return AthkarLog(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      athkarContentId: athkarContentId ?? this.athkarContentId,
      category: category ?? this.category,
      countDone: countDone ?? this.countDone,
      targetCount: targetCount ?? this.targetCount,
      completedAt: completedAt ?? this.completedAt,
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
      'athkarContentId': athkarContentId,
      'category': category.name,
      'countDone': countDone,
      'targetCount': targetCount,
      'completedAt': completedAt.toIso8601String(),
      'notes': notes,
    };
  }
}
