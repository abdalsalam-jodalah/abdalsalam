import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/food/food_log.dart';
import '../../../providers/app_providers.dart';
import '../providers/food_providers.dart';
import '../services/food_log_service.dart';

const _foodCategories = <String>['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'];

class FoodLogFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/food/logs/form';
  final FoodLog? log;

  const FoodLogFormScreen({super.key, this.log});

  @override
  ConsumerState<FoodLogFormScreen> createState() => _FoodLogFormScreenState();
}

class _FoodLogFormScreenState extends ConsumerState<FoodLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dishNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _componentsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbController = TextEditingController();
  late String _category;
  late DateTime _loggedAt;
  String? _imagePath;
  late final FoodLogService _service;
  bool _isSavingImage = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _service = ref.read(foodLogServiceProvider);

    if (widget.log != null) {
      final log = widget.log!;
      _category = log.category;
      _dishNameController.text = log.dishName;
      _quantityController.text = log.quantity;
      _componentsController.text = log.components ?? '';
      _descriptionController.text = log.description ?? '';
      _caloriesController.text = log.calories?.toString() ?? '';
      _proteinController.text = log.proteinGrams?.toString() ?? '';
      _fatController.text = log.fatGrams?.toString() ?? '';
      _carbController.text = log.carbGrams?.toString() ?? '';
      _loggedAt = log.loggedAt;
      _imagePath = log.imagePath;
    } else {
      _category = _foodCategories.first;
      _loggedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _dishNameController.dispose();
    _quantityController.dispose();
    _componentsController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final sourcePath = result.files.single.path;
    if (sourcePath == null) return;

    setState(() => _isSavingImage = true);
    final attachmentStorage = ref.read(foodAttachmentStorageServiceProvider);
    final savedPath = await attachmentStorage.saveAttachment(sourcePath);
    setState(() {
      _imagePath = savedPath;
      _isSavingImage = false;
    });
  }

  void _removeImage() {
    setState(() => _imagePath = null);
  }

  double? _parseOptionalDouble(String value) => value.trim().isEmpty ? null : double.tryParse(value.trim());

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final log = FoodLog(
      id: widget.log?.id ?? _uuid.v4(),
      createdAt: widget.log?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'current_user_id',
      category: _category,
      dishName: _dishNameController.text.trim(),
      quantity: _quantityController.text.trim(),
      imagePath: _imagePath,
      components: _componentsController.text.trim().isEmpty ? null : _componentsController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      loggedAt: _loggedAt,
      calories: _parseOptionalDouble(_caloriesController.text),
      proteinGrams: _parseOptionalDouble(_proteinController.text),
      fatGrams: _parseOptionalDouble(_fatController.text),
      carbGrams: _parseOptionalDouble(_carbController.text),
    );

    final result = widget.log == null ? await _service.create(log) : await _service.update(log);

    if (result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Food log ${widget.log == null ? 'added' : 'updated'}')),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error?.message ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log == null ? 'Add Food Log' : 'Edit Food Log'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _foodCategories
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _category = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dishNameController,
                decoration: const InputDecoration(
                  labelText: 'Dish name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.ramen_dining_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g. "1 bowl", "250g")',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Logged at'),
                subtitle: Text(
                  '${_loggedAt.year}-${_loggedAt.month.toString().padLeft(2, '0')}-${_loggedAt.day.toString().padLeft(2, '0')} '
                  '${_loggedAt.hour.toString().padLeft(2, '0')}:${_loggedAt.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _loggedAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_loggedAt),
                  );
                  if (time == null) return;
                  setState(() {
                    _loggedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Image', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_imagePath != null)
                Card(
                  child: ListTile(
                    leading: Image.file(File(_imagePath!), width: 48, height: 48, fit: BoxFit.cover),
                    title: Text(_imagePath!.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _removeImage,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _isSavingImage ? null : _pickImage,
                icon: _isSavingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add image'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _componentsController,
                decoration: const InputDecoration(
                  labelText: 'Components (optional, e.g. "rice, chicken, salad")',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.list_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              Text('Nutrition (optional)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _caloriesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _proteinController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fat (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _carbController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Carbs (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.log == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
