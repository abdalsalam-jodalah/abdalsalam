import 'package:flutter/material.dart';

import 'app_glass_style.dart';
import 'app_page_transitions_builder.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_theme_tokens.dart';
import 'appearance.dart';
import 'appearance_options.dart';

const String appFontFamily = 'Inter';
const List<String> appFontFamilyFallback = <String>['IBMPlexSansArabic'];

const double _buttonHeight = 48;
const double _compactButtonHeight = 42;
const double _buttonMinWidth = 64;
const double _navigationBarHeight = 68;
const double _progressHeight = 8;
const double _focusBorderWidth = 1.5;
const double _dividerOpacity = 0.5;
const double _inputFillOpacity = 0.55;
const double _lightGradientTint = 0.12;
const double _darkGradientTint = 0.18;

ThemeData buildAppTheme(Appearance appearance, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: appearance.accent.color, brightness: brightness);
  final spacing = AppSpacing.forDensity(appearance.density);
  final radius = AppRadius.forCornerStyle(appearance.cornerStyle);
  final glass = AppGlassStyle.forScheme(scheme, appearance.surfaceStyle);
  final tokens = AppThemeTokens(
    spacing: spacing,
    radius: radius,
    colors: AppSemanticColors.forScheme(scheme),
    glass: glass,
    backgroundGradient: _backgroundGradient(scheme),
  );
  final isCompact = appearance.density == DensityOption.compact;
  final buttonSize = Size(_buttonMinWidth, isCompact ? _compactButtonHeight : _buttonHeight);
  final buttonShape = RoundedRectangleBorder(borderRadius: radius.mediumBorder);
  final buttonPadding = EdgeInsets.symmetric(horizontal: spacing.xl, vertical: spacing.md);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: appFontFamily,
    fontFamilyFallback: appFontFamilyFallback,
    visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
  );
  final textTheme = _textTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>[tokens],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: AppPageTransitionsBuilder(),
        TargetPlatform.iOS: AppPageTransitionsBuilder(),
        TargetPlatform.macOS: AppPageTransitionsBuilder(),
        TargetPlatform.windows: AppPageTransitionsBuilder(),
        TargetPlatform.linux: AppPageTransitionsBuilder(),
        TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: glass.surfaceTint,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius.largeBorder,
        side: BorderSide(color: glass.borderColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: _inputFillOpacity),
      contentPadding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
      border: OutlineInputBorder(borderRadius: radius.mediumBorder, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius.mediumBorder, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius.mediumBorder,
        borderSide: BorderSide(color: scheme.primary, width: _focusBorderWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius.mediumBorder,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius.mediumBorder,
        borderSide: BorderSide(color: scheme.error, width: _focusBorderWidth),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        elevation: 0,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: buttonShape, textStyle: textTheme.labelLarge),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: radius.mediumBorder)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: radius.largeBorder),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: _inputFillOpacity),
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.labelMedium,
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        textStyle: textTheme.labelMedium,
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: radius.mediumBorder),
      contentPadding: EdgeInsets.symmetric(horizontal: spacing.lg),
      iconColor: scheme.primary,
      titleTextStyle: textTheme.titleSmall?.copyWith(color: scheme.onSurface),
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: _navigationBarHeight,
      elevation: 0,
      backgroundColor: glass.surfaceTint,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelSmall),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: glass.surfaceTint,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(color: scheme.primaryContainer, borderRadius: radius.pillBorder),
      labelColor: scheme.onPrimaryContainer,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: textTheme.labelLarge,
      splashBorderRadius: radius.pillBorder,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius.extraLargeBorder),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius.mediumBorder),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: radius.smallBorder),
      textStyle: textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearMinHeight: _progressHeight,
      borderRadius: radius.pillBorder,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: _dividerOpacity),
      space: spacing.lg,
      thickness: 1,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: radius.mediumBorder),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(radius.xl))),
    ),
  );
}

TextTheme _textTheme(TextTheme base) {
  const bold = FontWeight.w700;
  const semiBold = FontWeight.w600;
  const medium = FontWeight.w500;
  const tightLetterSpacing = -0.5;
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontWeight: bold, letterSpacing: tightLetterSpacing),
    displayMedium: base.displayMedium?.copyWith(fontWeight: bold, letterSpacing: tightLetterSpacing),
    displaySmall: base.displaySmall?.copyWith(fontWeight: bold, letterSpacing: tightLetterSpacing),
    headlineLarge: base.headlineLarge?.copyWith(fontWeight: bold, letterSpacing: tightLetterSpacing),
    headlineMedium: base.headlineMedium?.copyWith(fontWeight: bold, letterSpacing: tightLetterSpacing),
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: bold),
    titleLarge: base.titleLarge?.copyWith(fontWeight: bold),
    titleMedium: base.titleMedium?.copyWith(fontWeight: semiBold),
    titleSmall: base.titleSmall?.copyWith(fontWeight: semiBold),
    labelLarge: base.labelLarge?.copyWith(fontWeight: semiBold),
    labelMedium: base.labelMedium?.copyWith(fontWeight: medium),
    labelSmall: base.labelSmall?.copyWith(fontWeight: medium),
  );
}

List<Color> _backgroundGradient(ColorScheme scheme) {
  final tint = scheme.brightness == Brightness.dark ? _darkGradientTint : _lightGradientTint;
  return <Color>[
    Color.alphaBlend(scheme.primary.withValues(alpha: tint), scheme.surface),
    scheme.surface,
    Color.alphaBlend(scheme.tertiary.withValues(alpha: tint), scheme.surface),
  ];
}
