import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/data/repositories/financial/transaction_repository.dart';
import 'package:abdalsalam/features/financial/providers/financial_providers.dart';
import 'package:abdalsalam/features/financial/screens/transaction_form_screen.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../fakes.dart';

const _unreachableApiStatus = 503;
final _logger = LoggerService.forModule('TransactionFormScreenTest');

CurrencyService _offlineCurrencyService() {
  final client = MockClient((request) async => http.Response('unavailable', _unreachableApiStatus));
  return CurrencyService(_logger, StorageGateway.instance, httpClient: client);
}

List<Override> _overrides({TransactionRepository? transactionRepo}) {
  return [
    transactionRepositoryProvider.overrideWithValue(transactionRepo ?? FakeTransactionRepository()),
    categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
    budgetRepositoryProvider.overrideWithValue(FakeBudgetRepository()),
    accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
    financialActivityLogRepositoryProvider.overrideWithValue(FakeFinancialActivityLogRepository()),
    exchangeRateRepositoryProvider.overrideWithValue(FakeExchangeRateRepository()),
    currencyServiceProvider.overrideWithValue(_offlineCurrencyService()),
  ];
}

TransactionModel _transaction({required String id}) {
  final date = DateTime(2026, 1, 5);
  return TransactionModel(
    id: id,
    userId: 'abdalsalam',
    type: TransactionType.expense,
    amount: 42,
    currency: 'ILS',
    categoryId: 'c1',
    date: date,
    description: 'test transaction $id',
    createdAt: date,
    updatedAt: date,
  );
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LoggerService.initialize();
  });

  testWidgets('rejects invalid input and does not save', (tester) async {
    _useTallView(tester);
    final transaction = _transaction(id: 't1');
    final repo = FakeTransactionRepository([transaction]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(transactionRepo: repo),
        child: MaterialApp(home: TransactionFormScreen(transaction: transaction)),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), '');
    await tester.enterText(fields.at(1), '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Amount is required'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);
    expect(repo.transactions, hasLength(1));
    expect(repo.transactions.first.amount, transaction.amount);
  });

  testWidgets('delete failure shows a mapped error and keeps the form open', (tester) async {
    final transaction = _transaction(id: 't1');
    final repo = FailingTransactionRepository([transaction], isDeleteFailing: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(transactionRepo: repo),
        child: MaterialApp(home: TransactionFormScreen(transaction: transaction)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Delete Transaction'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Delete Transaction'), findsOneWidget);
    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(repo.transactions, hasLength(1));
  });
}
