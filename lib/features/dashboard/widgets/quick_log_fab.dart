import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'quick_log_action.dart';

class QuickLogFab extends StatelessWidget {
  static const int visibleSlots = 4;
  static const double _radius = 106;
  static const double _areaPadding = 56;
  static const double _actionSize = 44;
  static const double _actionInset = 8;
  static const double _scrollTurnDivisor = 20;
  static const double _panTurnDivisor = 16;
  static const double _actionTintOpacity = 0.18;
  static const String _openLabel = 'Quick log';
  static const String _closeLabel = 'Close quick log';

  final bool isOpen;
  final List<QuickLogAction> actions;
  final int startIndex;
  final ValueChanged<double> onTurnDelta;
  final VoidCallback onToggle;
  final ValueChanged<String> onActionTap;

  const QuickLogFab({
    super.key,
    required this.isOpen,
    required this.actions,
    required this.startIndex,
    required this.onTurnDelta,
    required this.onToggle,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (isOpen && event is PointerScrollEvent) {
          onTurnDelta(event.scrollDelta.dy / _scrollTurnDivisor);
        }
      },
      child: GestureDetector(
        behavior: isOpen ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
        onPanUpdate: (details) {
          if (isOpen) {
            onTurnDelta(_turnDeltaFromPan(details.delta));
          }
        },
        child: SizedBox(
          width: _radius + _areaPadding,
          height: _radius + _areaPadding,
          child: Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < actions.length; i++) _buildRadialAction(context, actions[i], i),
              FloatingActionButton(
                onPressed: onToggle,
                tooltip: isOpen ? _closeLabel : _openLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    if (isOpen) {
                      onTurnDelta(_turnDeltaFromPan(details.delta));
                    }
                  },
                  child: AnimatedRotation(
                    turns: isOpen ? 0.125 : 0,
                    duration: AppMotion.fast,
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _turnDeltaFromPan(Offset delta) => -(delta.dy + delta.dx) / _panTurnDivisor;

  Widget _buildRadialAction(BuildContext context, QuickLogAction action, int index) {
    final slotPosition = index - startIndex;
    if (slotPosition < 0 || slotPosition >= visibleSlots) {
      return const SizedBox.shrink();
    }
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule(action.moduleKey);
    final fraction = slotPosition / (visibleSlots - 1);
    final angle = math.pi + (math.pi / 2) * fraction;
    final distance = isOpen ? _radius : 0.0;
    return AnimatedPositioned(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      right: _actionInset - math.cos(angle) * distance,
      bottom: _actionInset - math.sin(angle) * distance,
      child: IgnorePointer(
        ignoring: !isOpen,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: isOpen ? 1 : 0,
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
                color: Color.alphaBlend(accent.withValues(alpha: _actionTintOpacity), tokens.glass.surfaceTint),
                shape: CircleBorder(side: BorderSide(color: tokens.glass.borderColor)),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onActionTap(action.routeName),
                  child: SizedBox.square(dimension: _actionSize, child: Icon(action.icon, color: accent)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
