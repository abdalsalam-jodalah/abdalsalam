import 'package:flutter/foundation.dart';

import '../../../data/models/planning/planning_task.dart';

class PlanningDragController extends ChangeNotifier {
  PlanningTask? _draggedTask;

  PlanningTask? get draggedTask => _draggedTask;

  bool get isDragging => _draggedTask != null;

  void start(PlanningTask task) {
    _draggedTask = task;
    notifyListeners();
  }

  void end() {
    if (_draggedTask == null) return;
    _draggedTask = null;
    notifyListeners();
  }
}
