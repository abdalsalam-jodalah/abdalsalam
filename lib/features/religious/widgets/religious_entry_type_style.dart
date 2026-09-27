import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/religious_entry.dart';

class ReligiousEntryTypeStyle {
  const ReligiousEntryTypeStyle._();

  static IconData icon(ReligiousEntryType type) {
    switch (type) {
      case ReligiousEntryType.prayer:
        return Icons.mosque_outlined;
      case ReligiousEntryType.quranReading:
        return Icons.menu_book_outlined;
      case ReligiousEntryType.badEvent:
        return Icons.warning_amber_outlined;
      case ReligiousEntryType.athkar:
        return Icons.favorite_outline;
      case ReligiousEntryType.nightPrayer:
        return Icons.nights_stay_outlined;
    }
  }

  static Color color(BuildContext context, ReligiousEntryType type) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppThemeTokens.of(context);
    switch (type) {
      case ReligiousEntryType.prayer:
      case ReligiousEntryType.nightPrayer:
        return scheme.primary;
      case ReligiousEntryType.quranReading:
        return scheme.secondary;
      case ReligiousEntryType.athkar:
        return scheme.tertiary;
      case ReligiousEntryType.badEvent:
        return tokens.colors.danger;
    }
  }
}
