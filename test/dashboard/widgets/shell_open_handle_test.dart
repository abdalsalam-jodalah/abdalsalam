import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/features/dashboard/widgets/shell_open_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int openCount;
  late double verticalDragTotal;

  Widget host() {
    return MaterialApp(
      theme: buildAppTheme(Appearance.defaults, Brightness.light),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 100,
              left: 0,
              child: ShellOpenHandle(
                onOpen: () => openCount++,
                onVerticalDrag: (delta) => verticalDragTotal += delta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  setUp(() {
    openCount = 0;
    verticalDragTotal = 0;
  });

  testWidgets('should open on a single tap without waiting for a possible double tap', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.byType(ShellOpenHandle));
    await tester.pump();

    expect(openCount, 1);
  });

  testWidgets('should open when the handle is swiped to the right', (tester) async {
    await tester.pumpWidget(host());

    await tester.drag(find.byType(ShellOpenHandle), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(openCount, 1);
  });

  testWidgets('should open on a short fast flick to the right', (tester) async {
    await tester.pumpWidget(host());
    final gesture = await tester.startGesture(tester.getCenter(find.byType(ShellOpenHandle)));

    for (var step = 1; step <= 5; step++) {
      await gesture.moveBy(const Offset(7, 0), timeStamp: Duration(milliseconds: step * 8));
    }
    await gesture.up(timeStamp: const Duration(milliseconds: 48));
    await tester.pumpAndSettle();

    expect(openCount, 1);
  });

  testWidgets('should not open when swiped to the left', (tester) async {
    await tester.pumpWidget(host());

    await tester.drag(find.byType(ShellOpenHandle), const Offset(-60, 0));
    await tester.pumpAndSettle();

    expect(openCount, 0);
  });

  testWidgets('should only move up and down, without opening, when dragged vertically', (tester) async {
    await tester.pumpWidget(host());

    await tester.drag(find.byType(ShellOpenHandle), const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(openCount, 0);
    expect(verticalDragTotal, greaterThan(0));
  });

  testWidgets('should be comfortable to hit, wider than the visible chevron', (tester) async {
    await tester.pumpWidget(host());

    final size = tester.getSize(find.byType(ShellOpenHandle));

    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(64));
  });

  testWidgets('should open when tapping the transparent area beside the chevron', (tester) async {
    await tester.pumpWidget(host());
    final topLeft = tester.getTopLeft(find.byType(ShellOpenHandle));

    await tester.tapAt(topLeft + const Offset(40, 10));
    await tester.pump();

    expect(openCount, 1);
  });
}
