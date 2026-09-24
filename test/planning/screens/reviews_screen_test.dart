import 'package:abdalsalam/data/models/planning/review.dart';
import 'package:abdalsalam/data/repositories/planning/review_repository.dart';
import 'package:abdalsalam/features/planning/providers/planning_providers.dart';
import 'package:abdalsalam/features/planning/screens/reviews_screen.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/failing_writes.dart';
import '../../support/test_storage.dart';

class _FailingReviewRepository = ReviewRepositoryImpl with FailingWrites<Review>;

void main() {
  initializeTestDatabaseFactory();

  setUp(() async {
    await resetTestStorage(databaseName: 'test_reviews_screen_test.db', tables: ['life_reviews']);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }
  }

  testWidgets('rejects an empty review and does not save, then shows a mapped error on failure', (tester) async {
    final logger = LoggerService.forModule('ReviewsScreenTest');
    final failingRepository = _FailingReviewRepository(StorageGateway.instance, logger);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [reviewRepositoryProvider.overrideWithValue(failingRepository)],
        child: const MaterialApp(home: ReviewsScreen()),
      ),
    );
    await settle(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New Review'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Fill in at least one field below before saving'), findsWidgets);
    expect(find.text('New Review'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Shipped the robustness phase');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(
      find.text('Your data could not be saved or loaded. Please try again.'),
      findsOneWidget,
    );
  });
}
