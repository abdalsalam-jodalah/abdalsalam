import 'package:abdalsalam/data/models/financial/financial_icon_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('financialIconPalette', () {
    test('should give every palette key an icon that maps back to the same key', () {
      for (final entry in financialIconPalette.entries) {
        expect(financialIconKeyFor(entry.value), entry.key, reason: '${entry.key} collides with another icon');
      }
    });

    test('should keep every selectable category icon storable instead of falling back to the default', () {
      for (final icon in financialCategoryIcons) {
        expect(financialIconForKey(financialIconKeyFor(icon)), icon, reason: 'icon ${icon.codePoint} is not storable');
      }
    });

    test('should offer each category icon only once', () {
      final codePoints = financialCategoryIcons.map((icon) => icon.codePoint).toList();

      expect(codePoints.toSet().length, codePoints.length);
    });

    test('should offer more than the original dozen category icons and keep the original default first', () {
      expect(financialCategoryIcons.length, greaterThan(12));
      expect(financialCategoryIcons.first, Icons.shopping_cart);
    });

    test('should still resolve an unknown key to the default icon', () {
      expect(financialIconForKey('does_not_exist'), Icons.category);
    });
  });
}
