import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/features/dashboard/screens/app_shell_screen.dart';
import 'package:abdalsalam/features/dashboard/widgets/shell_sidebar.dart';
import 'package:abdalsalam/features/dashboard/widgets/shell_sidebar_reveal.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Future<void> pumpShell(WidgetTester tester, {Size size = const Size(420, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(Appearance.defaults, Brightness.light),
          home: const AppShellScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  double sidebarVisibleWidth(WidgetTester tester) {
    final finder = find.descendant(of: find.byType(ShellSidebarReveal), matching: find.byType(ClipRect));
    return finder.evaluate().isEmpty ? 0 : tester.getSize(finder.first).width;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await StorageGateway.instance.initialize(databaseName: 'test_app_shell_screen_test.db');
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
  });

  testWidgets('should start with the icon rail visible', (tester) async {
    await pumpShell(tester);

    expect(find.byType(ShellSidebar), findsOneWidget);
    expect(sidebarVisibleWidth(tester), 88);
  });

  Future<void> finishAnimations(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> disposeShell(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  Future<void> expandSidebar(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await finishAnimations(tester);
  }

  testWidgets('should animate the icon rail closed instead of removing it at once', (tester) async {
    await pumpShell(tester);

    await tester.drag(find.byType(ShellSidebar), const Offset(-60, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sidebarVisibleWidth(tester), inExclusiveRange(0, 88));
    await finishAnimations(tester);
    expect(sidebarVisibleWidth(tester), 0);
    await disposeShell(tester);
  });

  testWidgets('should animate the full sidebar closed instead of removing it at once', (tester) async {
    await pumpShell(tester);
    await expandSidebar(tester);
    expect(sidebarVisibleWidth(tester), 264);

    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sidebarVisibleWidth(tester), inExclusiveRange(0, 264));
    await finishAnimations(tester);
    expect(sidebarVisibleWidth(tester), 0);
    await disposeShell(tester);
  });

  testWidgets('should animate the full sidebar down to icons when collapsed', (tester) async {
    await pumpShell(tester);
    await expandSidebar(tester);

    await tester.tap(find.byIcon(Icons.menu_open_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sidebarVisibleWidth(tester), inExclusiveRange(88, 264));
    await finishAnimations(tester);
    expect(sidebarVisibleWidth(tester), 88);
    await disposeShell(tester);
  });

  testWidgets('should animate closed when it closes itself after being left untouched', (tester) async {
    await pumpShell(tester);

    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 100));

    expect(sidebarVisibleWidth(tester), inExclusiveRange(0, 88));
    await finishAnimations(tester);
    expect(sidebarVisibleWidth(tester), 0);
    await disposeShell(tester);
  });

  testWidgets('should animate open again from closed', (tester) async {
    await pumpShell(tester);
    await tester.pump(const Duration(seconds: 10));
    await finishAnimations(tester);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sidebarVisibleWidth(tester), inExclusiveRange(0, 88));
    await finishAnimations(tester);
    expect(sidebarVisibleWidth(tester), 88);
    await disposeShell(tester);
  });

  testWidgets('should go through every open, expand, collapse, and close transition without layout errors', (tester) async {
    await pumpShell(tester);

    Future<void> step() async {
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await step();
    expect(sidebarVisibleWidth(tester), 264);

    await tester.tap(find.byIcon(Icons.menu_open_rounded));
    await tester.pump();
    await step();
    expect(sidebarVisibleWidth(tester), 88);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await step();
    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left_rounded));
    await tester.pump();
    await step();
    expect(sidebarVisibleWidth(tester), 0);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    await step();
    expect(sidebarVisibleWidth(tester), 88);

    expect(tester.takeException(), isNull);
    await disposeShell(tester);
  });

  testWidgets('should fade the labels in and out with the width instead of popping', (tester) async {
    await pumpShell(tester);
    double labelOpacity() {
      final opacity = find.descendant(of: find.byType(ShellSidebar), matching: find.byType(Opacity));
      return opacity.evaluate().isEmpty ? 0 : tester.widget<Opacity>(opacity.at(1)).opacity;
    }

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = labelOpacity();

    expect(midway, greaterThan(0));
    expect(midway, lessThan(1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(labelOpacity(), 1);
    await disposeShell(tester);
  });

  testWidgets('should animate every transition on a wide screen too', (tester) async {
    await pumpShell(tester, size: const Size(1200, 800));
    expect(sidebarVisibleWidth(tester), 88);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(sidebarVisibleWidth(tester), inExclusiveRange(88, 264));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sidebarVisibleWidth(tester), 264);

    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(sidebarVisibleWidth(tester), inExclusiveRange(0, 264));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sidebarVisibleWidth(tester), 0);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(sidebarVisibleWidth(tester), inExclusiveRange(0, 88));

    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
    await disposeShell(tester);
  });
}
