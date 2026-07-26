import '../base_model.dart';

class FoodLog extends BaseModel {
  final String userId;
  final String category;
  final String dishName;
  final String quantity;
  final String? imagePath;
  final String? components;
  final String? description;
  final DateTime loggedAt;
  final double? calories;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbGrams;

  const FoodLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.category,
    required this.dishName,
    required this.quantity,
    this.imagePath,
    this.components,
    this.description,
    required this.loggedAt,
    this.calories,
    this.proteinGrams,
    this.fatGrams,
    this.carbGrams,
  });

  FoodLog copyWith({
    String? userId,
    String? category,
    String? dishName,
    String? quantity,
    String? imagePath,
    String? components,
    String? description,
    DateTime? loggedAt,
    double? calories,
    double? proteinGrams,
    double? fatGrams,
    double? carbGrams,
    DateTime? updatedAt,
  }) =>
      FoodLog(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId ?? this.userId,
        category: category ?? this.category,
        dishName: dishName ?? this.dishName,
        quantity: quantity ?? this.quantity,
        imagePath: imagePath ?? this.imagePath,
        components: components ?? this.components,
        description: description ?? this.description,
        loggedAt: loggedAt ?? this.loggedAt,
        calories: calories ?? this.calories,
        proteinGrams: proteinGrams ?? this.proteinGrams,
        fatGrams: fatGrams ?? this.fatGrams,
        carbGrams: carbGrams ?? this.carbGrams,
      );

  factory FoodLog.fromJson(Map<String, dynamic> json) => FoodLog(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        category: json['category'] as String,
        dishName: json['dishName'] as String,
        quantity: json['quantity'] as String,
        imagePath: json['imagePath'] as String?,
        components: json['components'] as String?,
        description: json['description'] as String?,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        calories: (json['calories'] as num?)?.toDouble(),
        proteinGrams: (json['proteinGrams'] as num?)?.toDouble(),
        fatGrams: (json['fatGrams'] as num?)?.toDouble(),
        carbGrams: (json['carbGrams'] as num?)?.toDouble(),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'category': category,
        'dishName': dishName,
        'quantity': quantity,
        'imagePath': imagePath,
        'components': components,
        'description': description,
        'loggedAt': loggedAt.toIso8601String(),
        'calories': calories,
        'proteinGrams': proteinGrams,
        'fatGrams': fatGrams,
        'carbGrams': carbGrams,
      };
}
