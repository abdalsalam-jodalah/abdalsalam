import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/health/health_metric.dart';
import 'package:abdalsalam/data/repositories/health/health_metric_repository.dart';
import 'package:abdalsalam/features/health/providers/health_providers.dart';
import 'package:abdalsalam/features/health/screens/health_metric_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHealthMetricRepository implements HealthMetricRepository {
  final List<HealthMetric> items = <HealthMetric>[];
  bool shouldFailCreate = false;

  @override
  Future<Result<List<HealthMetric>, AppError>> getActive() async => Success(List<HealthMetric>.of(items));

  @override
  Future<Result<HealthMetric, AppError>> create(HealthMetric entity) async {
    if (shouldFailCreate) {
      return Failure(DatabaseError('fake write failure'));
    }
    items.add(entity);
    return Success(entity);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('rejects a non-numeric value and does not save', (tester) async {
    final repository = _FakeHealthMetricRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthMetricRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HealthMetricFormScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'abc');
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Enter a valid number'), findsOneWidget);
    expect(repository.items, isEmpty);
  });

  testWidgets('shows an error snackbar and keeps the form open when save fails', (tester) async {
    final repository = _FakeHealthMetricRepository()..shouldFailCreate = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthMetricRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HealthMetricFormScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Your data could not be saved or loaded. Please try again.'), findsOneWidget);
    expect(find.byType(HealthMetricFormScreen), findsOneWidget);
    expect(repository.items, isEmpty);
  });
}
