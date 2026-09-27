import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/doctor_visit.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../providers/health_providers.dart';
import '../services/doctor_visit_service.dart';

class DoctorVisitFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/doctor-visits/form';
  final DoctorVisit? visit;

  const DoctorVisitFormScreen({super.key, this.visit});

  @override
  ConsumerState<DoctorVisitFormScreen> createState() => _DoctorVisitFormScreenState();
}

class _DoctorVisitFormScreenState extends ConsumerState<DoctorVisitFormScreen> {
  static const double _spinnerSize = 16;
  static const double _spinnerStrokeWidth = 2;

  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _reasonController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _visitDate;
  DateTime? _followUpDate;
  late Set<String> _selectedMedicationIds;
  late List<String> _attachmentPaths;
  late final DoctorVisitService _service;
  bool _isSavingAttachment = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _service = ref.read(doctorVisitServiceProvider);

    if (widget.visit != null) {
      final visit = widget.visit!;
      _doctorNameController.text = visit.doctorName;
      _specialtyController.text = visit.specialty ?? '';
      _reasonController.text = visit.reason;
      _diagnosisController.text = visit.diagnosis ?? '';
      _notesController.text = visit.notes ?? '';
      _visitDate = visit.visitDate;
      _followUpDate = visit.followUpDate;
      _selectedMedicationIds = visit.medicationIds.toSet();
      _attachmentPaths = List.of(visit.attachmentPaths);
    } else {
      _visitDate = DateTime.now();
      _selectedMedicationIds = {};
      _attachmentPaths = [];
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specialtyController.dispose();
    _reasonController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final sourcePath = result.files.single.path;
    if (sourcePath == null || !mounted) return;

    setState(() => _isSavingAttachment = true);
    final attachmentStorage = ref.read(attachmentStorageServiceProvider);
    final saveResult = await attachmentStorage.saveAttachment(sourcePath);
    final savedPath = saveResult.data;
    if (!mounted) return;
    setState(() {
      if (savedPath != null) {
        _attachmentPaths.add(savedPath);
      }
      _isSavingAttachment = false;
    });
  }

  void _removeAttachment(String path) {
    setState(() => _attachmentPaths.remove(path));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final visit = DoctorVisit(
      id: widget.visit?.id ?? _uuid.v4(),
      createdAt: widget.visit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'current_user_id',
      doctorName: _doctorNameController.text.trim(),
      specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
      visitDate: _visitDate,
      reason: _reasonController.text.trim(),
      diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
      medicationIds: _selectedMedicationIds.toList(),
      attachmentPaths: _attachmentPaths,
      followUpDate: _followUpDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final result = widget.visit == null
        ? await _service.create(visit)
        : await _service.updateWithAttachmentCleanup(widget.visit!, visit);

    if (!mounted) return;
    if (result.isSuccess) {
      AppFeedback.showSuccess(context, 'Doctor visit ${widget.visit == null ? 'added' : 'updated'}');
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.showError(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('health');
    final medicationsAsync = ref.watch(sortedMedicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visit == null ? 'Add Doctor Visit' : 'Edit Doctor Visit'),
      ),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _doctorNameController,
                decoration: const InputDecoration(
                  labelText: 'Doctor name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty (optional)',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              DateTimeField(
                label: 'Visit date',
                value: _visitDate,
                onChanged: (date) {
                  if (date != null) {
                    setState(() => _visitDate = date);
                  }
                },
              ),
              SizedBox(height: tokens.spacing.sm),
              DateTimeField(
                label: 'Follow-up date (optional)',
                value: _followUpDate,
                isClearable: true,
                onChanged: (date) => setState(() => _followUpDate = date),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for visit',
                  prefixIcon: Icon(Icons.help_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis (optional)',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
              ),
              SizedBox(height: tokens.spacing.lg),
              Text('Prescribed medications', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: tokens.spacing.sm),
              medicationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AsyncErrorView(
                  error: error,
                  isCompact: true,
                  onRetry: () => ref.invalidate(sortedMedicationsProvider),
                ),
                data: (medications) {
                  if (medications.isEmpty) {
                    return const Text('No medications recorded yet.');
                  }
                  return Wrap(
                    spacing: tokens.spacing.sm,
                    runSpacing: tokens.spacing.sm,
                    children: medications.map((medication) {
                      final isSelected = _selectedMedicationIds.contains(medication.id);
                      return FilterChip(
                        label: Text(medication.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMedicationIds.add(medication.id);
                            } else {
                              _selectedMedicationIds.remove(medication.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: tokens.spacing.lg),
              Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: tokens.spacing.sm),
              for (final path in _attachmentPaths) ...[
                EntityTile(
                  icon: Icons.attach_file,
                  accentColor: accent,
                  title: path.split('/').last,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeAttachment(path),
                  ),
                ),
                SizedBox(height: tokens.spacing.sm),
              ],
              OutlinedButton.icon(
                onPressed: _isSavingAttachment ? null : _pickAttachment,
                icon: _isSavingAttachment
                    ? const SizedBox(
                        width: _spinnerSize,
                        height: _spinnerSize,
                        child: CircularProgressIndicator(strokeWidth: _spinnerStrokeWidth),
                      )
                    : const Icon(Icons.add),
                label: const Text('Add attachment'),
              ),
              SizedBox(height: tokens.spacing.lg),
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
                label: Text(widget.visit == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
