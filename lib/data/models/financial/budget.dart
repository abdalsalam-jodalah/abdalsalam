import '../../models/base_model.dart';

enum BudgetPeriod { weekly, monthly, yearly }

class Budget extends BaseModel {
  final String userId;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double alertThreshold;

  const Budget({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.alertThreshold,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.values.byName(json['period'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      alertThreshold: (json['alertThreshold'] as num).toDouble(),
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
      'categoryId': categoryId,
      'amount': amount,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'alertThreshold': alertThreshold,
    };
  }
}
