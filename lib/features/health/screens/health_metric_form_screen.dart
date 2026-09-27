import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/health_metric.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../providers/health_providers.dart';
import '../services/health_metric_service.dart';

const _invalidValueMessage = 'Enter a valid number';

const _commonMetricTypes = <String, String>{
  'Weight': 'kg',
  'Blood Pressure - Systolic': 'mmHg',
  'Blood Pressure - Diastolic': 'mmHg',
  'Glucose': 'mg/dL',
  'Heart Rate': 'bpm',
  'Temperature': '°C',
  'Custom': '',
};

class HealthMetricFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/metrics/form';
  final HealthMetric? metric;

  const HealthMetricFormScreen({super.key, this.metric});

  @override
  ConsumerState<HealthMetricFormScreen> createState() => _HealthMetricFormScreenState();
}

class _HealthMetricFormScreenState extends ConsumerState<HealthMetricFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customTypeController = TextEditingController();
  final _valueController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();
  late String _selectedType;
  late DateTime _measuredAt;
  late final HealthMetricService _service;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _service = ref.read(healthMetricServiceProvider);

    if (widget.metric != null) {
      final metric = widget.metric!;
      _selectedType = _commonMetricTypes.containsKey(metric.metricType) ? metric.metricType : 'Custom';
      if (_selectedType == 'Custom') {
        _customTypeController.text = metric.metricType;
      }
      _valueController.text = metric.value.toString();
      _unitController.text = metric.unit;
      _notesController.text = metric.notes ?? '';
      _measuredAt = metric.measuredAt;
    } else {
      _selectedType = 'Weight';
      _unitController.text = _commonMetricTypes['Weight']!;
      _measuredAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    _valueController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final metricType = _selectedType == 'Custom' ? _customTypeController.text.trim() : _selectedType;
    final value = double.tryParse(_valueController.text.trim());
    if (value == null) {
      AppFeedback.showError(
        context,
        ValidationError(_invalidValueMessage, fieldErrors: {'value': _invalidValueMessage}),
      );
      return;
    }

    final metric = HealthMetric(
      id: widget.metric?.id ?? _uuid.v4(),
      createdAt: widget.metric?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'current_user_id',
      metricType: metricType,
      value: value,
      unit: _unitController.text.trim(),
      measuredAt: _measuredAt,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final result = widget.metric == null ? await _service.create(metric) : await _service.update(metric);

    if (!mounted) return;
    if (result.isSuccess) {
      AppFeedback.showSuccess(context, 'Metric ${widget.metric == null ? 'added' : 'updated'}');
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
        title: Text(widget.metric == null ? 'Add Metric' : 'Edit Metric'),
      ),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: _commonMetricTypes.keys
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedType = value;
                    if (value != 'Custom') {
                      _unitController.text = _commonMetricTypes[value]!;
                    }
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Metric type',
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
              ),
              if (_selectedType == 'Custom') ...[
                SizedBox(height: tokens.spacing.md),
                TextFormField(
                  controller: _customTypeController,
                  decoration: const InputDecoration(labelText: 'Custom metric name'),
                  validator: (value) =>
                      _selectedType == 'Custom' && (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Value',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return double.tryParse(value.trim()) == null ? _invalidValueMessage : null;
                },
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: tokens.spacing.md),
              DateTimeField(
                label: 'Measured at',
                value: _measuredAt,
                onChanged: (date) {
                  if (date != null) {
                    setState(() => _measuredAt = date);
                  }
                },
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              SizedBox(height: tokens.spacing.xl),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.metric == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
