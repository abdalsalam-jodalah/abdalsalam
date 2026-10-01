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
  'local_grocery_store': Icons.local_grocery_store,
  'local_cafe': Icons.local_cafe,
  'fastfood': Icons.fastfood,
  'local_pizza': Icons.local_pizza,
  'bakery_dining': Icons.bakery_dining,
  'icecream': Icons.icecream,
  'local_bar': Icons.local_bar,
  'shopping_bag': Icons.shopping_bag,
  'checkroom': Icons.checkroom,
  'devices': Icons.devices,
  'local_gas_station': Icons.local_gas_station,
  'directions_bus': Icons.directions_bus,
  'train': Icons.train,
  'local_taxi': Icons.local_taxi,
  'two_wheeler': Icons.two_wheeler,
  'pedal_bike': Icons.pedal_bike,
  'local_parking': Icons.local_parking,
  'build': Icons.build,
  'flight': Icons.flight,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'wifi': Icons.wifi,
  'phone_android': Icons.phone_android,
  'receipt_long': Icons.receipt_long,
  'key': Icons.key,
  'chair': Icons.chair,
  'cleaning_services': Icons.cleaning_services,
  'local_laundry_service': Icons.local_laundry_service,
  'handyman': Icons.handyman,
  'local_hospital': Icons.local_hospital,
  'medication': Icons.medication,
  'local_pharmacy': Icons.local_pharmacy,
  'spa': Icons.spa,
  'content_cut': Icons.content_cut,
  'child_care': Icons.child_care,
  'family_restroom': Icons.family_restroom,
  'pets': Icons.pets,
  'cake': Icons.cake,
  'sports_esports': Icons.sports_esports,
  'sports_soccer': Icons.sports_soccer,
  'music_note': Icons.music_note,
  'celebration': Icons.celebration,
  'camera_alt': Icons.camera_alt,
  'beach_access': Icons.beach_access,
  'hotel': Icons.hotel,
  'luggage': Icons.luggage,
  'menu_book': Icons.menu_book,
  'computer': Icons.computer,
  'subscriptions': Icons.subscriptions,
  'attach_money': Icons.attach_money,
  'paid': Icons.paid,
  'trending_up': Icons.trending_up,
  'business_center': Icons.business_center,
  'storefront': Icons.storefront,
  'redeem': Icons.redeem,
  'currency_exchange': Icons.currency_exchange,
  'request_quote': Icons.request_quote,
  'security': Icons.security,
  'volunteer_activism': Icons.volunteer_activism,
  'mosque': Icons.mosque,
};

const _financialCategoryIconKeys = <String>[
  'shopping_cart',
  'restaurant',
  'directions_car',
  'home',
  'movie',
  'fitness_center',
  'medical_services',
  'school',
  'card_giftcard',
  'work',
  'savings',
  'category',
  'local_grocery_store',
  'local_cafe',
  'fastfood',
  'local_pizza',
  'bakery_dining',
  'icecream',
  'local_bar',
  'shopping_bag',
  'checkroom',
  'devices',
  'local_gas_station',
  'directions_bus',
  'train',
  'local_taxi',
  'two_wheeler',
  'pedal_bike',
  'local_parking',
  'build',
  'flight',
  'bolt',
  'water_drop',
  'wifi',
  'phone_android',
  'receipt_long',
  'key',
  'chair',
  'cleaning_services',
  'local_laundry_service',
  'handyman',
  'local_hospital',
  'medication',
  'local_pharmacy',
  'spa',
  'content_cut',
  'child_care',
  'family_restroom',
  'pets',
  'cake',
  'sports_esports',
  'sports_soccer',
  'music_note',
  'celebration',
  'camera_alt',
  'beach_access',
  'hotel',
  'luggage',
  'menu_book',
  'computer',
  'subscriptions',
  'attach_money',
  'paid',
  'trending_up',
  'business_center',
  'storefront',
  'redeem',
  'currency_exchange',
  'request_quote',
  'security',
  'volunteer_activism',
  'mosque',
];

final List<IconData> financialCategoryIcons = <IconData>[
  for (final key in _financialCategoryIconKeys) financialIconPalette[key]!,
];

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
