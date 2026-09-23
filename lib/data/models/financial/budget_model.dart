import '../../../core/json/json_reader.dart';
import '../base_model.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly, custom }

class BudgetModel extends BaseModel {
  static const double defaultAlertThreshold = 80.0;

  final String userId;
  final String categoryId;
  final double amount;
  final String? currency; // null => inherits base currency
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double alertThreshold; // Percentage (0-100)
  @override
  final bool isActive;

  const BudgetModel({
    required super.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.currency,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.alertThreshold = defaultAlertThreshold,
    this.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'categoryId': categoryId,
        'amount': amount,
        'currency': currency,
        'period': period.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'alertThreshold': alertThreshold,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'BudgetModel');
    final createdAt = reader.requireDate('createdAt');
    return BudgetModel(
      id: reader.requireString('id'),
      userId: reader.readString('userId'),
      categoryId: reader.requireString('categoryId'),
      amount: reader.requireDouble('amount'),
      currency: reader.optionalString('currency'),
      period: reader.readEnum('period', BudgetPeriod.values, fallback: BudgetPeriod.custom),
      startDate: reader.requireDate('startDate'),
      endDate: reader.requireDate('endDate'),
      alertThreshold: reader.readDouble('alertThreshold', fallback: defaultAlertThreshold),
      isActive: reader.readBool('isActive', fallback: true),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? currency,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    double? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amount,
        currency,
        period,
        startDate,
        endDate,
        alertThreshold,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
