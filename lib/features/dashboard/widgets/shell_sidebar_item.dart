import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'shell_destination.dart';
import 'shell_sidebar_metrics.dart';

class ShellSidebarItem extends StatelessWidget {
  static const double _minHeight = 48;
  static const double _selectedOpacity = 0.16;
  static const Duration _tooltipWait = Duration(milliseconds: 400);

  final double expandProgress;
  final bool isSelected;
  final ShellDestination destination;
  final VoidCallback onTap;

  const ShellSidebarItem({
    super.key,
    required this.expandProgress,
    required this.isSelected,
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = AppModuleAccents.forModule(destination.key);
    final iconColor = isSelected ? accent : theme.colorScheme.onSurfaceVariant;
    final iconSlotWidth = ShellSidebarMetrics.iconsWidth - 4 * tokens.spacing.sm;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm, vertical: tokens.spacing.xs / 2),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Open ${destination.label}',
        child: Tooltip(
          message: destination.label,
          waitDuration: _tooltipWait,
          triggerMode: TooltipTriggerMode.manual,
          child: InkWell(
            onTap: onTap,
            borderRadius: tokens.radius.mediumBorder,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              constraints: const BoxConstraints(minHeight: _minHeight),
              decoration: BoxDecoration(
                color: isSelected ? accent.withValues(alpha: _selectedOpacity) : Colors.transparent,
                borderRadius: tokens.radius.mediumBorder,
              ),
              child: ClipRect(
                child: Row(
                  children: [
                    SizedBox(width: iconSlotWidth, child: Center(child: Icon(destination.icon, color: iconColor))),
                    Expanded(
                      child: Opacity(
                        opacity: expandProgress,
                        child: Padding(
                          padding: EdgeInsets.only(right: tokens.spacing.md),
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: (isSelected ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
                                ?.copyWith(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
