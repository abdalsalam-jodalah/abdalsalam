import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
  double _openHandleTop = 140;
  bool _logWheelOpen = false;
  int _logWheelIndex = 0;
  double _logWheelTurnCarry = 0;

  static const double _closedWidth = 0;
  static const double _iconsWidth = 84;
  static const double _expandedWidth = 260;
  static const double _dragThreshold = 56;
  static const double _edgeSwipeZone = 28;

  static const _destinations = <_ShellDestination>[
    _ShellDestination('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
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

  static const _logActions = <_LogAction>[
    _LogAction(label: 'Prayer', icon: Icons.mosque_outlined, routeName: '/religious/prayer-log'),
    _LogAction(label: 'Quran', icon: Icons.menu_book_outlined, routeName: '/religious/quran-reading'),
    _LogAction(label: 'Finance', icon: Icons.receipt_long_outlined, routeName: '/financial/transaction-form'),
    _LogAction(label: 'Habit', icon: Icons.repeat_rounded, routeName: '/habits/form'),
    _LogAction(label: 'Medication', icon: Icons.medication_outlined, routeName: '/health/medication-form'),
    _LogAction(label: 'Event', icon: Icons.event_note_outlined, routeName: '/calendar/new-event'),
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

  void _toggleLogWheel() {
    setState(() {
      _logWheelOpen = !_logWheelOpen;
      if (!_logWheelOpen) {
        _logWheelIndex = 0;
        _logWheelTurnCarry = 0;
      }
    });
  }

  Future<void> _openLogRoute(String routeName) async {
    setState(() {
      _logWheelOpen = false;
      _logWheelIndex = 0;
      _logWheelTurnCarry = 0;
    });
    await Navigator.of(context).pushNamed(routeName);
  }

  void _stepLogWheel(int step) {
    const visibleSlots = 4;
    final maxIndex = math.max(0, _logActions.length - visibleSlots);
    setState(() {
      _logWheelIndex = (_logWheelIndex + step).clamp(0, maxIndex);
    });
  }

  void _turnLogWheel(double rawTurnDelta) {
    _logWheelTurnCarry += rawTurnDelta;
    while (_logWheelTurnCarry >= 1.0) {
      _stepLogWheel(-1);
      _logWheelTurnCarry -= 1.0;
    }
    while (_logWheelTurnCarry <= -1.0) {
      _stepLogWheel(1);
      _logWheelTurnCarry += 1.0;
    }
  }

  void _stepOpen() {
    if (_sidebarMode != _SidebarMode.expanded) {
      _setMode(_SidebarMode.expanded);
    }
  }

  void _openIconsOnly() {
    if (_sidebarMode != _SidebarMode.icons) {
      _setMode(_SidebarMode.icons);
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
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutQuart,
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final minTop = 12.0;
                    final maxTop = (constraints.maxHeight - 76).clamp(minTop, double.infinity);
                    final handleTop = _openHandleTop.clamp(minTop, maxTop);

                    return Stack(
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
                            top: handleTop,
                            left: 0,
                            child: Semantics(
                              button: true,
                              label: 'Open sidebar',
                              child: GestureDetector(
                                onTap: _openIconsOnly,
                                onDoubleTap: _stepOpen,
                                onVerticalDragUpdate: (details) {
                                  setState(() {
                                    _openHandleTop =
                                        (_openHandleTop + details.delta.dy).clamp(minTop, maxTop);
                                  });
                                },
                                         onVerticalDragEnd: (_) {
                                           // Open sidebar on drag end
                                           _openIconsOnly();
                                         },
                                         onVerticalDragDown: (_) {
                                           // Optionally open sidebar on drag start
                                           // _openIconsOnly();
                                         },
                                         onPanEnd: (_) {
                                           // Fallback: open sidebar on any pan end
                                           //_openIconsOnly();
                                          },
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
                        if (_logWheelOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => setState(() {
                                _logWheelOpen = false;
                                _logWheelIndex = 0;
                                _logWheelTurnCarry = 0;
                              }),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _QuarterLogFab(
                            isOpen: _logWheelOpen,
                            actions: _logActions,
                            startIndex: _logWheelIndex,
                            onTurnDelta: _turnLogWheel,
                            onToggle: _toggleLogWheel,
                            onActionTap: _openLogRoute,
                          ),
                        ),
                      ],
                    );
                  },
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

class _LogAction {
  final String label;
  final IconData icon;
  final String routeName;

  const _LogAction({
    required this.label,
    required this.icon,
    required this.routeName,
  });
}

class _QuarterLogFab extends StatelessWidget {
  final bool isOpen;
  final List<_LogAction> actions;
  final int startIndex;
  final ValueChanged<double> onTurnDelta;
  final VoidCallback onToggle;
  final ValueChanged<String> onActionTap;

  const _QuarterLogFab({
    required this.isOpen,
    required this.actions,
    required this.startIndex,
    required this.onTurnDelta,
    required this.onToggle,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 106.0;
    const visibleSlots = 4;
    final colorScheme = Theme.of(context).colorScheme;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (!isOpen) {
          return;
        }
        if (event is PointerScrollEvent) {
          onTurnDelta(event.scrollDelta.dy / 20);
        }
      },
      child: GestureDetector(
        behavior: isOpen ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
        onPanUpdate: (details) {
          if (isOpen) {
            final turnDelta = _turnDeltaFromPan(details.delta);
            onTurnDelta(turnDelta);
          }
        },
        child: SizedBox(
          width: radius + 56,
          height: radius + 56,
          child: Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < actions.length; i++)
                _buildRadialAction(
                  context: context,
                  action: actions[i],
                  index: i,
                  radius: radius,
                  visibleSlots: visibleSlots,
                ),
              FloatingActionButton(
                onPressed: onToggle,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    if (isOpen) {
                      onTurnDelta(_turnDeltaFromPan(details.delta));
                    }
                  },
                  child: Icon(isOpen ? Icons.close : Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _turnDeltaFromPan(Offset delta) {
    return -(delta.dy + delta.dx) / 16;
  }

  Widget _buildRadialAction({
    required BuildContext context,
    required _LogAction action,
    required int index,
    required double radius,
    required int visibleSlots,
  }) {
    final slotPosition = index - startIndex;
    final isVisible = slotPosition >= 0 && slotPosition < visibleSlots;
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final t = visibleSlots <= 1 ? 0.0 : slotPosition / (visibleSlots - 1);
    final angle = math.pi + (math.pi / 2) * t;
    final distance = isOpen ? radius : 0.0;
    final dx = math.cos(angle) * distance;
    final dy = math.sin(angle) * distance;
    final fade = isOpen ? 1.0 : 0.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      right: 8 + (-dx),
      bottom: 8 + (-dy),
      child: IgnorePointer(
        ignoring: !isOpen,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: fade,
          child: Tooltip(
            message: action.label,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (details) {
                if (isOpen) {
                  onTurnDelta(_turnDeltaFromPan(details.delta));
                }
              },
              child: Material(
                elevation: 6,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onActionTap(action.routeName),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(action.icon),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
