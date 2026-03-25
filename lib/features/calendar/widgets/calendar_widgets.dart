import 'package:flutter/material.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime selectedMonth;
  final Set<DateTime> daysWithEvents;
  final ValueChanged<DateTime> onDaySelected;

  const CalendarGrid({
    super.key,
    required this.selectedMonth,
    required this.daysWithEvents,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final days = List<DateTime>.generate(
      end.day,
      (index) => DateTime(selectedMonth.year, selectedMonth.month, index + 1),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        final hasEvent = daysWithEvents
            .any((item) => item.year == day.year && item.month == day.month && item.day == day.day);
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onDaySelected(day),
          child: Container(
            decoration: BoxDecoration(
              color: hasEvent ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('${day.day}'),
          ),
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const EventCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(time),
      ),
    );
  }
}

class TimelineView extends StatelessWidget {
  final List<Widget> items;

  const TimelineView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(Icons.circle, size: 10),
          ),
          const SizedBox(width: 10),
          Expanded(child: items[index]),
        ],
      ),
    );
  }
}

class SyncStatusIndicator extends StatelessWidget {
  final bool enabled;

  const SyncStatusIndicator({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(enabled ? Icons.sync : Icons.sync_disabled, size: 18),
      label: Text(enabled ? 'Google Sync On' : 'Google Sync Off'),
    );
  }
}
