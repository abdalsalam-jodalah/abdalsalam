import 'dart:math' as math;

import '../../core/result/result.dart';
import '../../core/errors/app_error.dart';

class AnalyticsEngine {
  static const int _minimumSamplesForAnomalies = 3;
  static const double _spendingSpikeMultiplier = 1.5;

  Future<Result<Map<String, dynamic>, AppError>> computeCrossModuleInsights({
    required List<double> moodScores,
    required List<double> workoutCounts,
    required List<double> spending,
    required List<double> income,
  }) async {
    final correlation = _correlation(moodScores, workoutCounts);
    final expenseRatio = income.isEmpty
      ? 0.0
      : (spending.fold<double>(0, (a, b) => a + b) /
        math.max(1.0, income.fold<double>(0, (a, b) => a + b)));

    return Success(<String, dynamic>{
      'moodWorkoutCorrelation': correlation,
      'expenseToIncomeRatio': expenseRatio,
      'insights': _buildInsights(correlation, expenseRatio),
      'anomalies': _detectAnomalies(spending),
    });
  }

  double _correlation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) {
      return 0;
    }

    final meanX = x.reduce((a, b) => a + b) / x.length;
    final meanY = y.reduce((a, b) => a + b) / y.length;
    var numerator = 0.0;
    var denomX = 0.0;
    var denomY = 0.0;

    for (var i = 0; i < x.length; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      numerator += dx * dy;
      denomX += dx * dx;
      denomY += dy * dy;
    }

    if (denomX == 0 || denomY == 0) {
      return 0;
    }
    return numerator / math.sqrt(denomX * denomY);
  }

  List<String> _buildInsights(double correlation, double expenseRatio) {
    final output = <String>[];
    if (correlation > 0.4) {
      output.add('Workout consistency is positively linked to mood.');
    } else {
      output.add('Mood and workout pattern is weak; consider a stable training schedule.');
    }

    if (expenseRatio > 0.9) {
      output.add('Spending is close to income. Review optional expenses this week.');
    } else {
      output.add('Spending remains under control compared to income.');
    }

    return output;
  }

  List<String> _detectAnomalies(List<double> spending) {
    if (spending.length < _minimumSamplesForAnomalies) {
      return const <String>[];
    }
    final averageSpending = spending.reduce((a, b) => a + b) / spending.length;
    if (averageSpending <= 0) {
      return const <String>[];
    }
    final anomalies = <String>[];
    for (var i = 0; i < spending.length; i++) {
      if (spending[i] > averageSpending * _spendingSpikeMultiplier) {
        anomalies.add('Spending spike detected at index $i');
      }
    }
    return anomalies;
  }
}
