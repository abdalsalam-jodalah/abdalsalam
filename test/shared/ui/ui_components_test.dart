import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/theme/app_background.dart';
import 'package:abdalsalam/core/theme/app_theme_builder.dart';
import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/core/theme/appearance_options.dart';
import 'package:abdalsalam/shared/widgets/charts/app_line_chart.dart';
import 'package:abdalsalam/shared/widgets/ui/async_section.dart';
import 'package:abdalsalam/shared/widgets/ui/date_time_field.dart';
import 'package:abdalsalam/shared/widgets/ui/entity_tile.dart';
import 'package:abdalsalam/shared/widgets/ui/filter_bar.dart';
import 'package:abdalsalam/shared/widgets/ui/filter_option.dart';
import 'package:abdalsalam/shared/widgets/ui/glass_surface.dart';
import 'package:abdalsalam/shared/widgets/ui/module_hub_destination.dart';
import 'package:abdalsalam/shared/widgets/ui/module_hub_scaffold.dart';
import 'package:abdalsalam/shared/widgets/ui/progress_bar.dart';
import 'package:abdalsalam/shared/widgets/ui/show_confirm_dialog.dart';
import 'package:abdalsalam/shared/widgets/ui/stat_grid.dart';
import 'package:abdalsalam/shared/widgets/ui/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Appearance appearance = Appearance.defaults, bool disableAnimations = false}) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(appearance, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: AppBackground(child: Scaffold(body: child)),
      ),
    ),
  );
}

void main() {
  group('GlassSurface', () {
    testWidgets('should blur only when requested and glass is enabled', (tester) async {
      await tester.pumpWidget(_host(const GlassSurface(isBlurred: true, child: Text('glass'))));
      expect(find.byType(BackdropFilter), findsOneWidget);

      await tester.pumpWidget(_host(const GlassSurface(child: Text('flat'))));
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('should never blur in solid surface style', (tester) async {
      await tester.pumpWidget(_host(
        const GlassSurface(isBlurred: true, child: Text('solid')),
        appearance: const Appearance(surfaceStyle: SurfaceStyle.solid),
      ));

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });

  group('StatTile and StatGrid', () {
    testWidgets('should show value, label and caption', (tester) async {
      await tester.pumpWidget(_host(const StatTile(
        icon: Icons.mosque_rounded,
        label: 'Prayers today',
        value: '4 / 5',
        caption: 'On track',
      )));

      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.text('Prayers today'), findsOneWidget);
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('should lay tiles out in several columns on wide screens', (tester) async {
      await tester.pumpWidget(_host(const StatGrid(children: [
        StatTile(icon: Icons.star, label: 'A', value: '1'),
        StatTile(icon: Icons.star, label: 'B', value: '2'),
        StatTile(icon: Icons.star, label: 'C', value: '3'),
      ])));

      final first = tester.getTopLeft(find.text('1'));
      final second = tester.getTopLeft(find.text('2'));
      expect(first.dy, second.dy);
    });
  });

  testWidgets('EntityTile should report taps and render trailing content', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(_host(EntityTile(
      icon: Icons.restaurant_rounded,
      title: 'Groceries',
      subtitle: 'Today',
      trailing: const Text('-86'),
      onTap: () => tapCount++,
    )));

    await tester.tap(find.text('Groceries'));

    expect(tapCount, 1);
    expect(find.text('-86'), findsOneWidget);
  });

  group('AsyncSection', () {
    testWidgets('should show the friendly error with retry', (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(_host(AsyncSection<int>(
        title: 'Weekly',
        value: AsyncValue.error(DatabaseError('raw text'), StackTrace.empty),
        onRetry: () => retryCount++,
        builder: (value) => Text('$value'),
      )));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(UserErrorMessages.database), findsOneWidget);
      expect(find.textContaining('raw text'), findsNothing);
      await tester.tap(find.text('Retry'));
      expect(retryCount, 1);
    });

    testWidgets('should render data', (tester) async {
      await tester.pumpWidget(_host(AsyncSection<int>(
        value: const AsyncValue.data(7),
        builder: (value) => Text('value $value'),
      )));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('value 7'), findsOneWidget);
    });
  });

  testWidgets('FilterBar should select an option', (tester) async {
    String? selected;
    await tester.pumpWidget(_host(FilterBar<String>(
      options: const [FilterOption('day', 'Day'), FilterOption('week', 'Week')],
      selected: 'day',
      onSelected: (value) => selected = value,
    )));

    await tester.tap(find.text('Week'));

    expect(selected, 'week');
  });

  testWidgets('DateTimeField should clear its value', (tester) async {
    DateTime? value = DateTime(2026, 9, 24);
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (context, setState) => DateTimeField(
        label: 'Due',
        value: value,
        isClearable: true,
        onChanged: (next) => setState(() => value = next),
      ),
    )));

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();

    expect(value, isNull);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('showConfirmDialog should resolve to the chosen answer', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(_host(Builder(builder: (context) {
      capturedContext = context;
      return const SizedBox.shrink();
    })));

    final answer = showConfirmDialog(capturedContext, title: 'Delete?', message: 'Sure?', confirmLabel: 'Delete');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await answer, isTrue);
  });

  testWidgets('ModuleHubScaffold should switch pages with the navigation bar', (tester) async {
    await tester.pumpWidget(_host(const ModuleHubScaffold(destinations: [
      ModuleHubDestination(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, page: Text('dashboard page')),
      ModuleHubDestination(label: 'Logs', icon: Icons.list_outlined, selectedIcon: Icons.list, page: Text('logs page')),
    ])));

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byIcon(Icons.list_outlined));
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
  });

  testWidgets('ProgressBar should jump straight to its value when animations are disabled', (tester) async {
    await tester.pumpWidget(_host(const ProgressBar(value: 0.6), disableAnimations: true));
    await tester.pump();

    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, closeTo(0.6, 0.001));
  });

  testWidgets('AppLineChart should show an empty state without data', (tester) async {
    await tester.pumpWidget(_host(const AppLineChart(points: [])));

    expect(find.text('No data yet'), findsOneWidget);
  });
}
