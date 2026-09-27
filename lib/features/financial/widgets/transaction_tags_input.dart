import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class TransactionTagsInput extends StatelessWidget {
  static const String _hintText = 'Add a tag';
  static const String _addLabel = 'Add';

  final List<String> tags;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const TransactionTagsInput({
    super.key,
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty)
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              for (final tag in tags) Chip(label: Text(tag), onDeleted: () => onRemove(tag)),
            ],
          ),
        if (tags.isNotEmpty) SizedBox(height: spacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: _hintText),
              ),
            ),
            SizedBox(width: spacing.sm),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text(_addLabel),
            ),
          ],
        ),
      ],
    );
  }
}
