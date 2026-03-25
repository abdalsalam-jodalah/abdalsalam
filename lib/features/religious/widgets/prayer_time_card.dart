import 'package:flutter/material.dart';

class PrayerTimeCard extends StatelessWidget {
  final String prayerName;
  final DateTime time;

  const PrayerTimeCard({
    super.key,
    required this.prayerName,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(prayerName),
        subtitle: Text(TimeOfDay.fromDateTime(time).format(context)),
      ),
    );
  }
}
