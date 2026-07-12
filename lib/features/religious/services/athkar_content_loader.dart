import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../data/models/religious/athkar_content.dart';

class AthkarContentLoader {
  static const _assetPath = 'assets/data/athkar_content.json';

  Future<List<AthkarContent>> loadBundled() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final categories = decoded['categories'] as List<dynamic>;

    final result = <AthkarContent>[];
    final now = DateTime.now();

    for (final categoryJson in categories) {
      final category = categoryJson as Map<String, dynamic>;
      final categoryId = category['id'] as String;
      final entries = category['entries'] as List<dynamic>;

      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index] as Map<String, dynamic>;
        result.add(
          AthkarContent(
            id: 'builtin-$categoryId-$index',
            createdAt: now,
            updatedAt: now,
            category: AthkarCategory.values.byName(categoryId),
            arabicText: entry['arabicText'] as String,
            transliteration: entry['transliteration'] as String?,
            translation: entry['translation'] as String?,
            targetCount: (entry['targetCount'] as num).toInt(),
            reference: entry['reference'] as String?,
            isBuiltIn: true,
            isCustom: false,
            sortOrder: (entry['sortOrder'] as num?)?.toInt() ?? index,
          ),
        );
      }
    }

    return result;
  }

  Future<Map<String, ({String start, String end})>> loadTimeWindows() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final categories = decoded['categories'] as List<dynamic>;

    final windows = <String, ({String start, String end})>{};
    for (final categoryJson in categories) {
      final category = categoryJson as Map<String, dynamic>;
      final start = category['timeWindowStart'] as String?;
      final end = category['timeWindowEnd'] as String?;
      if (start != null && end != null) {
        windows[category['id'] as String] = (start: start, end: end);
      }
    }
    return windows;
  }
}
