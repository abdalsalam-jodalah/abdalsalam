import 'package:flutter/widgets.dart';

class QuickLogAction {
  final String label;
  final IconData icon;
  final String routeName;
  final String moduleKey;

  const QuickLogAction({
    required this.label,
    required this.icon,
    required this.routeName,
    required this.moduleKey,
  });
}
