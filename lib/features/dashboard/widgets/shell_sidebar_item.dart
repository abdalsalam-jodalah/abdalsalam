import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'shell_destination.dart';

class ShellSidebarItem extends StatelessWidget {
  static const double _minHeight = 48;
  static const double _selectedOpacity = 0.16;
  static const Duration _tooltipWait = Duration(milliseconds: 400);

  final bool isExpanded;
  final bool isSelected;
  final ShellDestination destination;
  final VoidCallback onTap;

  const ShellSidebarItem({
    super.key,
    required this.isExpanded,
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
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? tokens.spacing.md : 0),
              child: isExpanded
                  ? Row(
                      children: [
                        Icon(destination.icon, color: iconColor),
                        SizedBox(width: tokens.spacing.md),
                        Expanded(
                          child: Text(
                            destination.label,
                            overflow: TextOverflow.ellipsis,
                            style: (isSelected ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
                                ?.copyWith(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    )
                  : Center(child: Icon(destination.icon, color: iconColor)),
            ),
          ),
        ),
      ),
    );
  }
}
