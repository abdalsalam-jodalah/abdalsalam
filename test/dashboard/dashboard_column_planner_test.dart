import 'package:abdalsalam/core/constants/dashboard_card_catalog.dart';
import 'package:abdalsalam/features/dashboard/services/dashboard_column_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardColumnPlanner.columnCountFor', () {
    test('should use one column on phones, two on tablets, three on large screens', () {
      expect(DashboardColumnPlanner.columnCountFor(390), 1);
      expect(DashboardColumnPlanner.columnCountFor(759), 1);
      expect(DashboardColumnPlanner.columnCountFor(760), 2);
      expect(DashboardColumnPlanner.columnCountFor(1199), 2);
      expect(DashboardColumnPlanner.columnCountFor(1200), 3);
    });
  });

  group('DashboardColumnPlanner.plan', () {
    const cards = DashboardCardCatalog.defaultOrder;

    test('should keep every card in order in a single column', () {
      expect(DashboardColumnPlanner.plan(cards, 1), [cards]);
    });

    test('should place every card exactly once across columns', () {
      for (final count in [2, 3]) {
        final placed = DashboardColumnPlanner.plan(cards, count).expand((column) => column).toList();

        expect(placed, unorderedEquals(cards));
      }
    });

    test('should keep the relative order of cards within a column', () {
      final columns = DashboardColumnPlanner.plan(cards, 2);

      for (final column in columns) {
        final indexes = column.map(cards.indexOf).toList();
        expect(indexes, [...indexes]..sort());
      }
    });

    test('should balance tall cards so one column does not hold them all', () {
      final columns = DashboardColumnPlanner.plan(
        const [DashboardCardCatalog.weather, DashboardCardCatalog.currency],
        2,
      );

      expect(columns[0], [DashboardCardCatalog.weather]);
      expect(columns[1], [DashboardCardCatalog.currency]);
    });

    test('should return empty columns when there are fewer cards than columns', () {
      final columns = DashboardColumnPlanner.plan(const [DashboardCardCatalog.today], 3);

      expect(columns, [
        [DashboardCardCatalog.today],
        <String>[],
        <String>[],
      ]);
    });

    test('should handle no visible cards', () {
      expect(DashboardColumnPlanner.plan(const <String>[], 2), [<String>[], <String>[]]);
    });
  });
}
