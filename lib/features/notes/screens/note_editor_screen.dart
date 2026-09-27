import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../widgets/notes_widgets.dart';

class NoteEditorScreen extends StatelessWidget {
  static const routeName = '/notes/editor';

  const NoteEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Note Editor')),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: const RichTextEditorWidget(),
      ),
    );
  }
}
