import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/ui/glass_surface.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../financial/screens/financial_screen.dart';
import '../../food/screens/food_screen.dart';
import '../../habits/screens/habits_screen.dart';
import '../../health/screens/health_screen.dart';
import '../../health/screens/medication_list_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../planning/screens/day_planning_screen.dart';
import '../../planning/screens/goals_screen.dart';
import '../../planning/screens/planning_home_screen.dart';
import '../../religious/screens/religious_screen.dart';
import '../../security/screens/security_screen.dart';
import '../../settings/screens/settings_hub_screen.dart';
import '../../sleep/screens/sleep_screen.dart';
import '../../sports/screens/sports_screen.dart';
import '../widgets/quick_log_action.dart';
import '../widgets/quick_log_fab.dart';
import '../widgets/shell_destination.dart';
import '../widgets/shell_open_handle.dart';
import '../widgets/shell_sidebar.dart';
import '../widgets/shell_sidebar_reveal.dart';
import '../widgets/shell_sidebar_mode.dart';
import '../widgets/shell_swipe_detector.dart';
import '../widgets/sidebar_auto_close_timer.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  static const String _sidebarOrderSetting = 'sidebarOrder';
  static const double _closedWidth = 0;
  static const double _iconsWidth = 88;
  static const double _expandedWidth = 264;
  static const double _edgeSwipeZone = 28;
  static const double _closeSwipeZone = 56;
  static const double _largeScreenBreakpoint = 900;
  static const double _initialHandleTop = 140;
  static const double _handleBottomClearance = 76;
  static const double _scrimOpacity = 0.3;
  static const ValueKey<String> _sidebarSlotKey = ValueKey<String>('shell-sidebar-slot');
  static const ValueKey<String> _sidebarScrimKey = ValueKey<String>('shell-sidebar-scrim');
  static const ValueKey<String> _closeSwipeZoneKey = ValueKey<String>('shell-close-swipe-zone');
  static const ValueKey<String> _edgeSwipeZoneKey = ValueKey<String>('shell-edge-swipe-zone');
  static const ValueKey<String> _openHandleKey = ValueKey<String>('shell-open-handle');
  static const ValueKey<String> _logWheelScrimKey = ValueKey<String>('shell-log-wheel-scrim');
  static const ValueKey<String> _logFabKey = ValueKey<String>('shell-log-fab');

  static const _defaultDestinations = <ShellDestination>[
    ShellDestination('dashboard', 'Dashboard', Icons.space_dashboard_rounded, DashboardScreen()),
    ShellDestination('religious', 'Religious', Icons.mosque_rounded, ReligiousScreen()),
    ShellDestination('financial', 'Financial', Icons.account_balance_wallet_rounded, FinancialScreen()),
    ShellDestination('habits', 'Habits', Icons.repeat_rounded, HabitsScreen()),
    ShellDestination('planning', 'Life Planning', Icons.flag_rounded, PlanningHomeScreen()),
    ShellDestination('day-planning', 'Day Planning', Icons.today_rounded, DayPlanningScreen()),
    ShellDestination('sports', 'Sports', Icons.fitness_center_rounded, SportsScreen()),
    ShellDestination('health', 'Health', Icons.health_and_safety_rounded, HealthScreen()),
    ShellDestination('sleep', 'Sleep', Icons.bedtime_rounded, SleepScreen()),
    ShellDestination('food', 'Food', Icons.restaurant_rounded, FoodScreen()),
    ShellDestination('medications', 'Medications', Icons.medication_rounded, MedicationListScreen()),
    ShellDestination('notes', 'Notes', Icons.sticky_note_2_rounded, NotesScreen()),
    ShellDestination('calendar', 'Calendar', Icons.calendar_month_rounded, CalendarScreen()),
    ShellDestination('security', 'Security', Icons.lock_rounded, SecurityScreen()),
    ShellDestination('analytics', 'Analytics', Icons.insights_rounded, AnalyticsScreen()),
    ShellDestination('settings', 'Settings', Icons.settings_rounded, SettingsHubScreen()),
  ];

  static const _logActions = <QuickLogAction>[
    QuickLogAction(label: 'Prayer', icon: Icons.mosque_rounded, routeName: '/religious/prayer-log', moduleKey: 'religious'),
    QuickLogAction(label: 'Quran', icon: Icons.menu_book_rounded, routeName: '/religious/quran-reading', moduleKey: 'religious'),
    QuickLogAction(label: 'Finance', icon: Icons.receipt_long_rounded, routeName: '/financial/transaction-form', moduleKey: 'financial'),
    QuickLogAction(label: 'Habit', icon: Icons.repeat_rounded, routeName: '/habits/form', moduleKey: 'habits'),
    QuickLogAction(label: 'Goal', icon: Icons.flag_rounded, routeName: GoalsScreen.routeName, moduleKey: 'planning'),
    QuickLogAction(label: 'Medication', icon: Icons.medication_rounded, routeName: '/health/medication-form', moduleKey: 'medications'),
    QuickLogAction(label: 'Event', icon: Icons.event_note_rounded, routeName: '/calendar/new-event', moduleKey: 'calendar'),
  ];

  int _index = 0;
  late List<ShellDestination> _destinations;
  ShellSidebarMode _sidebarMode = ShellSidebarMode.icons;
  ShellSidebarMode _lastOpenMode = ShellSidebarMode.icons;
  bool _slidesFromEdge = true;
  double _openHandleTop = _initialHandleTop;
  bool _isLogWheelOpen = false;
  int _logWheelIndex = 0;
  double _logWheelTurnCarry = 0;

  late final SidebarAutoCloseTimer _autoCloseTimer = SidebarAutoCloseTimer(onTimeout: _closeAfterInactivity);

  @override
  void initState() {
    super.initState();
    _destinations = _resolveOrder(ref.read(initialSidebarOrderProvider));
    _autoCloseTimer.start();
  }

  @override
  void dispose() {
    _autoCloseTimer.dispose();
    super.dispose();
  }

  void _closeAfterInactivity() {
    if (mounted && _sidebarMode != ShellSidebarMode.closed) {
      _setMode(ShellSidebarMode.closed);
    }
  }

  void _applySavedSettings(Map<String, dynamic> settings) {
    _applySavedOrder(settings[_sidebarOrderSetting]);
    _autoCloseTimer.configure(SidebarAutoCloseTimer.durationFromSetting(settings[SidebarAutoCloseTimer.settingKey]));
  }

  List<ShellDestination> _resolveOrder(List<String>? savedOrder) {
    if (savedOrder == null || savedOrder.isEmpty) {
      return List.of(_defaultDestinations);
    }
    final destinationsByKey = {for (final destination in _defaultDestinations) destination.key: destination};
    return <ShellDestination>[
      for (final key in savedOrder)
        if (destinationsByKey.containsKey(key)) destinationsByKey[key]!,
      for (final destination in _defaultDestinations)
        if (!savedOrder.contains(destination.key)) destination,
    ];
  }

  void _applySavedOrder(Object? savedOrder) {
    if (savedOrder is! List) {
      return;
    }
    final order = savedOrder.whereType<String>().toList(growable: false);
    final currentOrder = _destinations.map((destination) => destination.key).toList(growable: false);
    if (order.join(',') == currentOrder.join(',')) {
      return;
    }
    final selectedKey = _destinations[_index].key;
    setState(() {
      _destinations = _resolveOrder(order);
      _index = math.max(0, _destinations.indexWhere((destination) => destination.key == selectedKey));
    });
  }

  void _reorderDestinations(int oldIndex, int newIndex) {
    final selectedKey = _destinations[_index].key;
    setState(() {
      final destination = _destinations.removeAt(oldIndex);
      _destinations.insert(newIndex, destination);
      _index = _destinations.indexWhere((item) => item.key == selectedKey);
    });
    final newOrder = _destinations.map((destination) => destination.key).toList();
    unawaited(ref.read(settingsServiceProvider).updateSetting(_sidebarOrderSetting, newOrder).then(
      (_) => ref.read(loggerProvider).info('Sidebar order saved: $newOrder'),
      onError: (Object error, StackTrace stackTrace) => ref.read(loggerProvider).error(
            'Failed to save sidebar order',
            error: error,
            stackTrace: stackTrace,
          ),
    ));
  }

  double get _sidebarWidth => switch (_sidebarMode) {
        ShellSidebarMode.closed => _closedWidth,
        ShellSidebarMode.icons => _iconsWidth,
        ShellSidebarMode.expanded => _expandedWidth,
      };

  double get _panelWidth => _lastOpenMode == ShellSidebarMode.expanded ? _expandedWidth : _iconsWidth;

  void _setMode(ShellSidebarMode mode) {
    final touchesEdge = mode == ShellSidebarMode.closed || _sidebarMode == ShellSidebarMode.closed;
    setState(() {
      _slidesFromEdge = touchesEdge;
      _sidebarMode = mode;
      if (mode != ShellSidebarMode.closed) {
        _lastOpenMode = mode;
      }
    });
    if (mode == ShellSidebarMode.closed) {
      _autoCloseTimer.stop();
    } else {
      _autoCloseTimer.start();
    }
  }

  void _resetLogWheel() {
    _isLogWheelOpen = false;
    _logWheelIndex = 0;
    _logWheelTurnCarry = 0;
  }

  void _toggleLogWheel() {
    setState(() {
      if (_isLogWheelOpen) {
        _resetLogWheel();
      } else {
        _isLogWheelOpen = true;
      }
    });
  }

  Future<void> _openLogRoute(String routeName) async {
    setState(_resetLogWheel);
    await Navigator.of(context).pushNamed(routeName);
  }

  void _stepLogWheel(int step) {
    final maxIndex = math.max(0, _logActions.length - QuickLogFab.visibleSlots);
    setState(() => _logWheelIndex = (_logWheelIndex + step).clamp(0, maxIndex));
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
    switch (_sidebarMode) {
      case ShellSidebarMode.closed:
        _setMode(ShellSidebarMode.icons);
      case ShellSidebarMode.icons:
        _setMode(ShellSidebarMode.expanded);
      case ShellSidebarMode.expanded:
        break;
    }
  }

  void _stepClose() {
    if (_sidebarMode == ShellSidebarMode.expanded) {
      _setMode(ShellSidebarMode.icons);
    } else if (_sidebarMode == ShellSidebarMode.icons) {
      _setMode(ShellSidebarMode.closed);
    }
  }

  Widget _buildEdgeSwipeZone() {
    return Positioned(
      key: _edgeSwipeZoneKey,
      left: 0,
      top: 0,
      bottom: 0,
      width: _edgeSwipeZone,
      child: ShellSwipeDetector(onSwipeOpen: _stepOpen),
    );
  }

  Widget _buildCloseSwipeZone({required double left}) {
    return Positioned(
      key: _closeSwipeZoneKey,
      left: left,
      top: 0,
      bottom: 0,
      width: _closeSwipeZone,
      child: ShellSwipeDetector(onSwipeClose: _stepClose),
    );
  }

  Widget _buildOpenHandle(double minTop, double maxTop) {
    return Positioned(
      key: _openHandleKey,
      top: _openHandleTop.clamp(minTop, maxTop),
      left: 0,
      child: ShellOpenHandle(
        onOpen: _stepOpen,
        onVerticalDrag: (delta) => setState(() => _openHandleTop = (_openHandleTop + delta).clamp(minTop, maxTop)),
      ),
    );
  }

  Widget _buildSidebarPanel(AppThemeTokens tokens) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _autoCloseTimer.touch(),
      onPointerMove: (_) => _autoCloseTimer.touch(),
      child: ShellSwipeDetector(
        onSwipeOpen: _stepOpen,
        onSwipeClose: _stepClose,
        child: GlassSurface(
          isBlurred: true,
          borderRadius: tokens.radius.extraLargeBorder,
          child: ShellSidebar(
            mode: _sidebarMode,
            selectedIndex: _index,
            destinations: _destinations,
            onOpenStep: _stepOpen,
            onCloseStep: _stepClose,
            onCloseAll: () => _setMode(ShellSidebarMode.closed),
            onSelect: (value) => setState(() => _index = value),
            onReorder: _reorderDestinations,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSlot(AppThemeTokens tokens) {
    return ShellSidebarReveal(
      visibleWidth: _sidebarWidth,
      panelWidth: _panelWidth,
      slidesFromEdge: _slidesFromEdge,
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.sm),
        child: _buildSidebarPanel(tokens),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appSettingsProvider, (_, next) => next.whenData(_applySavedSettings));
    final tokens = AppThemeTokens.of(context);
    final selected = _destinations[_index];
    final sidebarWidth = _sidebarWidth;
    final isClosed = _sidebarMode == ShellSidebarMode.closed;
    final isIcons = _sidebarMode == ShellSidebarMode.icons;
    final isExpanded = _sidebarMode == ShellSidebarMode.expanded;

    final content = Semantics(
      label: '${selected.label} page',
      child: IndexedStack(
        index: _index,
        children: _destinations.map((item) => item.page).toList(growable: false),
      ),
    );

    final logWheelScrim = _isLogWheelOpen
        ? Positioned.fill(
            key: _logWheelScrimKey,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(_resetLogWheel),
              child: const SizedBox.expand(),
            ),
          )
        : null;

    final logFab = selected.key == 'dashboard'
        ? Positioned(
            key: _logFabKey,
            right: tokens.spacing.lg,
            bottom: tokens.spacing.lg,
            child: QuickLogFab(
              isOpen: _isLogWheelOpen,
              actions: _logActions,
              startIndex: _logWheelIndex,
              onTurnDelta: _turnLogWheel,
              onToggle: _toggleLogWheel,
              onActionTap: _openLogRoute,
            ),
          )
        : null;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minTop = tokens.spacing.md;
            final maxTop = (constraints.maxHeight - _handleBottomClearance).clamp(minTop, double.infinity);
            if (constraints.maxWidth >= _largeScreenBreakpoint) {
              return Row(
                children: [
                  _buildSidebarSlot(tokens),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: content),
                        if (isIcons) _buildCloseSwipeZone(left: 0),
                        if (isClosed) _buildEdgeSwipeZone(),
                        if (isClosed) _buildOpenHandle(minTop, maxTop),
                        ?logWheelScrim,
                        ?logFab,
                      ],
                    ),
                  ),
                ],
              );
            }
            return Stack(
              children: [
                Positioned.fill(child: content),
                if (isExpanded)
                  Positioned.fill(
                    key: _sidebarScrimKey,
                    child: ShellSwipeDetector(
                      onSwipeClose: _stepClose,
                      child: GestureDetector(
                        onTap: () => _setMode(ShellSidebarMode.icons),
                        child: ColoredBox(color: Theme.of(context).colorScheme.scrim.withValues(alpha: _scrimOpacity)),
                      ),
                    ),
                  ),
                Positioned(
                  key: _sidebarSlotKey,
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildSidebarSlot(tokens),
                ),
                if (isIcons) _buildCloseSwipeZone(left: sidebarWidth),
                if (isClosed) _buildEdgeSwipeZone(),
                if (isClosed) _buildOpenHandle(minTop, maxTop),
                ?logWheelScrim,
                ?logFab,
              ],
            );
          },
        ),
      ),
    );
  }
}
