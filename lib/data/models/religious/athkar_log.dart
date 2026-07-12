import '../../models/base_model.dart';
import 'athkar_content.dart';

class AthkarLog extends BaseModel {
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
    return AthkarLog(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      athkarContentId: json['athkarContentId'] as String,
      category: AthkarCategory.values.byName(json['category'] as String),
      countDone: (json['countDone'] as num).toInt(),
      targetCount: (json['targetCount'] as num).toInt(),
      completedAt: DateTime.parse(json['completedAt'] as String),
      notes: json['notes'] as String?,
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
