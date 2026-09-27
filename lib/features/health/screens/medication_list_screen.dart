import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/medication.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/show_confirm_dialog.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../providers/health_providers.dart';
import '../services/health_service.dart';
import '../services/medication_service.dart';
import '../widgets/medication_tile.dart';
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
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset All Checks',
      message: 'Are you sure you want to uncheck all medications for today?',
      confirmLabel: 'Reset',
      icon: Icons.refresh_rounded,
    );

    if (!confirmed) {
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
    final tokens = AppThemeTokens.of(context);
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
          Positioned(right: tokens.spacing.lg, bottom: tokens.spacing.lg, child: fab),
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
    final tokens = AppThemeTokens.of(context);
    return _dailyChecklist.isEmpty
        ? const EmptyState(
            title: 'No medications scheduled for this day',
            subtitle: 'Enjoy a day off from tracking.',
            icon: Icons.medication_outlined,
          )
        : ListView(
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              AppCard(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
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
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () async {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                        await _loadData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.today_rounded),
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
              SizedBox(height: tokens.spacing.lg),
              if (_stats.isNotEmpty)
                StatGrid(
                  children: [
                    StatTile(
                      icon: Icons.check_circle_rounded,
                      label: 'Taken',
                      value: '${_stats['todayTaken']}/${_stats['todayTotal']}',
                      accentColor: tokens.colors.success,
                    ),
                    StatTile(
                      icon: Icons.pending_rounded,
                      label: 'Pending',
                      value: '${_stats['todayPending']}',
                      accentColor: tokens.colors.warning,
                    ),
                    StatTile(
                      icon: Icons.trending_up_rounded,
                      label: 'Adherence',
                      value: '${_stats['adherenceRate']}%',
                      accentColor: tokens.colors.info,
                    ),
                  ],
                ),
              if (_stats.isNotEmpty) SizedBox(height: tokens.spacing.lg),
              OutlinedButton.icon(
                onPressed: _dailyChecklist.isEmpty ? null : _resetAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All Checks'),
              ),
              SizedBox(height: tokens.spacing.lg),
              for (final check in _dailyChecklist) ...[
                _ChecklistItem(check: check, onToggle: () => _toggleCheck(check)),
                SizedBox(height: tokens.spacing.sm),
              ],
            ],
          );
  }

  Widget _buildManageTab() {
    final tokens = AppThemeTokens.of(context);
    return _medications.isEmpty
        ? const EmptyState(
            title: 'No medications added yet',
            subtitle: 'Tap + to add your first medication',
            icon: Icons.medication_outlined,
          )
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.lg, tokens.spacing.lg, 0),
                  child: Column(
                    children: [
                      if (_stats.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spacing.md),
                          child: StatGrid(
                            children: [
                              StatTile(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Active',
                                value: '${_stats['activeMedications']}',
                                accentColor: tokens.colors.success,
                              ),
                              StatTile(
                                icon: Icons.pause_circle_outline_rounded,
                                label: 'Paused',
                                value: '${_medications.where((m) => !m.isActive).length}',
                                accentColor: tokens.colors.muted,
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Long press and drag to reorder',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      SizedBox(height: tokens.spacing.sm),
                    ],
                  ),
                ),
              ),
              SliverReorderableList(
                itemCount: _medications.length,
                onReorderItem: _reorderMedications,
                itemBuilder: (itemContext, index) {
                  final med = _medications[index];
                  return Padding(
                    key: ValueKey(med.id),
                    padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg, vertical: tokens.spacing.xs),
                    child: MedicationTile(
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

class _ChecklistItem extends StatelessWidget {
  final DailyMedicationCheck check;
  final VoidCallback onToggle;

  const _ChecklistItem({
    required this.check,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('health');
    return AppCard(
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: check.isChecked,
        onChanged: (_) => onToggle(),
        title: Text(check.medicationName),
        subtitle: Text('${check.dosage} • ${check.displayTime}'),
        secondary: Icon(
          Icons.medication,
          color: check.isChecked ? tokens.colors.success : accent,
        ),
      ),
    );
  }
}
