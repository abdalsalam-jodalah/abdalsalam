import 'package:flutter/painting.dart';

class HexColor {
  static final RegExp _pattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
  static const int _opaqueAlpha = 0xFF000000;
  static const int _rgbMask = 0x00FFFFFF;
  static const int _hexRadix = 16;
  static const int _hexDigits = 6;

  const HexColor._();

  static bool isValid(String? value) => value != null && _pattern.hasMatch(value);

  static Color? tryParse(String? value) {
    if (!isValid(value)) return null;
    return Color(_opaqueAlpha | int.parse(value!.substring(1), radix: _hexRadix));
  }

  static String format(Color color) {
    final rgb = color.toARGB32() & _rgbMask;
    return '#${rgb.toRadixString(_hexRadix).padLeft(_hexDigits, '0').toUpperCase()}';
  }
}
