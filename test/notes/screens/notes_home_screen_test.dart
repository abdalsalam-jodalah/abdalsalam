import 'package:abdalsalam/data/models/notes/note.dart';
import 'package:abdalsalam/data/repositories/notes/notes_repository.dart';
import 'package:abdalsalam/features/notes/providers/notes_providers.dart';
import 'package:abdalsalam/features/notes/screens/notes_home_screen.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/failing_writes.dart';
import '../notes_fakes.dart';

class _FailingNotesRepository = NotesRepositoryImpl with FailingWrites<Note>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await StorageGateway.instance.initialize(databaseName: 'test_notes_home_screen_test.db');
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
    for (final table in ['notes', 'reminders']) {
      await StorageGateway.instance.clearTable(table);
    }
  });

  testWidgets('shows AsyncErrorView friendly message and retries on failure', (tester) async {
    final repo = FakeNotesRepository()..shouldFailGetActive = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notesRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: NotesHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Failed to load notes'), findsNothing);

    final callsBeforeRetry = repo.getActiveCallCount;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repo.getActiveCallCount, greaterThan(callsBeforeRetry));
  });

  testWidgets('rejects an empty title and does not save, then shows a mapped error on failure', (tester) async {
    final logger = LoggerService.forModule('NotesHomeScreenTest');
    final failingRepository = _FailingNotesRepository(StorageGateway.instance, logger);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notesRepositoryProvider.overrideWithValue(failingRepository)],
        child: const MaterialApp(home: NotesHomeScreen()),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New Note'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(find.text('Label is required'), findsOneWidget);
    expect(find.text('New Note'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Groceries');
    await tester.tap(find.text('Create'));
    await _settle(tester);

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
  }
}
