import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/food/food_log.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../providers/food_providers.dart';
import '../services/food_log_service.dart';

const _foodCategories = <String>['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'];
const _invalidNumberMessage = 'Must be a number';

class FoodLogFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/food/logs/form';
  final FoodLog? log;
  final FoodLog? template;

  const FoodLogFormScreen({super.key, this.log, this.template});

  @override
  ConsumerState<FoodLogFormScreen> createState() => _FoodLogFormScreenState();
}

class _FoodLogFormScreenState extends ConsumerState<FoodLogFormScreen> {
  static const double _spinnerSize = 16;
  static const double _spinnerStrokeWidth = 2;
  static const double _thumbnailSize = 48;

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
    } else if (widget.template != null) {
      final template = widget.template!;
      _category = template.category;
      _dishNameController.text = template.dishName;
      _quantityController.text = template.quantity;
      _componentsController.text = template.components ?? '';
      _descriptionController.text = template.description ?? '';
      _caloriesController.text = template.calories?.toString() ?? '';
      _proteinController.text = template.proteinGrams?.toString() ?? '';
      _fatController.text = template.fatGrams?.toString() ?? '';
      _carbController.text = template.carbGrams?.toString() ?? '';
      _loggedAt = DateTime.now();
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
    if (sourcePath == null || !mounted) return;

    setState(() => _isSavingImage = true);
    final attachmentStorage = ref.read(foodAttachmentStorageServiceProvider);
    final saveResult = await attachmentStorage.saveAttachment(sourcePath);
    final savedPath = saveResult.data;
    if (!mounted) return;
    setState(() {
      if (savedPath != null) {
        _imagePath = savedPath;
      }
      _isSavingImage = false;
    });
  }

  void _removeImage() {
    setState(() => _imagePath = null);
  }

  double? _parseOptionalDouble(String value) => value.trim().isEmpty ? null : double.tryParse(value.trim());

  String? _validateOptionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.trim()) == null ? _invalidNumberMessage : null;
  }

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

    if (!mounted) return;
    if (result.isSuccess) {
      AppFeedback.showSuccess(context, 'Food log ${widget.log == null ? 'added' : 'updated'}');
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.showError(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log == null ? 'Add Food Log' : 'Edit Food Log'),
      ),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
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
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _dishNameController,
                decoration: const InputDecoration(
                  labelText: 'Dish name',
                  prefixIcon: Icon(Icons.ramen_dining_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g. "1 bowl", "250g")',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              DateTimeField(
                label: 'Logged at',
                value: _loggedAt,
                mode: DateTimeFieldMode.dateTime,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _loggedAt = value);
                  }
                },
              ),
              SizedBox(height: tokens.spacing.lg),
              Text('Image', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: tokens.spacing.sm),
              if (_imagePath != null) ...[
                EntityTile(
                  leading: ClipRRect(
                    borderRadius: tokens.radius.smallBorder,
                    child: Image.file(
                      File(_imagePath!),
                      width: _thumbnailSize,
                      height: _thumbnailSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: _imagePath!.split('/').last,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _removeImage,
                  ),
                ),
                SizedBox(height: tokens.spacing.sm),
              ],
              OutlinedButton.icon(
                onPressed: _isSavingImage ? null : _pickImage,
                icon: _isSavingImage
                    ? const SizedBox(
                        width: _spinnerSize,
                        height: _spinnerSize,
                        child: CircularProgressIndicator(strokeWidth: _spinnerStrokeWidth),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add image'),
              ),
              SizedBox(height: tokens.spacing.lg),
              TextFormField(
                controller: _componentsController,
                decoration: const InputDecoration(
                  labelText: 'Components (optional, e.g. "rice, chicken, salad")',
                  prefixIcon: Icon(Icons.list_outlined),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              SizedBox(height: tokens.spacing.lg),
              Text('Nutrition (optional)', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: tokens.spacing.sm),
              TextFormField(
                controller: _caloriesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateOptionalNumber,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _proteinController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateOptionalNumber,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _fatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateOptionalNumber,
                decoration: const InputDecoration(labelText: 'Fat (g)'),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _carbController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateOptionalNumber,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
              ),
              SizedBox(height: tokens.spacing.xl),
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
