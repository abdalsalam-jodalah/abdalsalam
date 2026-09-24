import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/health/health_metric.dart';
import 'package:abdalsalam/data/repositories/health/health_metric_repository.dart';
import 'package:abdalsalam/features/health/providers/health_providers.dart';
import 'package:abdalsalam/features/health/screens/health_metrics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHealthMetricRepository implements HealthMetricRepository {
  final List<HealthMetric> items;
  bool shouldFailGetActive = false;

  _FakeHealthMetricRepository([List<HealthMetric>? seed]) : items = seed ?? <HealthMetric>[];

  @override
  Future<Result<List<HealthMetric>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(DatabaseError('fake storage failure'));
    }
    return Success(List<HealthMetric>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('shows AsyncErrorView friendly message on failure and reloads on retry', (tester) async {
    final repository = _FakeHealthMetricRepository()..shouldFailGetActive = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthMetricRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HealthMetricsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Your data could not be saved or loaded. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No metrics logged yet. Tap + to add one.'), findsNothing);

    repository.shouldFailGetActive = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No metrics logged yet. Tap + to add one.'), findsOneWidget);
  });
}
