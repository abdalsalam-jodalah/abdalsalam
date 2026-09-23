import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox.shrink();
      })),
    ));
    return capturedContext;
  }

  testWidgets('should show the mapped message for an error', (tester) async {
    final context = await pumpHost(tester);

    AppFeedback.showError(context, ValidationError('invalid', fieldErrors: {'title': 'Title is required'}));
    await tester.pump();

    expect(find.text('Title is required'), findsOneWidget);
  });

  testWidgets('should never show raw text for unknown errors', (tester) async {
    final context = await pumpHost(tester);

    AppFeedback.showError(context, StateError('Bad state: internal'));
    await tester.pump();

    expect(find.text(UserErrorMessages.generic), findsOneWidget);
    expect(find.textContaining('Bad state'), findsNothing);
  });

  testWidgets('should show a success message', (tester) async {
    final context = await pumpHost(tester);

    AppFeedback.showSuccess(context, 'Saved');
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
  });
}
