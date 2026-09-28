import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'glass_surface.dart';
import 'module_hub_destination.dart';

class ModuleHubScaffold extends StatefulWidget {
  final List<ModuleHubDestination> destinations;
  final int initialIndex;
  final Widget? floatingActionButton;

  const ModuleHubScaffold({
    super.key,
    required this.destinations,
    this.initialIndex = 0,
    this.floatingActionButton,
  });

  @override
  State<ModuleHubScaffold> createState() => _ModuleHubScaffoldState();
}

class _ModuleHubScaffoldState extends State<ModuleHubScaffold> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      extendBody: true,
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [for (final destination in widget.destinations) destination.page],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(tokens.spacing.lg, 0, tokens.spacing.lg, tokens.spacing.md),
        child: GlassSurface(
          isBlurred: true,
          borderRadius: tokens.radius.extraLargeBorder,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              for (final destination in widget.destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
