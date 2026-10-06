import 'dart:async';

import 'package:flutter/widgets.dart';

class DragAutoScroller {
  static const double _edgeZone = 72;
  static const double _maxStep = 14;
  static const Duration _tick = Duration(milliseconds: 16);

  final ScrollController controller;
  Timer? _timer;
  double _velocity = 0;

  DragAutoScroller(this.controller);

  void update({required double pointer, required double viewportExtent}) {
    if (pointer < _edgeZone) {
      _velocity = -_maxStep * (1 - pointer.clamp(0, _edgeZone) / _edgeZone);
    } else if (pointer > viewportExtent - _edgeZone) {
      _velocity = _maxStep * (1 - (viewportExtent - pointer).clamp(0, _edgeZone) / _edgeZone);
    } else {
      _velocity = 0;
    }
    if (_velocity == 0) {
      _cancelTimer();
      return;
    }
    _timer ??= Timer.periodic(_tick, (_) => _step());
  }

  void stop() {
    _velocity = 0;
    _cancelTimer();
  }

  void _step() {
    if (!controller.hasClients) return;
    final position = controller.position;
    controller.jumpTo((position.pixels + _velocity).clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
