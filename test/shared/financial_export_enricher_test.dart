import 'package:abdalsalam/shared/services/financial_export_enricher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const enricher = FinancialExportEnricher();

  Map<String, List<Map<String, dynamic>>> sampleRows() => {
        'accounts': [
          {'id': 'acc1', 'name': 'Cash'},
        ],
        'categories': [
          {'id': 'cat1', 'name': 'Food'},
        ],
        'transactions': [
          {'id': 't1', 'accountId': 'acc1', 'categoryId': 'cat1', 'amount': 10},
          {'id': 't2', 'accountId': 'missing', 'categoryId': 'cat1', 'amount': 5},
        ],
        'budgets': [
          {'id': 'b1', 'categoryId': 'cat1'},
        ],
      };

  group('FinancialExportEnricher', () {
    test('should add account and category names to transactions', () {
      final result = enricher.enrich(sampleRows());

      expect(result['transactions']![0]['accountName'], 'Cash');
      expect(result['transactions']![0]['categoryName'], 'Food');
    });

    test('should leave the name empty when the referenced account no longer exists', () {
      final result = enricher.enrich(sampleRows());

      expect(result['transactions']![1]['accountName'], isNull);
      expect(result['transactions']![1]['categoryName'], 'Food');
    });

    test('should add the category name to budgets', () {
      final result = enricher.enrich(sampleRows());

      expect(result['budgets']![0]['categoryName'], 'Food');
    });

    test('should not change the rows it was given', () {
      final rows = sampleRows();

      enricher.enrich(rows);

      expect(rows['transactions']![0].containsKey('accountName'), isFalse);
    });

    test('should tolerate a module without transactions or budgets', () {
      final result = enricher.enrich({
        'prayer_logs': [
          {'id': 'p1'},
        ],
      });

      expect(result.keys, ['prayer_logs']);
    });
  });
}
