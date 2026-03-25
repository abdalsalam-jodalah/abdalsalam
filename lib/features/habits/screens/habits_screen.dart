import 'package:flutter/material.dart';

import 'habits_home_screen.dart';

class HabitsScreen extends StatelessWidget {
  static const routeName = '/habits';

  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HabitsHomeScreen();
  }
}
