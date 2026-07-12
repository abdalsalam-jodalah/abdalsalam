import '../base_model.dart';

enum FinancialEntityType { transaction, budget, category, account }

enum FinancialActionType { created, updated, deleted, recurringGenerated }

/// Append-only record of a financial mutation. Never updated or soft-deleted
/// once written — a log entry about a deletion is still a log entry.
class FinancialActivityLogModel extends BaseModel {
  final String userId;
  final FinancialEntityType entityType;
  final FinancialActionType action;
  final String entityId;
  final String summary;
  final double? amount;
  final String? currency;
  final String? categoryId;
  final String? accountId;
  final double? conversionRateUsed;
  final String? conversionRateFromTo;
  final DateTime? conversionRateDate;
  final Map<String, dynamic>? metadata;

  const FinancialActivityLogModel({
    required super.id,
    required this.userId,
    required this.entityType,
    required this.action,
    required this.entityId,
    required this.summary,
    this.amount,
    this.currency,
    this.categoryId,
    this.accountId,
    this.conversionRateUsed,
    this.conversionRateFromTo,
    this.conversionRateDate,
    this.metadata,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'entityType': entityType.name,
        'action': action.name,
        'entityId': entityId,
        'summary': summary,
        'amount': amount,
        'currency': currency,
        'categoryId': categoryId,
        'accountId': accountId,
        'conversionRateUsed': conversionRateUsed,
        'conversionRateFromTo': conversionRateFromTo,
        'conversionRateDate': conversionRateDate?.toIso8601String(),
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory FinancialActivityLogModel.fromJson(Map<String, dynamic> json) {
    return FinancialActivityLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      entityType: FinancialEntityType.values.byName(json['entityType'] as String),
      action: FinancialActionType.values.byName(json['action'] as String),
      entityId: json['entityId'] as String,
      summary: json['summary'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      categoryId: json['categoryId'] as String?,
      accountId: json['accountId'] as String?,
      conversionRateUsed: (json['conversionRateUsed'] as num?)?.toDouble(),
      conversionRateFromTo: json['conversionRateFromTo'] as String?,
      conversionRateDate: json['conversionRateDate'] != null
          ? DateTime.parse(json['conversionRateDate'] as String)
          : null,
      metadata: (json['metadata'] as Map<String, dynamic>?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        entityType,
        action,
        entityId,
        summary,
        amount,
        currency,
        categoryId,
        accountId,
        conversionRateUsed,
        conversionRateFromTo,
        conversionRateDate,
        metadata,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
