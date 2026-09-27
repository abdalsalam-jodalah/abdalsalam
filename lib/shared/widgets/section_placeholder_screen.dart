import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';
import 'ui/app_card.dart';
import 'ui/app_form_dialog.dart';
import 'ui/app_section_header.dart';
import 'ui/icon_badge.dart';
import 'ui/stat_grid.dart';
import 'ui/stat_tile.dart';
import 'empty_state.dart';

class SectionMetric {
  final String label;
  final String value;

  const SectionMetric({required this.label, required this.value});
}

class SectionPlaceholderScreen extends StatefulWidget {
  static const String defaultQuickAddHint = 'Add a new activity';

  final String title;
  final String description;
  final IconData icon;
  final List<SectionMetric> metrics;
  final List<String> focusItems;
  final List<String> initialActivities;
  final String quickAddHint;

  const SectionPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.metrics,
    required this.focusItems,
    required this.initialActivities,
    this.quickAddHint = defaultQuickAddHint,
  });

  @override
  State<SectionPlaceholderScreen> createState() => _SectionPlaceholderScreenState();
}

class _SectionPlaceholderScreenState extends State<SectionPlaceholderScreen> {
  static const String _metricsTitle = 'Quick Metrics';
  static const String _focusTitle = 'Today Focus';
  static const String _activityTitle = 'Recent Activity';
  static const String _emptyActivityTitle = 'No activity yet';
  static const String _emptyActivitySubtitle = 'Logged activity will show up here.';
  static const String _quickAddTitle = 'Quick Add';
  static const String _quickAddLabel = 'Add';
  static const String _quickAddButtonLabel = 'Quick Add Activity';
  static const IconData _metricIcon = Icons.insights_rounded;
  static const IconData _activityIcon = Icons.bolt_rounded;

  late final List<bool> _focusChecks;
  late final List<String> _activities;

  @override
  void initState() {
    super.initState();
    _focusChecks = List<bool>.filled(widget.focusItems.length, false);
    _activities = [...widget.initialActivities];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: widget.icon),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleLarge),
                      SizedBox(height: tokens.spacing.xs),
                      Text(
                        widget.description,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSectionHeader(title: _metricsTitle),
          StatGrid(
            children: [
              for (final metric in widget.metrics)
                StatTile(icon: _metricIcon, label: metric.label, value: metric.value),
            ],
          ),
          AppSectionHeader(title: _focusTitle),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(widget.focusItems.length, (index) {
                return CheckboxListTile(
                  value: _focusChecks[index],
                  title: Text(widget.focusItems[index]),
                  onChanged: (value) {
                    setState(() {
                      _focusChecks[index] = value ?? false;
                    });
                  },
                );
              }),
            ),
          ),
          AppSectionHeader(title: _activityTitle),
          if (_activities.isEmpty)
            EmptyState(title: _emptyActivityTitle, subtitle: _emptyActivitySubtitle, isCompact: true)
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _activities
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        leading: Icon(_activityIcon),
                        title: Text(entry),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          SizedBox(height: tokens.spacing.lg),
          FilledButton.icon(
            onPressed: _showQuickAddDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text(_quickAddButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickAddDialog() async {
    final controller = TextEditingController();

    final entry = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AppFormDialog(
          title: _quickAddTitle,
          submitLabel: _quickAddLabel,
          onSubmit: () => Navigator.of(dialogContext).pop(controller.text.trim()),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: widget.quickAddHint),
          ),
        );
      },
    );

    if (entry != null && entry.isNotEmpty && mounted) {
      setState(() {
        _activities.insert(0, entry);
      });
    }

    controller.dispose();
  }
}
