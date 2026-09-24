import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/health/medication.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/health_providers.dart';
import '../services/health_service.dart';
import '../services/medication_service.dart';
import 'medication_form_screen.dart';

class MedicationListScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/medications';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [HealthScreen] shell.
  final bool embedded;

  const MedicationListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MedicationService _service;
  late final HealthService _healthService;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  AppError? _loadError;
  List<Medication> _medications = [];
  List<DailyMedicationCheck> _dailyChecklist = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = ref.read(medicationServiceProvider);
    _healthService = ref.read(healthServiceProvider);
    unawaited(_loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen (but not on first build)
    if (_hasLoadedOnce && mounted) {
      unawaited(_loadData());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final generateResult = await _service.generateDailyLogs(_selectedDate, 'current_user_id');
    if (!mounted) return;
    if (generateResult.isFailure) {
      setState(() {
        _isLoading = false;
        _loadError = generateResult.error;
      });
      return;
    }

    final medsResult = await _service.getMedicationsSorted();
    if (!mounted) return;
    if (medsResult.isFailure) {
      setState(() {
        _isLoading = false;
        _loadError = medsResult.error;
      });
      return;
    }

    final checklistResult = await _service.getDailyChecklist(_selectedDate);
    if (!mounted) return;
    if (checklistResult.isFailure) {
      setState(() {
        _isLoading = false;
        _loadError = checklistResult.error;
      });
      return;
    }

    final statsResult = await _service.getStatistics();
    if (!mounted) return;
    if (statsResult.isFailure) {
      setState(() {
        _isLoading = false;
        _loadError = statsResult.error;
      });
      return;
    }

    setState(() {
      _medications = medsResult.data!;
      _dailyChecklist = checklistResult.data!;
      _stats = statsResult.data!;
      _isLoading = false;
      _hasLoadedOnce = true;
    });
  }

  int _compareChecklistEntries(DailyMedicationCheck a, DailyMedicationCheck b) {
    if (a.isChecked != b.isChecked) {
      return a.isChecked ? 1 : -1;
    }
    final orderCompare = a.medication.displayOrder.compareTo(b.medication.displayOrder);
    if (orderCompare != 0) return orderCompare;
    return a.log.scheduledTime.compareTo(b.log.scheduledTime);
  }

  Future<void> _toggleCheck(DailyMedicationCheck check) async {
    final index = _dailyChecklist.indexOf(check);

    if (check.isChecked) {
      // Uncheck by resetting
      final updated = check.log.copyWith(
        takenAtIsNull: true,
        updatedAt: DateTime.now(),
      );
      final updateResult = await _service.logRepository.update(updated);
      if (!mounted) return;
      if (updateResult.isFailure) {
        AppFeedback.showError(context, updateResult.error!);
        return;
      }

      setState(() {
        _dailyChecklist[index] = DailyMedicationCheck(
          log: updated,
          medication: check.medication,
        );
        _dailyChecklist.sort(_compareChecklistEntries);
      });

      final statsResult = await _service.getStatistics();
      if (!mounted) return;
      if (statsResult.isSuccess) {
        setState(() {
          _stats = statsResult.data!;
        });
      }
    } else {
      // Mark as taken
      final result = await _service.markAsTaken(
        check.medication.id,
        _selectedDate,
        check.log.scheduledTime,
      );
      if (!mounted) return;
      if (result.isFailure) {
        AppFeedback.showError(context, result.error!);
        return;
      }

      setState(() {
        _dailyChecklist[index] = DailyMedicationCheck(
          log: result.data!,
          medication: check.medication,
        );
        _dailyChecklist.sort(_compareChecklistEntries);
      });

      final statsResult = await _service.getStatistics();
      if (!mounted) return;
      if (statsResult.isSuccess) {
        setState(() {
          _stats = statsResult.data!;
        });
      }
    }
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset All Checks'),
        content: const Text('Are you sure you want to uncheck all medications for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    final result = await _service.resetDailyLogs(_selectedDate);
    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    await _loadData();
    if (!mounted) return;
    AppFeedback.showSuccess(context, 'All checks reset');
  }

  Future<void> _reorderMedications(int oldIndex, int newIndex) async {
    final previousOrder = List<Medication>.of(_medications);
    final item = _medications.removeAt(oldIndex);
    _medications.insert(newIndex, item);
    setState(() {});

    final ids = _medications.map((m) => m.id).toList();
    final result = await _service.reorderMedications(ids);
    if (!mounted) return;
    if (result.isFailure) {
      setState(() => _medications = previousOrder);
      AppFeedback.showError(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Daily Checklist', icon: Icon(Icons.checklist)),
        Tab(text: 'Manage', icon: Icon(Icons.medication_outlined)),
      ],
    );
    final tabContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
            ? AsyncErrorView(error: _loadError!, onRetry: _loadData)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyChecklistTab(),
                  _buildManageTab(),
                ],
              );
    final fab = FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.pushNamed(context, MedicationFormScreen.routeName);
        if (!mounted) return;
        await _loadData();
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Medication'),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: tabBar,
              ),
              Expanded(child: tabContent),
            ],
          ),
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Medications'), bottom: tabBar),
      body: tabContent,
      floatingActionButton: fab,
    );
  }

  Widget _buildDailyChecklistTab() {
    return _dailyChecklist.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No medications scheduled for this day',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Date selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () async {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                        await _loadData();
                      },
                    ),
                    Expanded(
                      child: Text(
                        _formatDate(_selectedDate),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () async {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                        await _loadData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.today),
                      onPressed: () async {
                        setState(() {
                          _selectedDate = DateTime.now();
                        });
                        await _loadData();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              if (_stats.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Taken',
                        value: '${_stats['todayTaken']}/${_stats['todayTotal']}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Pending',
                        value: '${_stats['todayPending']}',
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Adherence',
                        value: '${_stats['adherenceRate']}%',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              
              if (_stats.isNotEmpty) const SizedBox(height: 16),
              
              // Reset button
              OutlinedButton.icon(
                onPressed: _dailyChecklist.isEmpty ? null : _resetAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All Checks'),
              ),
              
              const SizedBox(height: 16),
              
              // Checklist items
              ..._dailyChecklist.map((check) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ChecklistItem(
                      check: check,
                      onToggle: () => _toggleCheck(check),
                    ),
                  )),
            ],
          );
  }

  Widget _buildManageTab() {
    return _medications.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No medications added yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Tap + to add your first medication'),
              ],
            ),
          )
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (_stats.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '${_stats['activeMedications']}',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const Text('Active'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${_medications.where((m) => !m.isActive).length}',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const Text('Paused'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Long press and drag to reorder',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              
              SliverReorderableList(
                itemCount: _medications.length,
                onReorderItem: _reorderMedications,
                itemBuilder: (itemContext, index) {
                  final med = _medications[index];
                  return Padding(
                    key: ValueKey(med.id),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _MedicationCard(
                      medication: med,
                      onToggleActive: () async {
                        final result = await _service.toggleActive(med.id);
                        if (!mounted) return;
                        if (result.isFailure) {
                          AppFeedback.showError(context, result.error!);
                          return;
                        }
                        final reminderResult = await _healthService.refreshReminders(result.data!);
                        if (!mounted) return;
                        if (reminderResult.isFailure) {
                          AppFeedback.showError(context, reminderResult.error!);
                        }
                        await _loadData();
                      },
                      onEdit: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => MedicationFormScreen(medication: med),
                          ),
                        );
                        if (!mounted) return;
                        await _loadData();
                      },
                      onDelete: () async {
                        final deleteResult = await _service.softDelete(med.id);
                        if (!mounted) return;
                        if (deleteResult.isFailure) {
                          AppFeedback.showError(context, deleteResult.error!);
                          return;
                        }
                        final cancelResult = await _healthService.cancelReminders(med.id);
                        if (!mounted) return;
                        if (cancelResult.isFailure) {
                          AppFeedback.showError(context, cancelResult.error!);
                        }
                        await _loadData();
                      },
                    ),
                  );
                },
              ),
            ],
          );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else if (targetDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final DailyMedicationCheck check;
  final VoidCallback onToggle;

  const _ChecklistItem({
    required this.check,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: check.isChecked,
        onChanged: (_) => onToggle(),
        title: Text(check.medicationName),
        subtitle: Text('${check.dosage} • ${check.displayTime}'),
        secondary: Icon(
          Icons.medication,
          color: check.isChecked ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.medication,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.drag_handle,
          color: Theme.of(context).colorScheme.outline,
        ),
        title: Text(
          medication.name,
          style: TextStyle(
            decoration: medication.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${medication.dosage} • ${medication.frequency}'),
            Text('Times: ${medication.reminderTimes.join(", ")}'),
            if (medication.timing != MedicationTiming.anytime)
              Text('Take: ${medication.timingLabel}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (medication.frequency == 'Weekly' && medication.weekDays.isNotEmpty)
              Text('Days: ${medication.weekDaysLabel}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              child: Row(
                children: [
                  Icon(medication.isActive ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(medication.isActive ? 'Pause' : 'Resume'),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, onToggleActive);
              },
            ),
            PopupMenuItem<void>(
              child: const Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, onEdit);
              },
            ),
            PopupMenuItem<void>(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, onDelete);
              },
            ),
          ],
        ),
      ),
    );
  }
}
