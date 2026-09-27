import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class TimelineView extends StatelessWidget {
  static const double _dotSize = 10;

  final List<Widget> items;

  const TimelineView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: tokens.spacing.sm),
      itemBuilder: (context, index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm),
            child: Icon(Icons.circle, size: _dotSize, color: accent),
          ),
          SizedBox(width: tokens.spacing.sm),
          Expanded(child: items[index]),
        ],
      ),
    );
  }
}

class SyncStatusIndicator extends StatelessWidget {
  static const double _iconSize = 18;

  final bool enabled;

  const SyncStatusIndicator({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(enabled ? Icons.sync : Icons.sync_disabled, size: _iconSize),
      label: Text(enabled ? 'Google Sync On' : 'Google Sync Off'),
    );
  }
}
