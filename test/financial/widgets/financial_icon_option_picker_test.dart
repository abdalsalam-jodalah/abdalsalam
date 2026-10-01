import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/financial/financial_icon_palette.dart';
import 'package:abdalsalam/features/financial/widgets/financial_icon_option_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const collapsedCount = 12;
  late List<IconData> selections;

  Widget host({required IconData selected, int? collapsed = collapsedCount, List<IconData>? options}) {
    return MaterialApp(
      theme: buildAppTheme(Appearance.defaults, Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: FinancialIconOptionPicker(
            options: options ?? financialCategoryIcons,
            collapsedCount: collapsed,
            selected: selected,
            accentColor: Colors.teal,
            onSelected: selections.add,
          ),
        ),
      ),
    );
  }

  Finder tileOf(IconData icon) => find.byKey(FinancialIconOptionPicker.tileKeyFor(icon));

  int visibleTileCount(WidgetTester tester) {
    return financialCategoryIcons.where((icon) => tileOf(icon).evaluate().isNotEmpty).length;
  }

  setUp(() => selections = <IconData>[]);

  testWidgets('should start collapsed to the first icons with a button to show them all', (tester) async {
    await tester.pumpWidget(host(selected: financialCategoryIcons.first));

    expect(visibleTileCount(tester), collapsedCount);
    expect(find.text('Show all ${financialCategoryIcons.length} icons'), findsOneWidget);
  });

  testWidgets('should show every icon after tapping show all', (tester) async {
    await tester.pumpWidget(host(selected: financialCategoryIcons.first));

    await tester.tap(find.text('Show all ${financialCategoryIcons.length} icons'));
    await tester.pumpAndSettle();

    expect(visibleTileCount(tester), financialCategoryIcons.length);
    expect(find.text('Show fewer icons'), findsOneWidget);
  });

  testWidgets('should collapse again after tapping show fewer', (tester) async {
    await tester.pumpWidget(host(selected: financialCategoryIcons.first));
    await tester.tap(find.text('Show all ${financialCategoryIcons.length} icons'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show fewer icons'));
    await tester.pumpAndSettle();

    expect(visibleTileCount(tester), collapsedCount);
  });

  testWidgets('should start expanded when the selected icon is further down so it is not hidden', (tester) async {
    final farIcon = financialCategoryIcons.last;
    await tester.pumpWidget(host(selected: farIcon));

    expect(visibleTileCount(tester), financialCategoryIcons.length);
    expect(tileOf(farIcon), findsOneWidget);
    expect(find.text('Show fewer icons'), findsOneWidget);
  });

  testWidgets('should report the icon that was tapped', (tester) async {
    await tester.pumpWidget(host(selected: financialCategoryIcons.first));

    await tester.tap(tileOf(financialCategoryIcons[3]));

    expect(selections, [financialCategoryIcons[3]]);
  });

  testWidgets('should not offer collapsing when no collapsed count is given', (tester) async {
    await tester.pumpWidget(host(selected: financialCategoryIcons.first, collapsed: null));

    expect(visibleTileCount(tester), financialCategoryIcons.length);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('should not offer collapsing when every icon already fits', (tester) async {
    final fewIcons = financialCategoryIcons.take(5).toList();
    await tester.pumpWidget(host(selected: fewIcons.first, options: fewIcons));

    expect(find.byType(TextButton), findsNothing);
  });
}
