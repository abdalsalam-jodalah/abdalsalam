// lib/shared/services/financial_export_enricher.dart — adds account and category names next to their ids in financial exports.

import 'export_row_enricher.dart';

class FinancialExportEnricher implements ExportRowEnricher {
  static const String _transactionsTable = 'transactions';
  static const String _budgetsTable = 'budgets';
  static const String _accountsTable = 'accounts';
  static const String _categoriesTable = 'categories';
  static const String _nameField = 'name';
  static const String _accountIdField = 'accountId';
  static const String _categoryIdField = 'categoryId';
  static const String _accountNameField = 'accountName';
  static const String _categoryNameField = 'categoryName';

  const FinancialExportEnricher();

  @override
  Map<String, List<Map<String, dynamic>>> enrich(Map<String, List<Map<String, dynamic>>> rowsByTable) {
    final accountNames = _namesById(rowsByTable[_accountsTable]);
    final categoryNames = _namesById(rowsByTable[_categoriesTable]);
    final enriched = <String, List<Map<String, dynamic>>>{...rowsByTable};

    final transactions = rowsByTable[_transactionsTable];
    if (transactions != null) {
      enriched[_transactionsTable] = transactions
          .map((row) => <String, dynamic>{
                ...row,
                _accountNameField: accountNames[row[_accountIdField]],
                _categoryNameField: categoryNames[row[_categoryIdField]],
              })
          .toList(growable: false);
    }
    final budgets = rowsByTable[_budgetsTable];
    if (budgets != null) {
      enriched[_budgetsTable] = budgets
          .map((row) => <String, dynamic>{...row, _categoryNameField: categoryNames[row[_categoryIdField]]})
          .toList(growable: false);
    }
    return enriched;
  }

  Map<Object?, String> _namesById(List<Map<String, dynamic>>? rows) {
    final names = <Object?, String>{};
    for (final row in rows ?? const <Map<String, dynamic>>[]) {
      final name = row[_nameField];
      if (name is String) {
        names[row['id']] = name;
      }
    }
    return names;
  }
}
