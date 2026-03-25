import 'package:flutter/material.dart';

class QuranProgressChart extends StatelessWidget {
  final int totalAyahsRead;
  final int surahsCompleted;

  const QuranProgressChart({
    super.key,
    required this.totalAyahsRead,
    required this.surahsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total ayahs read: $totalAyahsRead'),
            const SizedBox(height: 6),
            Text('Surahs completed: $surahsCompleted'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (surahsCompleted / 114).clamp(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
