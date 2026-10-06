import '../../../data/models/financial/exchange_rate_model.dart';

class ExchangeRateSeries {
  static const double _percentScale = 100;

  const ExchangeRateSeries._();

  static double? ilsPerUnit(double unitsPerIls) {
    return unitsPerIls.isFinite && unitsPerIls > 0 ? 1 / unitsPerIls : null;
  }

  static List<double> ilsPerUnitSeries(List<ExchangeRateModel> historyOfUnitsPerIls) {
    return <double>[
      for (final entry in historyOfUnitsPerIls)
        if (ilsPerUnit(entry.rate) != null) ilsPerUnit(entry.rate)!,
    ];
  }

  static double? changePercent(List<double> series) {
    if (series.length < 2 || series.first == 0) {
      return null;
    }
    return (series.last - series.first) / series.first * _percentScale;
  }
}
