import 'package:flutter/material.dart';

import 'quran_progress_screen.dart';

class QuranReadingScreen extends StatelessWidget {
  static const routeName = '/religious/quran-reading';

  const QuranReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuranProgressScreen();
  }
}
