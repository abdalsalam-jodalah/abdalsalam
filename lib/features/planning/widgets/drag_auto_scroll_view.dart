import 'package:flutter/widgets.dart';

import 'drag_auto_scroller.dart';
import 'planning_drag_controller.dart';

class DragAutoScrollView extends StatefulWidget {
  final PlanningDragController dragController;
  final Axis axis;
  final double initialScrollOffset;
  final Widget Function(BuildContext context, ScrollController controller) builder;

  const DragAutoScrollView({
    super.key,
    required this.dragController,
    required this.builder,
    this.axis = Axis.vertical,
    this.initialScrollOffset = 0,
  });

  @override
  State<DragAutoScrollView> createState() => _DragAutoScrollViewState();
}

class _DragAutoScrollViewState extends State<DragAutoScrollView> {
  late final ScrollController _controller = ScrollController(initialScrollOffset: widget.initialScrollOffset);
  late final DragAutoScroller _autoScroller = DragAutoScroller(_controller);

  @override
  void initState() {
    super.initState();
    widget.dragController.addListener(_stopWhenDragEnds);
  }

  @override
  void didUpdateWidget(DragAutoScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dragController != widget.dragController) {
      oldWidget.dragController.removeListener(_stopWhenDragEnds);
      widget.dragController.addListener(_stopWhenDragEnds);
    }
  }

  @override
  void dispose() {
    widget.dragController.removeListener(_stopWhenDragEnds);
    _autoScroller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _stopWhenDragEnds() {
    if (!widget.dragController.isDragging) {
      _autoScroller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = widget.axis == Axis.vertical;
    return LayoutBuilder(
      builder: (context, constraints) => Listener(
        onPointerMove: (event) {
          if (widget.dragController.isDragging) {
            _autoScroller.update(
              pointer: isVertical ? event.localPosition.dy : event.localPosition.dx,
              viewportExtent: isVertical ? constraints.maxHeight : constraints.maxWidth,
            );
          }
        },
        onPointerUp: (_) => _autoScroller.stop(),
        onPointerCancel: (_) => _autoScroller.stop(),
        child: widget.builder(context, _controller),
      ),
    );
  }
}
