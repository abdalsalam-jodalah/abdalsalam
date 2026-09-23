import 'package:abdalsalam/shared/services/analytics_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsEngine', () {
    final engine = AnalyticsEngine();

    Future<List<String>> anomaliesFor(List<double> spending) async {
      final result = await engine.computeCrossModuleInsights(
        moodScores: const <double>[],
        workoutCounts: const <double>[],
        spending: spending,
        income: const <double>[100],
      );
      return result.getOrThrow()['anomalies'] as List<String>;
    }

    test('should flag spending well above the average', () async {
      final anomalies = await anomaliesFor(const <double>[10, 10, 10, 100]);

      expect(anomalies, ['Spending spike detected at index 3']);
    });

    test('should report no anomalies when average spending is zero', () async {
      final anomalies = await anomaliesFor(const <double>[0, 0, 0]);

      expect(anomalies, isEmpty);
    });

    test('should report no anomalies when average spending is negative', () async {
      final anomalies = await anomaliesFor(const <double>[-50, -50, 5]);

      expect(anomalies, isEmpty);
    });

    test('should report no anomalies with fewer than three samples', () async {
      final anomalies = await anomaliesFor(const <double>[1, 100]);

      expect(anomalies, isEmpty);
    });
  });
}
