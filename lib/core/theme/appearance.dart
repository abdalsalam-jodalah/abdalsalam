import 'package:flutter/material.dart';

import '../json/json_reader.dart';
import 'accent_option.dart';
import 'accent_palette.dart';
import 'appearance_options.dart';

class Appearance {
  static const String accentKey = 'appearanceAccent';
  static const String themeModeKey = 'themeMode';
  static const String cornerStyleKey = 'appearanceCorners';
  static const String textSizeKey = 'appearanceTextSize';
  static const String densityKey = 'appearanceDensity';
  static const String surfaceStyleKey = 'appearanceSurface';

  static const Map<TextSizeOption, double> _textScales = <TextSizeOption, double>{
    TextSizeOption.small: 0.9,
    TextSizeOption.standard: 1,
    TextSizeOption.large: 1.15,
  };

  final String accentId;
  final ThemeMode themeMode;
  final CornerStyle cornerStyle;
  final TextSizeOption textSize;
  final DensityOption density;
  final SurfaceStyle surfaceStyle;

  const Appearance({
    this.accentId = AccentPalette.defaultId,
    this.themeMode = ThemeMode.system,
    this.cornerStyle = CornerStyle.round,
    this.textSize = TextSizeOption.standard,
    this.density = DensityOption.comfortable,
    this.surfaceStyle = SurfaceStyle.glass,
  });

  static const Appearance defaults = Appearance();

  factory Appearance.fromSettings(Map<String, dynamic> settings) {
    final reader = JsonReader(settings, source: 'Appearance');
    return Appearance(
      accentId: AccentPalette.byId(reader.optionalString(accentKey)).id,
      themeMode: reader.readEnum(themeModeKey, ThemeMode.values, fallback: defaults.themeMode),
      cornerStyle: reader.readEnum(cornerStyleKey, CornerStyle.values, fallback: defaults.cornerStyle),
      textSize: reader.readEnum(textSizeKey, TextSizeOption.values, fallback: defaults.textSize),
      density: reader.readEnum(densityKey, DensityOption.values, fallback: defaults.density),
      surfaceStyle: reader.readEnum(surfaceStyleKey, SurfaceStyle.values, fallback: defaults.surfaceStyle),
    );
  }

  Map<String, dynamic> toSettings() => <String, dynamic>{
        accentKey: accentId,
        themeModeKey: themeMode.name,
        cornerStyleKey: cornerStyle.name,
        textSizeKey: textSize.name,
        densityKey: density.name,
        surfaceStyleKey: surfaceStyle.name,
      };

  AccentOption get accent => AccentPalette.byId(accentId);

  double get textScale => _textScales[textSize]!;

  bool get isGlass => surfaceStyle == SurfaceStyle.glass;

  Appearance copyWith({
    String? accentId,
    ThemeMode? themeMode,
    CornerStyle? cornerStyle,
    TextSizeOption? textSize,
    DensityOption? density,
    SurfaceStyle? surfaceStyle,
  }) {
    return Appearance(
      accentId: accentId ?? this.accentId,
      themeMode: themeMode ?? this.themeMode,
      cornerStyle: cornerStyle ?? this.cornerStyle,
      textSize: textSize ?? this.textSize,
      density: density ?? this.density,
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Appearance &&
      other.accentId == accentId &&
      other.themeMode == themeMode &&
      other.cornerStyle == cornerStyle &&
      other.textSize == textSize &&
      other.density == density &&
      other.surfaceStyle == surfaceStyle;

  @override
  int get hashCode => Object.hash(accentId, themeMode, cornerStyle, textSize, density, surfaceStyle);
}
