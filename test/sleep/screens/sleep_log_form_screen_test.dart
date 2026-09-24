import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sleep/sleep_log.dart';
import 'package:abdalsalam/data/repositories/sleep/sleep_log_repository.dart';
import 'package:abdalsalam/features/sleep/providers/sleep_providers.dart';
import 'package:abdalsalam/features/sleep/screens/sleep_log_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSleepLogRepository implements SleepLogRepository {
  final List<SleepLog> items = <SleepLog>[];
  bool shouldFailCreate = false;
  bool updateCalled = false;

  @override
  Future<Result<List<SleepLog>, AppError>> getActive() async => Success(List<SleepLog>.of(items));

  @override
  Future<Result<SleepLog, AppError>> create(SleepLog entity) async {
    if (shouldFailCreate) {
      return Failure(DatabaseError('fake write failure'));
    }
    items.add(entity);
    return Success(entity);
  }

  @override
  Future<Result<void, AppError>> update(SleepLog entity) async {
    updateCalled = true;
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

SleepLog _buildLog({required DateTime sleepStart, required DateTime sleepEnd}) {
  return SleepLog(
    id: 'log-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userId: 'user',
    sleepStart: sleepStart,
    sleepEnd: sleepEnd,
  );
}

void main() {
  Future<void> useTallViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('rejects a sleep end before sleep start and does not save', (tester) async {
    await useTallViewport(tester);
    final repository = _FakeSleepLogRepository();
    final invalidLog = _buildLog(
      sleepStart: DateTime(2026, 1, 2, 23, 0),
      sleepEnd: DateTime(2026, 1, 2, 22, 0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sleepLogRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: SleepLogFormScreen(log: invalidLog)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Update'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Sleep end must be after sleep start.'), findsWidgets);
    expect(repository.updateCalled, isFalse);
  });

  testWidgets('shows an error snackbar and keeps the form open when save fails', (tester) async {
    await useTallViewport(tester);
    final repository = _FakeSleepLogRepository()..shouldFailCreate = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sleepLogRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SleepLogFormScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Your data could not be saved or loaded. Please try again.'), findsOneWidget);
    expect(find.byType(SleepLogFormScreen), findsOneWidget);
    expect(repository.items, isEmpty);
  });
}
