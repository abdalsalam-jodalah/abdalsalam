// lib/features/financial/widgets/financial_icon_option_picker.dart: icon option picker for category and account forms.
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';

class FinancialIconOptionPicker extends StatefulWidget {
  static const double _tileSize = 44;

  final List<IconData> options;
  final IconData selected;
  final Color accentColor;
  final ValueChanged<IconData> onSelected;
  final int? collapsedCount;

  const FinancialIconOptionPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.accentColor,
    required this.onSelected,
    this.collapsedCount,
  });

  static ValueKey<int> tileKeyFor(IconData icon) => ValueKey<int>(icon.codePoint);

  @override
  State<FinancialIconOptionPicker> createState() => _FinancialIconOptionPickerState();
}

class _FinancialIconOptionPickerState extends State<FinancialIconOptionPicker> {
  late bool _isExpanded;

  bool get _canCollapse {
    final collapsedCount = widget.collapsedCount;
    return collapsedCount != null && widget.options.length > collapsedCount;
  }

  @override
  void initState() {
    super.initState();
    final collapsedCount = widget.collapsedCount;
    _isExpanded = !_canCollapse || widget.options.indexOf(widget.selected) >= collapsedCount!;
  }

  List<IconData> get _visibleOptions {
    if (_isExpanded || !_canCollapse) {
      return widget.options;
    }
    return widget.options.take(widget.collapsedCount!).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: [
              for (final icon in _visibleOptions)
                Semantics(
                  button: true,
                  selected: icon == widget.selected,
                  child: InkWell(
                    key: FinancialIconOptionPicker.tileKeyFor(icon),
                    borderRadius: tokens.radius.mediumBorder,
                    onTap: () => widget.onSelected(icon),
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      width: FinancialIconOptionPicker._tileSize,
                      height: FinancialIconOptionPicker._tileSize,
                      decoration: BoxDecoration(
                        color: icon == widget.selected
                            ? widget.accentColor.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: tokens.radius.mediumBorder,
                        border: Border.all(color: icon == widget.selected ? widget.accentColor : Colors.transparent),
                      ),
                      child: Icon(
                        icon,
                        color: icon == widget.selected ? widget.accentColor : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_canCollapse)
          TextButton.icon(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: Text(_isExpanded ? 'Show fewer icons' : 'Show all ${widget.options.length} icons'),
          ),
      ],
    );
  }
}
