import '../../models/base_model.dart';

enum TransactionType { income, expense }

class Transaction extends BaseModel {
  final String userId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String category;
  final String? subcategory;
  final DateTime date;
  final String description;
  final List<String> tags;
  final String paymentMethod;

  const Transaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.category,
    required this.subcategory,
    required this.date,
    required this.description,
    required this.tags,
    required this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      paymentMethod: json['paymentMethod'] as String,
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
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'category': category,
      'subcategory': subcategory,
      'date': date.toIso8601String(),
      'description': description,
      'tags': tags,
      'paymentMethod': paymentMethod,
    };
  }
}
