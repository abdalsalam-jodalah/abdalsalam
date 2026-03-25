import 'dart:async';

import 'package:flutter/material.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  static const routeName = '/sports/active';

  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _seconds += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Workout')),
      body: Center(
        child: Text(
          'Elapsed: ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
