import 'package:flutter/material.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import '../services/error_handler.dart';
import 'app_feedback.dart';

/// Database Viewer Screen for inspecting SQLite data
class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  static final LoggerService _logger = LoggerService.forModule('DatabaseViewerScreen');
  static final ErrorHandler _errorHandler = ErrorHandler(_logger);

  // Known tables in the app
  static const List<String> _knownTables = [
    'prayers',
    'quran_readings',
    'religious_entries',
    'prayer_times_snapshots',
    'transactions',
    'categories',
    'budgets',
    'habits',
    'habit_logs',
    'daily_events',
    'workouts',
    'exercises',
    'schedules',
    'medications',
    'medication_logs',
    'blood_tests',
    'health_metrics',
    'notes',
    'todos',
    'note_categories',
    'events',
    'reminders',
    'credentials',
    'security_categories',
    '_key_value',
  ];

  List<String> _tables = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      // Try to load data from known tables to see which ones exist
      final existingTables = <String>[];
      for (final table in _knownTables) {
        try {
          await StorageGateway.instance.query(table: table);
          // Show table even if empty (removed the isNotEmpty check)
          existingTables.add(table);
        } catch (error) {
          _logger.debug('Table $table is not available: $error');
        }
      }

      setState(() {
        _tables = existingTables;
        _tables.sort();
      });
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(
        error,
        context: 'DatabaseViewerScreen.loadTables',
        stackTrace: stackTrace,
      );
      if (mounted) {
        AppFeedback.showError(context, mapped);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() => _isLoading = true);
    try {
      final data = await StorageGateway.instance.query(table: tableName);
      setState(() {
        _selectedTable = tableName;
        _tableData = data;
      });
    } catch (error, stackTrace) {
      final mapped = _errorHandler.mapException(
        error,
        context: 'DatabaseViewerScreen.loadTableData',
        stackTrace: stackTrace,
      );
      if (mounted) {
        AppFeedback.showError(context, mapped);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
            tooltip: 'Refresh Tables',
          ),
        ],
      ),
      body: Row(
        children: [
          // Tables list
          SizedBox(
            width: 200,
            child: _buildTablesList(),
          ),
          const VerticalDivider(width: 1),
          // Table data
          Expanded(
            child: _buildTableData(),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesList() {
    if (_isLoading && _tables.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storage_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tables found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _tables.length,
      itemBuilder: (context, index) {
        final table = _tables[index];
        final isSelected = _selectedTable == table;

        return ListTile(
          title: Text(table),
          selected: isSelected,
          selectedTileColor: Colors.blue.withValues(alpha: 0.2),
          onTap: () => _loadTableData(table),
          trailing: isSelected
              ? Icon(Icons.check, color: Colors.blue[700])
              : null,
        );
      },
    );
  }

  Widget _buildTableData() {
    if (_selectedTable == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a table to view data',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tableData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No data in $_selectedTable',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Get column names from first row
    final columns = _tableData.first.keys.toList();

    return Column(
      children: [
        // Header with table info
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedTable (${_tableData.length} rows)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${columns.length} columns',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Data table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: columns
                    .map((col) => DataColumn(label: Text(col)))
                    .toList(),
                rows: _tableData
                    .map(
                      (row) => DataRow(
                        cells: columns
                            .map(
                              (col) => DataCell(
                                Text(
                                  _formatValue(row[col]),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String) return value;
    if (value is bool) return value ? 'true' : 'false';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }
}
