import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Enlarges the test surface so long scrollable screens render their whole
/// content within the viewport, since [ListView] only builds children that
/// are laid out inside the viewport.
void enlargeTestSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
