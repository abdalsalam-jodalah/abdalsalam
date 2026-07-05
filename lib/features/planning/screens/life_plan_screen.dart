import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/life_plan.dart';
import '../providers/planning_providers.dart';

class LifePlanScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/life-plan';

  const LifePlanScreen({super.key});

  @override
  ConsumerState<LifePlanScreen> createState() => _LifePlanScreenState();
}

class _LifePlanScreenState extends ConsumerState<LifePlanScreen> {
  final _uuid = const Uuid();
  final _visionController = TextEditingController();
  final _missionController = TextEditingController();
  final _valueController = TextEditingController();
  final _principleController = TextEditingController();
  List<String> _values = [];
  List<String> _principles = [];
  LifePlan? _existingPlan;
  bool _loaded = false;

  @override
  void dispose() {
    _visionController.dispose();
    _missionController.dispose();
    _valueController.dispose();
    _principleController.dispose();
    super.dispose();
  }

  void _loadFrom(LifePlan? plan) {
    if (_loaded) {
      return;
    }
    _loaded = true;
    _existingPlan = plan;
    _visionController.text = plan?.visionStatement ?? '';
    _missionController.text = plan?.missionStatement ?? '';
    _values = [...?plan?.values];
    _principles = [...?plan?.principles];
  }

  Future<void> _save() async {
    final repo = ref.read(lifePlanRepositoryProvider);
    final now = DateTime.now();

    final plan = LifePlan(
      id: _existingPlan?.id ?? _uuid.v4(),
      createdAt: _existingPlan?.createdAt ?? now,
      updatedAt: now,
      userId: planningUserId,
      visionStatement: _visionController.text.trim(),
      missionStatement: _missionController.text.trim(),
      values: _values,
      principles: _principles,
    );

    final result = _existingPlan == null ? await repo.create(plan) : await repo.update(plan);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? 'Life plan saved' : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
    if (result.isSuccess) {
      _existingPlan = plan;
      ref.invalidate(lifePlanProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lifePlanAsync = ref.watch(lifePlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Life Plan')),
      body: lifePlanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Failed to load life plan')),
        data: (plan) {
          _loadFrom(plan);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _visionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Vision',
                  hintText: 'Who do you want to become?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _missionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mission',
                  hintText: 'What is your purpose day to day?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Values', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _ChipEditor(
                controller: _valueController,
                items: _values,
                hintText: 'Add a value',
                onAdd: (value) => setState(() => _values = [..._values, value]),
                onRemove: (index) => setState(() => _values = [..._values]..removeAt(index)),
              ),
              const SizedBox(height: 16),
              Text('Principles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _ChipEditor(
                controller: _principleController,
                items: _principles,
                hintText: 'Add a principle',
                onAdd: (value) => setState(() => _principles = [..._principles, value]),
                onRemove: (index) => setState(() => _principles = [..._principles]..removeAt(index)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Life Plan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipEditor extends StatelessWidget {
  final TextEditingController controller;
  final List<String> items;
  final String hintText;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _ChipEditor({
    required this.controller,
    required this.items,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
  });

  void _submit() {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    onAdd(value);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < items.length; i++)
              InputChip(
                label: Text(items[i]),
                onDeleted: () => onRemove(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: hintText, border: const OutlineInputBorder()),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _submit),
          ],
        ),
      ],
    );
  }
}
