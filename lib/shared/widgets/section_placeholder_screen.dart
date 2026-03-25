import 'package:flutter/material.dart';

class SectionMetric {
  final String label;
  final String value;

  const SectionMetric({required this.label, required this.value});
}

class SectionPlaceholderScreen extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<SectionMetric> metrics;
  final List<String> focusItems;
  final List<String> initialActivities;
  final String quickAddHint;

  const SectionPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.metrics,
    required this.focusItems,
    required this.initialActivities,
    this.quickAddHint = 'Add a new activity',
  });

  @override
  State<SectionPlaceholderScreen> createState() => _SectionPlaceholderScreenState();
}

class _SectionPlaceholderScreenState extends State<SectionPlaceholderScreen> {
  late final List<bool> _focusChecks;
  late final List<String> _activities;

  @override
  void initState() {
    super.initState();
    _focusChecks = List<bool>.filled(widget.focusItems.length, false);
    _activities = [...widget.initialActivities];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(widget.description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Quick Metrics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: widget.metrics.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final metric = widget.metrics[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        metric.value,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(metric.label),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Today Focus', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: List.generate(widget.focusItems.length, (index) {
                return CheckboxListTile(
                  value: _focusChecks[index],
                  title: Text(widget.focusItems[index]),
                  onChanged: (value) {
                    setState(() {
                      _focusChecks[index] = value ?? false;
                    });
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: _activities.isEmpty
                ? const ListTile(title: Text('No activity yet'))
                : Column(
                    children: _activities
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.bolt_outlined),
                            title: Text(entry),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showQuickAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('Quick Add Activity'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickAddDialog() async {
    final controller = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quick Add'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: widget.quickAddHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true && controller.text.trim().isNotEmpty && mounted) {
      setState(() {
        _activities.insert(0, controller.text.trim());
      });
    }

    controller.dispose();
  }
}
