import 'package:flutter/material.dart';

import 'notes_home_screen.dart';

class NotesScreen extends StatelessWidget {
  static const routeName = '/notes';

  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotesHomeScreen();
  }
}
