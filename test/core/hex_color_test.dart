import 'package:abdalsalam/core/formatting/hex_color.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexColor', () {
    test('should accept only #RRGGBB values', () {
      expect(HexColor.isValid('#F5A623'), isTrue);
      expect(HexColor.isValid('#f5a623'), isTrue);
      expect(HexColor.isValid('F5A623'), isFalse);
      expect(HexColor.isValid('#F5A62'), isFalse);
      expect(HexColor.isValid('#GGGGGG'), isFalse);
      expect(HexColor.isValid('#F5A62380'), isFalse);
      expect(HexColor.isValid(null), isFalse);
    });

    test('should parse a hex string into an opaque color', () {
      expect(HexColor.tryParse('#F5A623'), const Color(0xFFF5A623));
      expect(HexColor.tryParse('nope'), isNull);
    });

    test('should format a color as upper case hex and round trip', () {
      expect(HexColor.format(const Color(0xFF0E8A16)), '#0E8A16');
      expect(HexColor.format(const Color(0xFF000001)), '#000001');
      expect(HexColor.tryParse(HexColor.format(const Color(0xFFD73A4A))), const Color(0xFFD73A4A));
    });
  });
}
