import 'package:flutter/material.dart';

class HabitFormScreen extends StatefulWidget {
  static const routeName = '/habits/form';

  const HabitFormScreen({super.key});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  TimeOfDay? _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  String _frequency = 'Daily';
  String _category = 'Health';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g. Read Quran',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Habit name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                items: const ['Daily', 'Weekly', 'Custom']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _frequency = value ?? _frequency),
                decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target count',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Target count must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: const ['Health', 'Productivity', 'Learning', 'Spiritual', 'Social']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _category = value ?? _category),
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).dividerColor)),
                leading: const Icon(Icons.alarm_outlined),
                title: const Text('Reminder time'),
                subtitle: Text(_reminderTime == null ? 'Disabled' : _reminderTime!.format(context)),
                trailing: Switch(
                  value: _reminderTime != null,
                  onChanged: (enabled) {
                    setState(() {
                      _reminderTime = enabled ? (_reminderTime ?? const TimeOfDay(hour: 8, minute: 0)) : null;
                    });
                  },
                ),
                onTap: () async {
                  if (_reminderTime == null) {
                    return;
                  }
                  final picked = await showTimePicker(context: context, initialTime: _reminderTime!);
                  if (picked != null) {
                    setState(() => _reminderTime = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Habit saved')),
                    );
                    Navigator.of(context).maybePop();
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
