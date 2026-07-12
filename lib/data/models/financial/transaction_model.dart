import '../base_model.dart';
import 'recurrence_pattern.dart';

enum TransactionType { income, expense }

class TransactionModel extends BaseModel {
  final String userId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String categoryId;
  final String? accountId;
  final DateTime date;
  final String description;
  final List<String> tags;
  final String? paymentMethod;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime? recurrenceNextDueDate;

  const TransactionModel({
    required super.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.categoryId,
    this.accountId,
    required this.date,
    required this.description,
    this.tags = const [],
    this.paymentMethod,
    this.isRecurring = false,
    this.recurringPattern,
    this.recurrenceNextDueDate,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// Typed view of [recurringPattern]; null if unset or unrecognized.
  RecurrencePattern? get recurrence => recurringPattern == null
      ? null
      : RecurrencePattern.values.asNameMap()[recurringPattern];

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'amount': amount,
        'currency': currency,
        'categoryId': categoryId,
        'accountId': accountId,
        'date': date.toIso8601String(),
        'description': description,
        'tags': tags,
        'paymentMethod': paymentMethod,
        'isRecurring': isRecurring,
        'recurringPattern': recurringPattern,
        'recurrenceNextDueDate': recurrenceNextDueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String?,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      paymentMethod: json['paymentMethod'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringPattern: json['recurringPattern'] as String?,
      recurrenceNextDueDate: json['recurrenceNextDueDate'] != null
          ? DateTime.parse(json['recurrenceNextDueDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? currency,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? description,
    List<String>? tags,
    String? paymentMethod,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? recurrenceNextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurrenceNextDueDate: recurrenceNextDueDate ?? this.recurrenceNextDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        amount,
        currency,
        categoryId,
        accountId,
        date,
        description,
        tags,
        paymentMethod,
        isRecurring,
        recurringPattern,
        recurrenceNextDueDate,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
