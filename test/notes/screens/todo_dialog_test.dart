import 'package:abdalsalam/data/models/notes/todo.dart';
import 'package:abdalsalam/data/repositories/notes/todo_repository.dart';
import 'package:abdalsalam/features/notes/providers/notes_providers.dart';
import 'package:abdalsalam/features/notes/screens/todo_list_screen.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/failing_writes.dart';

class _FailingTodoRepository = TodoRepositoryImpl with FailingWrites<Todo>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await StorageGateway.instance.initialize(databaseName: 'test_todo_dialog_test.db');
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
    for (final table in ['todos', 'reminders']) {
      await StorageGateway.instance.clearTable(table);
    }
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }
  }

  testWidgets('rejects an empty title and does not save, then shows a mapped error and keeps the dialog open on failure', (tester) async {
    final logger = LoggerService.forModule('TodoDialogTest');
    final failingRepository = _FailingTodoRepository(StorageGateway.instance, logger);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoRepositoryProvider.overrideWithValue(failingRepository)],
        child: const MaterialApp(home: TodoListScreen()),
      ),
    );
    await settle(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New Todo'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(find.text('Label is required'), findsOneWidget);
    expect(find.text('New Todo'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Call the bank');
    await tester.tap(find.text('Create'));
    await settle(tester);

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('New Todo'), findsOneWidget);
    expect(find.text('Call the bank'), findsOneWidget);
  });
}
