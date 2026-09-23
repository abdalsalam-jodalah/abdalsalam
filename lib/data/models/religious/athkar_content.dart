import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

enum AthkarCategory {
  morning,
  evening,
  afterPrayer,
  sleep,
  wakingUp,
  custom,
}

class AthkarContent extends BaseModel {
  static const String _jsonSource = 'AthkarContent';
  static const int _defaultTargetCount = 1;

  final AthkarCategory category;
  final String arabicText;
  final String? transliteration;
  final String? translation;
  final int targetCount;
  final String? reference;
  final bool isBuiltIn;
  final bool isCustom;
  final int sortOrder;

  const AthkarContent({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.category,
    required this.arabicText,
    this.transliteration,
    this.translation,
    required this.targetCount,
    this.reference,
    required this.isBuiltIn,
    required this.isCustom,
    required this.sortOrder,
  });

  factory AthkarContent.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: _jsonSource);
    final createdAt = reader.requireDate('createdAt');
    return AthkarContent(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      category: reader.readEnum('category', AthkarCategory.values, fallback: AthkarCategory.custom),
      arabicText: reader.requireString('arabicText'),
      transliteration: reader.optionalString('transliteration'),
      translation: reader.optionalString('translation'),
      targetCount: reader.readInt('targetCount', fallback: _defaultTargetCount),
      reference: reader.optionalString('reference'),
      isBuiltIn: reader.readBool('isBuiltIn'),
      isCustom: reader.readBool('isCustom'),
      sortOrder: reader.readInt('sortOrder'),
    );
  }

  AthkarContent copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    AthkarCategory? category,
    String? arabicText,
    String? transliteration,
    String? translation,
    int? targetCount,
    String? reference,
    bool? isBuiltIn,
    bool? isCustom,
    int? sortOrder,
  }) {
    return AthkarContent(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      category: category ?? this.category,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      targetCount: targetCount ?? this.targetCount,
      reference: reference ?? this.reference,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isCustom: isCustom ?? this.isCustom,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'category': category.name,
      'arabicText': arabicText,
      'transliteration': transliteration,
      'translation': translation,
      'targetCount': targetCount,
      'reference': reference,
      'isBuiltIn': isBuiltIn,
      'isCustom': isCustom,
      'sortOrder': sortOrder,
    };
  }
}
