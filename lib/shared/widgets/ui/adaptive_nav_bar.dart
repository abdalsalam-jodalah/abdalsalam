import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'module_hub_destination.dart';

class AdaptiveNavBar extends StatelessWidget {
  final List<ModuleHubDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdaptiveNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).navigationBarTheme.labelTextStyle?.resolve(<WidgetState>{}) ??
        Theme.of(context).textTheme.labelSmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < destinations.length; i++)
          Expanded(
            child: _NavDestinationTile(
              destination: destinations[i],
              isSelected: i == selectedIndex,
              indicatorColor: scheme.primaryContainer,
              onSurfaceColor: scheme.onSurfaceVariant,
              onIndicatorColor: scheme.onPrimaryContainer,
              labelStyle: labelStyle,
              tokens: tokens,
              onTap: () => onDestinationSelected(i),
            ),
          ),
      ],
    );
  }
}

class _NavDestinationTile extends StatelessWidget {
  final ModuleHubDestination destination;
  final bool isSelected;
  final Color indicatorColor;
  final Color onSurfaceColor;
  final Color onIndicatorColor;
  final TextStyle? labelStyle;
  final AppThemeTokens tokens;
  final VoidCallback onTap;

  const _NavDestinationTile({
    required this.destination,
    required this.isSelected,
    required this.indicatorColor,
    required this.onSurfaceColor,
    required this.onIndicatorColor,
    required this.labelStyle,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? onIndicatorColor : onSurfaceColor;
    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: tokens.radius.pillBorder,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg, vertical: tokens.spacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected ? indicatorColor : Colors.transparent,
                    borderRadius: tokens.radius.pillBorder,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: iconColor),
                    child: Icon(isSelected ? destination.selectedIcon : destination.icon),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: isSelected
                      ? Padding(
                          padding: EdgeInsets.only(top: tokens.spacing.xs),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              destination.label,
                              maxLines: 1,
                              softWrap: false,
                              style: labelStyle?.copyWith(color: onSurfaceColor),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
