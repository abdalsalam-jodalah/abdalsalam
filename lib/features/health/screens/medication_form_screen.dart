import 'package:flutter/material.dart';

class MedicationFormScreen extends StatefulWidget {
  static const routeName = '/health/medication-form';

  const MedicationFormScreen({super.key});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _prescribedByController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime? _refillDate;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  String _frequency = 'Daily';

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _prescribedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication name',
                  hintText: 'e.g. Vitamin D3',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Medication name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g. 1000 IU',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Dosage is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                items: const ['Daily', 'Twice Daily', 'Weekly', 'Custom']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _frequency = value ?? _frequency),
                decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Start Date',
                date: _startDate,
                onPick: (date) => setState(() => _startDate = date),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: 'End Date (optional)',
                date: _endDate,
                onPick: (date) => setState(() => _endDate = date),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: 'Refill Date (optional)',
                date: _refillDate,
                onPick: (date) => setState(() => _refillDate = date),
              ),
              const SizedBox(height: 12),
              Text('Reminder Times', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _times.length; i++)
                    InputChip(
                      label: Text(_times[i].format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _times[i]);
                        if (picked != null) {
                          setState(() => _times[i] = picked);
                        }
                      },
                      onDeleted: _times.length == 1 ? null : () => setState(() => _times.removeAt(i)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_alarm_outlined),
                    label: const Text('Add Time'),
                    onPressed: () => setState(() => _times.add(const TimeOfDay(hour: 12, minute: 0))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prescribedByController,
                decoration: const InputDecoration(
                  labelText: 'Prescribed By (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medication saved')),
                    );
                    Navigator.of(context).maybePop();
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _DateField({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? 'Not set'
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(label),
      subtitle: Text(text),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
    );
  }
}
