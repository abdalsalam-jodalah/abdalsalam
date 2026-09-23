import 'package:flutter/material.dart';

const financialIconPalette = <String, IconData>{
  'account_balance_wallet': Icons.account_balance_wallet,
  'account_balance': Icons.account_balance,
  'credit_card': Icons.credit_card,
  'savings': Icons.savings,
  'payments': Icons.payments,
  'shopping_cart': Icons.shopping_cart,
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'home': Icons.home,
  'movie': Icons.movie,
  'fitness_center': Icons.fitness_center,
  'medical_services': Icons.medical_services,
  'school': Icons.school,
  'card_giftcard': Icons.card_giftcard,
  'work': Icons.work,
  'category': Icons.category,
  'help': Icons.help,
};

const _defaultFinancialIconKey = 'category';

const int financialDefaultColorValue = 0xFF9E9E9E;

String financialIconKeyFor(IconData icon) {
  for (final entry in financialIconPalette.entries) {
    if (entry.value.codePoint == icon.codePoint && entry.value.fontFamily == icon.fontFamily) {
      return entry.key;
    }
  }
  return _defaultFinancialIconKey;
}

IconData financialIconForKey(String? key) {
  return financialIconPalette[key] ?? financialIconPalette[_defaultFinancialIconKey]!;
}

/// Resolves an icon for records persisted before icons were stored by
/// palette key, by matching the old raw codePoint/fontFamily against the
/// known palette entries (never constructs a new IconData, so this stays
/// tree-shake-safe for web release builds).
IconData financialIconForLegacyCodePoint(int? codePoint, String? fontFamily) {
  if (codePoint == null) {
    return financialIconPalette[_defaultFinancialIconKey]!;
  }
  for (final icon in financialIconPalette.values) {
    if (icon.codePoint == codePoint && icon.fontFamily == fontFamily) {
      return icon;
    }
  }
  return financialIconPalette[_defaultFinancialIconKey]!;
}
