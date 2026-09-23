import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/widgets/data_integrity_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(int corruptRecordCount) => ProviderScope(
        overrides: [corruptRecordCountProvider.overrideWith((ref) => Stream.value(corruptRecordCount))],
        child: MaterialApp(home: Scaffold(body: DataIntegrityBanner(navigatorKey: GlobalKey<NavigatorState>()))),
      );

  testWidgets('should stay hidden when no records are corrupt', (tester) async {
    await tester.pumpWidget(host(0));
    await tester.pump();

    expect(find.text('View'), findsNothing);
  });

  testWidgets('should tell the user how many records are hidden', (tester) async {
    await tester.pumpWidget(host(3));
    await tester.pump();

    expect(find.text(DataIntegrityBanner.messageFor(3)), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
  });
}
