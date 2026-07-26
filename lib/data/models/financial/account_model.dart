import 'package:flutter/material.dart';
import '../base_model.dart';
import 'financial_icon_palette.dart';

enum AccountType { cash, bank, card, savings }

class AccountModel extends BaseModel {
  final String userId;
  final String name;
  final AccountType type;
  final String currency;
  final double initialBalance;
  final String iconKey;
  final int colorValue;
  @override
  final bool isActive;

  const AccountModel({
    required super.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.iconKey,
    required this.colorValue,
    this.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  IconData get icon => financialIconForKey(iconKey);
  Color get color => Color(colorValue);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'type': type.name,
        'currency': currency,
        'initialBalance': initialBalance,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: AccountType.values.byName(json['type'] as String),
      currency: json['currency'] as String,
      initialBalance: (json['initialBalance'] as num).toDouble(),
      iconKey: json['iconKey'] as String? ??
          financialIconKeyFor(
            financialIconForLegacyCodePoint(
              json['iconCodePoint'] as int?,
              json['iconFontFamily'] as String?,
            ),
          ),
      colorValue: json['colorValue'] as int,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    String? currency,
    double? initialBalance,
    String? iconKey,
    int? colorValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
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
        name,
        type,
        currency,
        initialBalance,
        iconKey,
        colorValue,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
