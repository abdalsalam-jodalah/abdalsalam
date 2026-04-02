import 'package:flutter/material.dart';

import '../../../data/models/health/medication.dart';
import '../../../data/models/health/medication_log.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../data/repositories/health/medication_log_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../services/medication_service.dart';
import 'medication_form_screen.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart';

class MedicationListScreen extends StatefulWidget {
  static const routeName = '/health/medications';

  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MedicationService _service;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  List<Medication> _medications = [];
  List<DailyMedicationCheck> _dailyChecklist = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize service
    final logger = LoggerService.forModule('MedicationService', moduleType: ModuleType.service);
    final storage = StorageGateway.instance;
    final repo = HealthRepositoryImpl(storage, logger);
    final logRepo = MedicationLogRepositoryImpl(storage, logger);
    
    _service = MedicationService(
      repository: repo,
      logger: logger,
      logRepository: logRepo,
    );
    
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen (but not on first build)
    if (_hasLoadedOnce && mounted) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Generate logs for today if needed
    await _service.generateDailyLogs(_selectedDate, 'current_user_id');
    
    // Load medications
    final medsResult = await _service.getMedicationsSorted();
    if (medsResult.isSuccess) {
      _medications = medsResult.data!;
    }
    
    // Load daily checklist
    final checklistResult = await _service.getDailyChecklist(_selectedDate);
    if (checklistResult.isSuccess) {
      _dailyChecklist = checklistResult.data!;
    }
    
    // Load statistics
    final statsResult = await _service.getStatistics();
    if (statsResult.isSuccess) {
      _stats = statsResult.data!;
    }
    
    setState(() {
      _isLoading = false;
      _hasLoadedOnce = true;
    });
  }

  Future<void> _toggleCheck(DailyMedicationCheck check) async {
    if (check.isChecked) {
      // Uncheck by resetting
      final updated = check.log.copyWith(
        takenAtIsNull: true,
        updatedAt: DateTime.now(),
      );
      await _service.logRepository.update(updated);
    } else {
      // Mark as taken
      await _service.markAsTaken(
        check.medication.id,
        _selectedDate,
        check.log.scheduledTime,
      );
    }
    _loadData();
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Checks'),
        content: const Text('Are you sure you want to uncheck all medications for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.resetDailyLogs(_selectedDate);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All checks reset')),
        );
      }
    }
  }

  Future<void> _reorderMedications(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    
    final item = _medications.removeAt(oldIndex);
    _medications.insert(newIndex, item);
    
    final ids = _medications.map((m) => m.id).toList();
    await _service.reorderMedications(ids);
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily Checklist', icon: Icon(Icons.checklist)),
            Tab(text: 'Manage', icon: Icon(Icons.medication_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyChecklistTab(),
                _buildManageTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, MedicationFormScreen.routeName);
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildDailyChecklistTab() {
    return Column(
      children: [
        // Date selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                  _loadData();
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
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                  _loadData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                  _loadData();
                },
              ),
            ],
          ),
        ),
        
        // Stats
        if (_stats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
          ),
        
        // Reset button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: _dailyChecklist.isEmpty ? null : _resetAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset All Checks'),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Checklist
        Expanded(
          child: _dailyChecklist.isEmpty
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dailyChecklist.length,
                  itemBuilder: (context, index) {
                    final check = _dailyChecklist[index];
                    return _ChecklistItem(
                      check: check,
                      onToggle: () => _toggleCheck(check),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildManageTab() {
    return Column(
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
        
        Expanded(
          child: _medications.isEmpty
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
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  onReorder: _reorderMedications,
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    return _MedicationCard(
                      key: ValueKey(med.id),
                      medication: med,
                      onToggleActive: () async {
                        await _service.toggleActive(med.id);
                        _loadData();
                      },
                      onEdit: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicationFormScreen(medication: med),
                          ),
                        );
                        _loadData();
                      },
                      onDelete: () async {
                        await _service.softDelete(med.id);
                        _loadData();
                      },
                    );
                  },
                ),
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
    super.key,
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
            PopupMenuItem(
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
            PopupMenuItem(
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
            PopupMenuItem(
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
