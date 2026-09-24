import 'dart:io';

import 'package:abdalsalam/core/theme/app_background.dart';
import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool _areFontsLoaded = false;

Future<void> _loadFamily(String family, List<String> assetPaths) async {
  final loader = FontLoader(family);
  for (final path in assetPaths) {
    loader.addFont(rootBundle.load(path));
  }
  await loader.load();
}

Future<void> loadGoldenFonts() async {
  if (_areFontsLoaded) {
    return;
  }
  const weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
  await _loadFamily('Inter', [for (final weight in weights) 'assets/fonts/inter/Inter-$weight.ttf']);
  await _loadFamily(
    'IBMPlexSansArabic',
    [for (final weight in weights) 'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-$weight.ttf'],
  );
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final iconFont = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (iconFont.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(iconFont.readAsBytesSync())));
      await loader.load();
    }
  }
  _areFontsLoaded = true;
}

Widget goldenHost({
  required Widget child,
  Appearance appearance = Appearance.defaults,
  Brightness brightness = Brightness.light,
}) {
  final theme = buildAppTheme(appearance, brightness);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: AppBackground(child: child),
  );
}

Future<void> setGoldenSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
