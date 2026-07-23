import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String preview;
  final VoidCallback? onTap;
  final Widget? trailing;

  const NoteCard({
    super.key,
    required this.title,
    required this.preview,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sticky_note_2_outlined),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: preview.isEmpty ? null : Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
        onTap: onTap,
      ),
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
    return CheckboxListTile(
      value: completed,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: completed ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
      ),
      secondary: trailing,
    );
  }
}

class RichTextEditorWidget extends StatefulWidget {
  const RichTextEditorWidget({super.key});

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
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
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: () => _wrapSelection('**', '**'), child: const Text('Bold')),
            OutlinedButton(onPressed: () => _wrapSelection('_', '_'), child: const Text('Italic')),
            OutlinedButton(onPressed: () => _wrapSelection('<u>', '</u>'), child: const Text('Underline')),
            OutlinedButton(onPressed: () => _prefixLine('- '), child: const Text('Bullets')),
            OutlinedButton(onPressed: () => _prefixLine('1. '), child: const Text('Numbered')),
            OutlinedButton(onPressed: () => _prefixLine('## '), child: const Text('Heading')),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
                hintText: 'Write your note with formatting...',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
