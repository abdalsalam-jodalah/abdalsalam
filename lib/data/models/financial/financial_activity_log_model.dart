import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'FinancialActivityLogModel');
    final createdAt = reader.requireDate('createdAt');
    return FinancialActivityLogModel(
      id: reader.requireString('id'),
      userId: reader.readString('userId'),
      entityType: reader.requireEnum('entityType', FinancialEntityType.values),
      action: reader.requireEnum('action', FinancialActionType.values),
      entityId: reader.requireString('entityId'),
      summary: reader.readString('summary'),
      amount: reader.optionalDouble('amount'),
      currency: reader.optionalString('currency'),
      categoryId: reader.optionalString('categoryId'),
      accountId: reader.optionalString('accountId'),
      conversionRateUsed: reader.optionalDouble('conversionRateUsed'),
      conversionRateFromTo: reader.optionalString('conversionRateFromTo'),
      conversionRateDate: reader.optionalDate('conversionRateDate'),
      metadata: reader.optionalMap('metadata'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
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
