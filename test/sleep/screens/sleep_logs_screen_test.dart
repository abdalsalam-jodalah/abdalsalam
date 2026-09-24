import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sleep/sleep_log.dart';
import 'package:abdalsalam/data/repositories/sleep/sleep_log_repository.dart';
import 'package:abdalsalam/features/sleep/providers/sleep_providers.dart';
import 'package:abdalsalam/features/sleep/screens/sleep_logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSleepLogRepository implements SleepLogRepository {
  final List<SleepLog> items;
  bool shouldFailGetActive = false;

  _FakeSleepLogRepository([List<SleepLog>? seed]) : items = seed ?? <SleepLog>[];

  @override
  Future<Result<List<SleepLog>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(DatabaseError('fake storage failure'));
    }
    return Success(List<SleepLog>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('shows AsyncErrorView friendly message on failure and reloads on retry', (tester) async {
    final repository = _FakeSleepLogRepository()..shouldFailGetActive = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sleepLogRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SleepLogsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Your data could not be saved or loaded. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No sleep logs yet. Tap + to add one.'), findsNothing);

    repository.shouldFailGetActive = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No sleep logs yet. Tap + to add one.'), findsOneWidget);
  });
}
