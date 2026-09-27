import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

const Map<String, int> _kNoteColorValues = <String, int>{
  'yellow': 0xFFFFF59D,
  'blue': 0xFF90CAF9,
  'green': 0xFFA5D6A7,
  'pink': 0xFFF48FB1,
};

/// Resolves a note's named colour key (from user-chosen note data or the
/// `notesDefaultColor` setting) into the accent colour rendered on its card.
Color? noteColorFromKey(String? key) {
  final value = _kNoteColorValues[key];
  return value == null ? null : Color(value);
}

class NoteCard extends StatelessWidget {
  static const IconData _icon = Icons.sticky_note_2_outlined;

  final String title;
  final String preview;
  final Color? accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const NoteCard({
    super.key,
    required this.title,
    required this.preview,
    this.accentColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return EntityTile(
      title: title,
      subtitle: preview.isEmpty ? null : preview,
      icon: _icon,
      accentColor: accentColor,
      onTap: onTap,
      trailing: trailing,
    );
  }
}

class TodoItem extends StatelessWidget {
  final String title;
  final bool completed;
  final ValueChanged<bool?>? onChanged;
  final Widget? trailing;

  const TodoItem({
    super.key,
    required this.title,
    required this.completed,
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final titleStyle = completed
        ? theme.textTheme.bodyLarge?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.onSurfaceVariant,
          )
        : theme.textTheme.bodyLarge;
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg, vertical: tokens.spacing.sm),
      onTap: onChanged == null ? null : () => onChanged!(!completed),
      child: Row(
        children: [
          Checkbox(value: completed, onChanged: onChanged),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
          ),
          if (trailing != null) ...[SizedBox(width: tokens.spacing.sm), trailing!],
        ],
      ),
    );
  }
}

class RichTextEditorWidget extends StatefulWidget {
  const RichTextEditorWidget({super.key});

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  static const String _boldLabel = 'Bold';
  static const String _italicLabel = 'Italic';
  static const String _underlineLabel = 'Underline';
  static const String _bulletsLabel = 'Bullets';
  static const String _numberedLabel = 'Numbered';
  static const String _headingLabel = 'Heading';
  static const String _hintText = 'Write your note with formatting...';

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid || selection.start < 0 || selection.end > text.length) {
      return;
    }

    final selected = selection.textInside(text);
    final replaced = '$prefix$selected$suffix';
    final newText = selection.textBefore(text) + replaced + selection.textAfter(text);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + replaced.length,
      ),
    );
  }

  void _prefixLine(String prefix) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid || selection.start < 0 || selection.start > text.length) {
      return;
    }

    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final newText = text.substring(0, lineStart) + prefix + text.substring(lineStart);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Column(
      children: [
        Wrap(
          spacing: tokens.spacing.sm,
          runSpacing: tokens.spacing.sm,
          children: [
            OutlinedButton(onPressed: () => _wrapSelection('**', '**'), child: const Text(_boldLabel)),
            OutlinedButton(onPressed: () => _wrapSelection('_', '_'), child: const Text(_italicLabel)),
            OutlinedButton(onPressed: () => _wrapSelection('<u>', '</u>'), child: const Text(_underlineLabel)),
            OutlinedButton(onPressed: () => _prefixLine('- '), child: const Text(_bulletsLabel)),
            OutlinedButton(onPressed: () => _prefixLine('1. '), child: const Text(_numberedLabel)),
            OutlinedButton(onPressed: () => _prefixLine('## '), child: const Text(_headingLabel)),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(tokens.spacing.md),
              hintText: _hintText,
            ),
          ),
        ),
      ],
    );
  }
}
