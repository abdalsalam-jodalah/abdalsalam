import 'package:abdalsalam/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AbdalsalamApp()));

    expect(find.text('Abdalsalam Dashboard'), findsOneWidget);
    expect(find.text('Open Religious Tracking'), findsOneWidget);
  });
}
