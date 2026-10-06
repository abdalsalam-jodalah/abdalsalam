import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../services/dashboard_greeting_icon.dart';
import 'dashboard_greeting.dart';
import 'dashboard_status_chips.dart';

class DashboardHero extends StatelessWidget {
  static const double _wideBreakpoint = 640;
  static const double _iconSize = 52;
  static const double _tintOpacity = 0.14;

  final DateTime now;

  const DashboardHero({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final greeting = Row(
      children: [
        Container(
          width: _iconSize,
          height: _iconSize,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: _tintOpacity),
            borderRadius: tokens.radius.largeBorder,
          ),
          child: Icon(DashboardGreetingIcon.forTime(now), color: colors.primary),
        ),
        SizedBox(width: tokens.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DashboardGreeting.forTime(now),
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                AppDateFormatter.date(now),
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _wideBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Expanded(child: greeting), const DashboardStatusChips()],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [greeting, SizedBox(height: tokens.spacing.md), const DashboardStatusChips()],
          );
        },
      ),
    );
  }
}
