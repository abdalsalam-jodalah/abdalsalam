import 'package:flutter/painting.dart';

import 'accent_option.dart';

class AccentPalette {
  const AccentPalette._();

  static const String defaultId = 'lagoon';

  static const List<AccentOption> options = <AccentOption>[
    AccentOption(id: 'lagoon', label: 'Lagoon', color: Color(0xFF00B8D4)),
    AccentOption(id: 'ocean', label: 'Ocean', color: Color(0xFF3B82F6)),
    AccentOption(id: 'indigo', label: 'Indigo', color: Color(0xFF6366F1)),
    AccentOption(id: 'violet', label: 'Violet', color: Color(0xFF8B5CF6)),
    AccentOption(id: 'rose', label: 'Rose', color: Color(0xFFEC4899)),
    AccentOption(id: 'coral', label: 'Coral', color: Color(0xFFF97316)),
    AccentOption(id: 'amber', label: 'Amber', color: Color(0xFFF59E0B)),
    AccentOption(id: 'emerald', label: 'Emerald', color: Color(0xFF10B981)),
    AccentOption(id: 'teal', label: 'Teal', color: Color(0xFF14B8A6)),
    AccentOption(id: 'slate', label: 'Slate', color: Color(0xFF64748B)),
  ];

  static AccentOption byId(String? id) {
    for (final option in options) {
      if (option.id == id) {
        return option;
      }
    }
    return options.first;
  }
}
