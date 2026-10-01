import 'package:abdalsalam/core/theme/app_motion.dart';
import 'package:abdalsalam/features/dashboard/widgets/shell_sidebar_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const panelKey = Key('panel');
  const panelWidth = 88.0;

  Widget host({required double visibleWidth, bool slidesFromEdge = true, bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Row(
            children: [
              ShellSidebarReveal(
                visibleWidth: visibleWidth,
                panelWidth: panelWidth,
                slidesFromEdge: slidesFromEdge,
                child: const SizedBox(key: panelKey, width: panelWidth, height: 200, child: Text('Pages')),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  double visibleWidthOfPanel(WidgetTester tester) => tester.getSize(find.byType(ClipRect).first).width;

  testWidgets('should shrink gradually when closing instead of disappearing at once', (tester) async {
    await tester.pumpWidget(host(visibleWidth: panelWidth));
    await tester.pumpWidget(host(visibleWidth: 0));

    await tester.pump(AppMotion.normal ~/ 2);

    expect(find.byKey(panelKey), findsOneWidget);
    expect(visibleWidthOfPanel(tester), inExclusiveRange(0, panelWidth));
  });

  testWidgets('should be gone once the closing animation has finished', (tester) async {
    await tester.pumpWidget(host(visibleWidth: panelWidth));
    await tester.pumpWidget(host(visibleWidth: 0));

    await tester.pumpAndSettle();

    expect(find.byKey(panelKey), findsNothing);
  });

  testWidgets('should grow gradually when opening', (tester) async {
    await tester.pumpWidget(host(visibleWidth: 0));
    await tester.pumpWidget(host(visibleWidth: panelWidth));

    await tester.pump(AppMotion.normal ~/ 2);

    expect(find.byKey(panelKey), findsOneWidget);
    expect(visibleWidthOfPanel(tester), inExclusiveRange(0, panelWidth));

    await tester.pumpAndSettle();
    expect(visibleWidthOfPanel(tester), panelWidth);
  });

  testWidgets('should slide the panel out to the left while closing', (tester) async {
    await tester.pumpWidget(host(visibleWidth: panelWidth));
    await tester.pumpWidget(host(visibleWidth: 0));

    await tester.pump(AppMotion.normal ~/ 2);

    expect(tester.getTopRight(find.byKey(panelKey)).dx, closeTo(visibleWidthOfPanel(tester), 0.5));
  });

  testWidgets('should keep the panel pinned to the left while growing between icons and expanded', (tester) async {
    await tester.pumpWidget(host(visibleWidth: panelWidth, slidesFromEdge: false));
    await tester.pumpWidget(host(visibleWidth: 40, slidesFromEdge: false));

    await tester.pump(AppMotion.normal ~/ 2);

    expect(tester.getTopLeft(find.byKey(panelKey)).dx, 0);
  });

  testWidgets('should not overflow at any point of the animation', (tester) async {
    await tester.pumpWidget(host(visibleWidth: panelWidth));
    await tester.pumpWidget(host(visibleWidth: 0));

    for (var step = 0; step < 6; step++) {
      await tester.pump(AppMotion.normal ~/ 6);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('should jump straight to the end when animations are disabled', (tester) async {
    await tester.pumpWidget(host(visibleWidth: panelWidth, disableAnimations: true));
    await tester.pumpWidget(host(visibleWidth: 0, disableAnimations: true));

    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byKey(panelKey), findsNothing);
  });
}
