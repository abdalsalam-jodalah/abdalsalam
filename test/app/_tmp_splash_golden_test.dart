import 'dart:io';

import 'package:abdalsalam/app/bootstrap/app_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('golden', (tester) async {
    final loader = FontLoader('Inter')
      ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/inter/Inter-Regular.ttf').readAsBytesSync())))
      ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/inter/Inter-SemiBold.ttf').readAsBytesSync())));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(const MaterialApp(home: AppSplashScreen()));
    await tester.runAsync(() async {
      for (final name in ['top_left', 'top_right', 'bottom_left', 'bottom_right']) {
        await precacheImage(AssetImage('assets/branding/emblem_$name.png'), tester.element(find.byType(AppSplashScreen)));
      }
    });
    for (final ms in [250, 1700, 2000]) {
      await tester.pump(Duration(milliseconds: ms == 250 ? 250 : ms == 1700 ? 1450 : 300));
      await expectLater(find.byType(AppSplashScreen), matchesGoldenFile('_tmp_splash_$ms.png'));
    }
  });
}
