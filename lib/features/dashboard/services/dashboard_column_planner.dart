import '../../../core/constants/dashboard_card_catalog.dart';

class DashboardColumnPlanner {
  static const double _defaultHeight = 240;
  static const double _threeColumnMinWidth = 1200;
  static const double _twoColumnMinWidth = 760;
  static const Map<String, double> _estimatedHeights = <String, double>{
    DashboardCardCatalog.today: 150,
    DashboardCardCatalog.age: 230,
    DashboardCardCatalog.weather: 380,
    DashboardCardCatalog.currency: 440,
    DashboardCardCatalog.goals: 230,
    DashboardCardCatalog.agenda: 300,
  };

  const DashboardColumnPlanner._();

  static int columnCountFor(double width) {
    if (width >= _threeColumnMinWidth) return 3;
    if (width >= _twoColumnMinWidth) return 2;
    return 1;
  }

  static List<List<String>> plan(List<String> cards, int columnCount) {
    final columns = List<List<String>>.generate(columnCount, (_) => <String>[]);
    final heights = List<double>.filled(columnCount, 0);
    for (final card in cards) {
      var shortest = 0;
      for (var index = 1; index < columnCount; index++) {
        if (heights[index] < heights[shortest]) shortest = index;
      }
      columns[shortest].add(card);
      heights[shortest] += _estimatedHeights[card] ?? _defaultHeight;
    }
    return columns;
  }
}
