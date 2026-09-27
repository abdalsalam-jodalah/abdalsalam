import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

class DebouncedSearchBar extends StatefulWidget {
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const String defaultHint = 'Search';

  final ValueChanged<String> onQueryChanged;
  final String hint;

  const DebouncedSearchBar({
    super.key,
    required this.onQueryChanged,
    this.hint = defaultHint,
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
      onChanged: (value) {
        _timer?.cancel();
        _timer = Timer(DebouncedSearchBar.debounceDelay, () {
          widget.onQueryChanged(value);
        });
      },
    );
  }
}

class HighlightedText extends StatelessWidget {
  static const double _highlightOpacity = 0.45;

  final String text;
  final String query;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);
    if (index == -1) {
      return Text(text);
    }

    final tokens = AppThemeTokens.of(context);
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: DefaultTextStyle.of(context).style.copyWith(
                  fontWeight: FontWeight.w700,
                  backgroundColor: tokens.colors.warning.withValues(alpha: _highlightOpacity),
                ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

class FilterSheet extends StatelessWidget {
  static const String _title = 'Filters';

  final List<String> statuses;
  final ValueChanged<String> onStatusSelected;

  const FilterSheet({
    super.key,
    required this.statuses,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text(_title)),
          for (final status in statuses)
            ListTile(
              title: Text(status),
              onTap: () {
                onStatusSelected(status);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
