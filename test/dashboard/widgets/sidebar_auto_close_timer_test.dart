import 'package:abdalsalam/features/dashboard/widgets/sidebar_auto_close_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int timeoutCount;
  late SidebarAutoCloseTimer timer;

  setUp(() {
    timeoutCount = 0;
    timer = SidebarAutoCloseTimer(onTimeout: () => timeoutCount++);
  });

  tearDown(() => timer.dispose());

  group('SidebarAutoCloseTimer', () {
    testWidgets('should time out after ten seconds by default once started', (tester) async {
      timer.start();

      await tester.pump(const Duration(seconds: 9));
      expect(timeoutCount, 0);

      await tester.pump(const Duration(seconds: 1));
      expect(timeoutCount, 1);
    });

    testWidgets('should not time out before it is started', (tester) async {
      await tester.pump(const Duration(seconds: 30));

      expect(timeoutCount, 0);
    });

    testWidgets('should push the timeout back each time the sidebar is touched', (tester) async {
      timer.start();

      await tester.pump(const Duration(seconds: 8));
      timer.touch();
      await tester.pump(const Duration(seconds: 8));
      expect(timeoutCount, 0);

      await tester.pump(const Duration(seconds: 2));
      expect(timeoutCount, 1);
    });

    testWidgets('should ignore touches while stopped', (tester) async {
      timer.touch();

      await tester.pump(const Duration(seconds: 30));

      expect(timeoutCount, 0);
    });

    testWidgets('should not time out after being stopped', (tester) async {
      timer.start();
      await tester.pump(const Duration(seconds: 5));

      timer.stop();
      await tester.pump(const Duration(seconds: 30));

      expect(timeoutCount, 0);
    });

    testWidgets('should time out only once per start', (tester) async {
      timer.start();

      await tester.pump(const Duration(seconds: 60));

      expect(timeoutCount, 1);
    });

    testWidgets('should never time out when configured with no timeout', (tester) async {
      timer.configure(null);
      timer.start();

      await tester.pump(const Duration(minutes: 10));

      expect(timeoutCount, 0);
    });

    testWidgets('should use a new timeout straight away while running', (tester) async {
      timer.start();
      await tester.pump(const Duration(seconds: 2));

      timer.configure(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));

      expect(timeoutCount, 1);
    });

    testWidgets('should stop a pending timeout when switched to never', (tester) async {
      timer.start();

      timer.configure(null);
      await tester.pump(const Duration(seconds: 30));

      expect(timeoutCount, 0);
    });

    testWidgets('should restart the countdown when started again', (tester) async {
      timer.start();
      await tester.pump(const Duration(seconds: 8));

      timer.start();
      await tester.pump(const Duration(seconds: 8));

      expect(timeoutCount, 0);
      timer.stop();
    });
  });

  group('SidebarAutoCloseTimer.durationFromSetting', () {
    test('should read whole seconds', () {
      expect(SidebarAutoCloseTimer.durationFromSetting(30), const Duration(seconds: 30));
    });

    test('should read a number stored as a double', () {
      expect(SidebarAutoCloseTimer.durationFromSetting(5.0), const Duration(seconds: 5));
    });

    test('should treat zero as never', () {
      expect(SidebarAutoCloseTimer.durationFromSetting(0), isNull);
    });

    test('should treat a negative value as never', () {
      expect(SidebarAutoCloseTimer.durationFromSetting(-3), isNull);
    });

    test('should fall back to ten seconds when the setting is missing or unreadable', () {
      expect(SidebarAutoCloseTimer.durationFromSetting(null), const Duration(seconds: 10));
      expect(SidebarAutoCloseTimer.durationFromSetting('soon'), const Duration(seconds: 10));
    });
  });
}
