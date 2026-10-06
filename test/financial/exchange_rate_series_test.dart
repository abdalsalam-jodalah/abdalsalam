import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/features/financial/services/exchange_rate_series.dart';
import 'package:flutter_test/flutter_test.dart';

ExchangeRateModel _rate(double rate) {
  final now = DateTime(2026, 1, 1);
  return ExchangeRateModel(
    id: 'r$rate',
    fromCurrency: 'ILS',
    toCurrency: 'USD',
    rate: rate,
    date: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ExchangeRateSeries', () {
    test('should invert units per ILS into ILS per unit', () {
      expect(ExchangeRateSeries.ilsPerUnit(0.25), 4);
    });

    test('should return null for zero negative or non finite rates', () {
      expect(ExchangeRateSeries.ilsPerUnit(0), isNull);
      expect(ExchangeRateSeries.ilsPerUnit(-1), isNull);
      expect(ExchangeRateSeries.ilsPerUnit(double.nan), isNull);
    });

    test('should invert a history and skip unusable entries', () {
      final series = ExchangeRateSeries.ilsPerUnitSeries([_rate(0.5), _rate(0), _rate(0.25)]);

      expect(series, [2, 4]);
    });

    test('should compute the percent change from first to last', () {
      expect(ExchangeRateSeries.changePercent([3.5, 3.7]), closeTo(5.714, 0.001));
      expect(ExchangeRateSeries.changePercent([4, 3]), -25);
    });

    test('should not compute a change from fewer than two points or a zero start', () {
      expect(ExchangeRateSeries.changePercent([3.5]), isNull);
      expect(ExchangeRateSeries.changePercent(const []), isNull);
      expect(ExchangeRateSeries.changePercent([0, 1]), isNull);
    });
  });
}
