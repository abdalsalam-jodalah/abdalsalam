import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/widgets/async_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => ProviderScope(child: MaterialApp(home: Scaffold(body: child)));

  testWidgets('should show the friendly message instead of the raw error', (tester) async {
    await tester.pumpWidget(host(AsyncErrorView(error: DatabaseError('SqfliteException: no such table'))));

    expect(find.text(UserErrorMessages.database), findsOneWidget);
    expect(find.textContaining('Sqflite'), findsNothing);
  });

  testWidgets('should call onRetry when Retry is tapped', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(host(AsyncErrorView(error: NetworkError('down'), onRetry: () => retryCount++)));

    await tester.tap(find.text('Retry'));

    expect(retryCount, 1);
  });

  testWidgets('should hide the Retry button when no callback is given', (tester) async {
    await tester.pumpWidget(host(AsyncErrorView(error: NetworkError('down'), isCompact: true)));

    expect(find.text('Retry'), findsNothing);
    expect(find.text(UserErrorMessages.network), findsOneWidget);
  });
}
