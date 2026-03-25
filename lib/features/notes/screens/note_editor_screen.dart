import 'package:flutter/material.dart';

import '../widgets/notes_widgets.dart';

class NoteEditorScreen extends StatelessWidget {
  static const routeName = '/notes/editor';

  const NoteEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Note Editor')),
      body: const Padding(
        padding: EdgeInsets.all(12),
        child: RichTextEditorWidget(),
      ),
    );
  }
}
