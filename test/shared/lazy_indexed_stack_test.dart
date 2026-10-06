import 'package:abdalsalam/shared/widgets/ui/lazy_indexed_stack.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  final VoidCallback onInit;

  const _Probe({required this.onInit});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  Widget buildStack(int index, List<int> builtLog) => Directionality(
        textDirection: TextDirection.ltr,
        child: LazyIndexedStack(
          index: index,
          children: [for (var position = 0; position < 3; position++) _Probe(onInit: () => builtLog.add(position))],
        ),
      );

  testWidgets('should only build the selected child on first render', (tester) async {
    final builtLog = <int>[];

    await tester.pumpWidget(buildStack(1, builtLog));

    expect(builtLog, [1]);
  });

  testWidgets('should build a child the first time it is selected and keep it afterwards', (tester) async {
    final builtLog = <int>[];
    await tester.pumpWidget(buildStack(0, builtLog));

    await tester.pumpWidget(buildStack(2, builtLog));
    await tester.pumpWidget(buildStack(0, builtLog));
    await tester.pumpWidget(buildStack(2, builtLog));

    expect(builtLog, [0, 2]);
  });
}
