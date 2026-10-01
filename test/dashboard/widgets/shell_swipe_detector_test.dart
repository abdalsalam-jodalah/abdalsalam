import 'package:abdalsalam/features/dashboard/widgets/shell_swipe_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int openCount;
  late int closeCount;
  late int tapCount;

  Widget host() {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: () => tapCount++, child: const ColoredBox(color: Colors.white)),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 88,
              child: ShellSwipeDetector(
                key: const Key('swipe-zone'),
                onSwipeOpen: () => openCount++,
                onSwipeClose: () => closeCount++,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> swipe(WidgetTester tester, double dx, {int milliseconds = 300}) async {
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('swipe-zone'))));
    const steps = 6;
    for (var step = 1; step <= steps; step++) {
      await gesture.moveBy(
        Offset(dx / steps, 0),
        timeStamp: Duration(milliseconds: milliseconds * step ~/ steps),
      );
    }
    await gesture.up(timeStamp: Duration(milliseconds: milliseconds));
    await tester.pumpAndSettle();
  }

  setUp(() {
    openCount = 0;
    closeCount = 0;
    tapCount = 0;
  });

  testWidgets('should close on a modest slow swipe to the left', (tester) async {
    await tester.pumpWidget(host());

    await swipe(tester, -45);

    expect(closeCount, 1);
    expect(openCount, 0);
  });

  testWidgets('should close on a short fast flick to the left', (tester) async {
    await tester.pumpWidget(host());

    await swipe(tester, -35, milliseconds: 40);

    expect(closeCount, 1);
  });

  testWidgets('should open on a long swipe to the right', (tester) async {
    await tester.pumpWidget(host());

    await swipe(tester, 90);

    expect(openCount, 1);
    expect(closeCount, 0);
  });

  testWidgets('should not open on a modest slow swipe to the right that would close in the other direction', (tester) async {
    await tester.pumpWidget(host());

    await swipe(tester, 45);

    expect(openCount, 0);
  });

  testWidgets('should ignore a tiny movement', (tester) async {
    await tester.pumpWidget(host());

    await swipe(tester, -10);

    expect(closeCount, 0);
    expect(openCount, 0);
  });

  testWidgets('should still let taps reach the widget underneath', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.byKey(const Key('swipe-zone')));
    await tester.pump();

    expect(tapCount, 1);
  });
}
