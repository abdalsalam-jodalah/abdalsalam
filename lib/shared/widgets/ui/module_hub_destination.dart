import 'package:flutter/widgets.dart';

class ModuleHubDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const ModuleHubDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}
