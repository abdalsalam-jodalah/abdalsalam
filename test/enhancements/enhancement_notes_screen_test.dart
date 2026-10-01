import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/features/enhancements/screens/enhancement_notes_screen.dart';
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

  Future<void> settle(WidgetTester tester) async {
    for (var round = 0; round < 6; round++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(Appearance.defaults, Brightness.light),
          home: const EnhancementNotesScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> addNote(WidgetTester tester, String title, {String? details, String? priority}) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'What should be improved?'), title);
    if (details != null) {
      await tester.enterText(find.widgetWithText(TextFormField, 'Details (optional)'), details);
    }
    if (priority != null) {
      await tester.tap(find.text(priority));
      await settle(tester);
    }
    await tester.tap(find.text('Add'));
    await settle(tester);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await StorageGateway.instance.initialize(databaseName: 'test_enhancement_notes_screen_test.db');
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
    await StorageGateway.instance.clearTable('app_enhancement_notes');
  });

  testWidgets('should invite the first note when there are none', (tester) async {
    await pumpScreen(tester);

    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.text('Write down anything you want to improve in the app.'), findsOneWidget);
  });

  testWidgets('should add a note with details and priority and show it in the open list', (tester) async {
    await pumpScreen(tester);

    await addNote(tester, 'Smoother sidebar', details: 'Animate closing too', priority: 'High');

    expect(find.text('Smoother sidebar'), findsOneWidget);
    expect(find.text('Animate closing too'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Open (1)'), findsOneWidget);
  });

  testWidgets('should not add a note without a title', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.tap(find.text('Add'));
    await settle(tester);

    expect(find.text('Write what you want to improve'), findsOneWidget);
  });

  testWidgets('should move a note to the done list when ticked', (tester) async {
    await pumpScreen(tester);
    await addNote(tester, 'Fix icons');

    await tester.tap(find.byType(Checkbox));
    await settle(tester);

    expect(find.text('Fix icons'), findsNothing);
    expect(find.text('Nothing left to improve'), findsOneWidget);
    expect(find.text('Done (1)'), findsOneWidget);

    await tester.tap(find.text('Done (1)'));
    await settle(tester);

    expect(find.text('Fix icons'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('should show every note under all', (tester) async {
    await pumpScreen(tester);
    await addNote(tester, 'First');
    await addNote(tester, 'Second');
    await tester.tap(find.byType(Checkbox).first);
    await settle(tester);

    await tester.tap(find.text('All (2)'));
    await settle(tester);

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('should edit a note', (tester) async {
    await pumpScreen(tester);
    await addNote(tester, 'Old title');

    await tester.tap(find.text('Old title'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'What should be improved?'), 'New title');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('New title'), findsOneWidget);
    expect(find.text('Old title'), findsNothing);
  });

  testWidgets('should delete a note', (tester) async {
    await pumpScreen(tester);
    await addNote(tester, 'Remove me');

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);

    expect(find.text('Remove me'), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('should keep notes after the page is rebuilt', (tester) async {
    await pumpScreen(tester);
    await addNote(tester, 'Persist me');

    await tester.pumpWidget(const SizedBox());
    await pumpScreen(tester);

    expect(find.text('Persist me'), findsOneWidget);
  });
}
