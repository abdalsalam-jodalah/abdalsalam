import 'package:flutter/material.dart';
import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'AccountModel');
    final createdAt = reader.requireDate('createdAt');
    return AccountModel(
      id: reader.requireString('id'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      type: reader.readEnum('type', AccountType.values, fallback: AccountType.cash),
      currency: reader.requireString('currency'),
      initialBalance: reader.requireDouble('initialBalance'),
      iconKey: reader.optionalString('iconKey') ??
          financialIconKeyFor(
            financialIconForLegacyCodePoint(
              reader.optionalInt('iconCodePoint'),
              reader.optionalString('iconFontFamily'),
            ),
          ),
      colorValue: reader.readInt('colorValue', fallback: financialDefaultColorValue),
      isActive: reader.readBool('isActive', fallback: true),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
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
