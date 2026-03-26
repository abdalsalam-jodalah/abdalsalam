import 'package:flutter/material.dart';

import '../../analytics/screens/analytics_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../financial/screens/financial_screen.dart';
import '../../habits/screens/habits_screen.dart';
import '../../health/screens/health_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../religious/screens/religious_home_screen.dart';
import '../../security/screens/security_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../sports/screens/sports_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

enum _SidebarMode { closed, icons, expanded }

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 0;
  _SidebarMode _sidebarMode = _SidebarMode.icons;
  double _dragDelta = 0;

  static const double _closedWidth = 0;
  static const double _iconsWidth = 84;
  static const double _expandedWidth = 260;
  static const double _dragThreshold = 56;
  static const double _edgeSwipeZone = 28;

  static const _destinations = <_ShellDestination>[
    _ShellDestination('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
    _ShellDestination('Quick Add', Icons.add_circle_outline, _QuickAddPage()),
    _ShellDestination('Religious', Icons.mosque_outlined, ReligiousHomeScreen()),
    _ShellDestination('Financial', Icons.account_balance_wallet_outlined, FinancialScreen()),
    _ShellDestination('Habits', Icons.repeat_rounded, HabitsScreen()),
    _ShellDestination('Sports', Icons.fitness_center, SportsScreen()),
    _ShellDestination('Health', Icons.health_and_safety_outlined, HealthScreen()),
    _ShellDestination('Notes', Icons.sticky_note_2_outlined, NotesScreen()),
    _ShellDestination('Calendar', Icons.calendar_month_outlined, CalendarScreen()),
    _ShellDestination('Security', Icons.lock_outline, SecurityScreen()),
    _ShellDestination('Analytics', Icons.insights_outlined, AnalyticsScreen()),
    _ShellDestination('Settings', Icons.settings_outlined, SettingsScreen()),
  ];

  double get _sidebarWidth {
    switch (_sidebarMode) {
      case _SidebarMode.closed:
        return _closedWidth;
      case _SidebarMode.icons:
        return _iconsWidth;
      case _SidebarMode.expanded:
        return _expandedWidth;
    }
  }

  void _setMode(_SidebarMode mode) {
    setState(() => _sidebarMode = mode);
  }

  void _stepOpen() {
    if (_sidebarMode == _SidebarMode.closed) {
      _setMode(_SidebarMode.icons);
    } else if (_sidebarMode == _SidebarMode.icons) {
      _setMode(_SidebarMode.expanded);
    }
  }

  void _stepClose() {
    if (_sidebarMode == _SidebarMode.expanded) {
      _setMode(_SidebarMode.icons);
    } else if (_sidebarMode == _SidebarMode.icons) {
      _setMode(_SidebarMode.closed);
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragDelta = 0;
    if (_sidebarMode == _SidebarMode.closed && details.localPosition.dx > _edgeSwipeZone) {
      _dragDelta = double.nan;
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragDelta.isNaN) {
      return;
    }
    _dragDelta += details.delta.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_dragDelta.isNaN) {
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final openIntent = _dragDelta >= _dragThreshold || velocity > 420;
    final closeIntent = _dragDelta <= -_dragThreshold || velocity < -420;

    if (openIntent) {
      _stepOpen();
    } else if (closeIntent) {
      _stepClose();
    }

    _dragDelta = 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _destinations[_index];
    final sidebarWidth = _sidebarWidth;
    final isExpanded = _sidebarMode == _SidebarMode.expanded;
    final isClosed = _sidebarMode == _SidebarMode.closed;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleHorizontalDragStart,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: sidebarWidth,
                decoration: BoxDecoration(
                  color: sidebarWidth == 0
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  border: Border(
                    right: BorderSide(
                      color: sidebarWidth == 0
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: sidebarWidth == 0
                    ? const SizedBox.shrink()
                    : _Sidebar(
                        mode: _sidebarMode,
                        selectedIndex: _index,
                        destinations: _destinations,
                        onOpenStep: _stepOpen,
                        onCloseStep: _stepClose,
                        onCloseAll: () => _setMode(_SidebarMode.closed),
                        onSelect: (value) => setState(() => _index = value),
                      ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Semantics(
                      label: '${selected.label} page',
                      child: IndexedStack(
                        index: _index,
                        children: _destinations.map((item) => item.page).toList(growable: false),
                      ),
                    ),
                    if (isClosed)
                      Positioned(
                        top: 16,
                        left: 0,
                        child: Semantics(
                          button: true,
                          label: 'Open sidebar',
                          child: GestureDetector(
                            onTap: _stepOpen,
                            child: Container(
                              width: 20,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: const Center(
                                child: Icon(Icons.chevron_right_rounded, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!isClosed && !isExpanded)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Semantics(
                          button: true,
                          label: 'Expand sidebar',
                          child: IconButton(
                            onPressed: _stepOpen,
                            tooltip: 'Expand sidebar',
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final _SidebarMode mode;
  final int selectedIndex;
  final List<_ShellDestination> destinations;
  final VoidCallback onOpenStep;
  final VoidCallback onCloseStep;
  final VoidCallback onCloseAll;
  final ValueChanged<int> onSelect;

  const _Sidebar({
    required this.mode,
    required this.selectedIndex,
    required this.destinations,
    required this.onOpenStep,
    required this.onCloseStep,
    required this.onCloseAll,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = mode == _SidebarMode.expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: expanded ? Alignment.centerRight : Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(right: expanded ? 6 : 0),
                  child: Semantics(
                    button: true,
                    label: expanded ? 'Collapse to icons' : 'Expand sidebar',
                    child: IconButton(
                      onPressed: expanded ? onCloseStep : onOpenStep,
                      tooltip: expanded ? 'Collapse to icons' : 'Expand sidebar',
                      icon: Icon(expanded ? Icons.menu_open_rounded : Icons.menu_rounded),
                    ),
                  ),
                ),
              ),
            ),
            if (expanded)
              Semantics(
                button: true,
                label: 'Close sidebar completely',
                child: IconButton(
                  onPressed: onCloseAll,
                  tooltip: 'Close sidebar',
                  icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                ),
              ),
          ],
        ),
        if (expanded)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text(
              'Pages',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              final selected = index == selectedIndex;
              return _SidebarItem(
                expanded: expanded,
                selected: selected,
                destination: destination,
                onTap: () => onSelect(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final bool expanded;
  final bool selected;
  final _ShellDestination destination;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.expanded,
    required this.selected,
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 8, vertical: 4),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Open ${destination.label}',
        child: Tooltip(
          message: destination.label,
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: selected ? colorScheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 10),
              child: expanded
                  ? Row(
                      children: [
                        Icon(
                          destination.icon,
                          color: selected ? colorScheme.onPrimaryContainer : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            destination.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? colorScheme.onPrimaryContainer : null,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        destination.icon,
                        color: selected ? colorScheme.onPrimaryContainer : null,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  final String label;
  final IconData icon;
  final Widget page;

  const _ShellDestination(this.label, this.icon, this.page);
}

class _QuickAddPage extends StatelessWidget {
  const _QuickAddPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Add')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(leading: Icon(Icons.mosque_outlined), title: Text('Prayer Log')),
          ListTile(leading: Icon(Icons.receipt_long_outlined), title: Text('Expense')),
          ListTile(leading: Icon(Icons.repeat), title: Text('Habit Check-in')),
          ListTile(leading: Icon(Icons.event_note_outlined), title: Text('Todo/Event')),
        ],
      ),
    );
  }
}
