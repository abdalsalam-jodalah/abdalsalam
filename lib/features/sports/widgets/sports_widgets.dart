import 'dart:async';

import 'package:flutter/material.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class RestTimer extends StatefulWidget {
  final int seconds;

  const RestTimer({super.key, this.seconds = 60});

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  Timer? _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }
      if (_remaining <= 0) {
        timer.cancel();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.timer_outlined),
      label: Text('Rest: ${_remaining}s'),
    );
  }
}

class ProgressChart extends StatelessWidget {
  final List<double> points;

  const ProgressChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Progress points: ${points.length}'),
      ),
    );
  }
}

class PRBadge extends StatelessWidget {
  final String label;

  const PRBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.emoji_events_outlined),
      label: Text(label),
    );
  }
}
