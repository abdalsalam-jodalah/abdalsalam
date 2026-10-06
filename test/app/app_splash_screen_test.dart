import 'package:abdalsalam/app/bootstrap/app_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSplash({bool disableAnimations = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const MaterialApp(home: AppSplashScreen()),
      );

  testWidgets('should show the app name and all four emblem tiles once the animation completes', (tester) async {
    await tester.pumpWidget(buildSplash());
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Abdalsalam'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(4));
  });

  testWidgets('should render fully visible immediately when animations are disabled', (tester) async {
    await tester.pumpWidget(buildSplash(disableAnimations: true));

    final wordmarkOpacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Abdalsalam'), matching: find.byType(Opacity)).first,
    );
    expect(wordmarkOpacity.opacity, 1);
  });
}
