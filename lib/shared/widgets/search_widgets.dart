import 'dart:async';

import 'package:flutter/material.dart';

class DebouncedSearchBar extends StatefulWidget {
  final ValueChanged<String> onQueryChanged;
  final String hint;

  const DebouncedSearchBar({
    super.key,
    required this.onQueryChanged,
    this.hint = 'Search',
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
        prefixIcon: const Icon(Icons.search),
      ),
      onChanged: (value) {
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 300), () {
          widget.onQueryChanged(value);
        });
      },
    );
  }
}

class HighlightedText extends StatelessWidget {
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

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(fontWeight: FontWeight.w700, backgroundColor: Color(0xFFFFFF99)),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

class FilterSheet extends StatelessWidget {
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
          const ListTile(title: Text('Filters')),
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
