import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import '../services/error_handler.dart';
import 'app_feedback.dart';
import 'empty_state.dart';
import 'ui/app_card.dart';

class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  static final LoggerService _logger = LoggerService.forModule('DatabaseViewerScreen');
  static final ErrorHandler _errorHandler = ErrorHandler(_logger);

  static const double _tablesListWidth = 220;
  static const String _title = 'Database Viewer';
  static const String _refreshTooltip = 'Refresh Tables';
  static const String _noTablesTitle = 'No tables found';
  static const String _noTablesSubtitle = 'Nothing has been written to storage yet.';
  static const String _selectTableTitle = 'Select a table';
  static const String _selectTableSubtitle = 'Pick a table from the list to view its rows.';
  static const String _noDataTitle = 'No data';
  static const String _noDataSubtitleTemplate = 'The table has no rows yet.';
  static const String _rowsSuffix = 'rows';
  static const String _columnsSuffix = 'columns';
  static const String _nullValue = 'NULL';
  static const String _trueValue = 'true';
  static const String _falseValue = 'false';
  static const int _cellMaxLines = 3;

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
    unawaited(_loadTables());
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final existingTables = <String>[];
      for (final table in _knownTables) {
        try {
          await StorageGateway.instance.query(table: table);
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
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTables,
            tooltip: _refreshTooltip,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _tablesListWidth, child: _buildTablesList(tokens)),
            SizedBox(width: tokens.spacing.lg),
            Expanded(child: _buildTableData(tokens)),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesList(AppThemeTokens tokens) {
    if (_isLoading && _tables.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tables.isEmpty) {
      return const EmptyState(
        title: _noTablesTitle,
        subtitle: _noTablesSubtitle,
        icon: Icons.storage_rounded,
        isCompact: true,
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.builder(
        itemCount: _tables.length,
        itemBuilder: (context, index) {
          final table = _tables[index];
          final isSelected = _selectedTable == table;

          return ListTile(
            title: Text(table),
            selected: isSelected,
            onTap: () => _loadTableData(table),
            trailing: isSelected
                ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildTableData(AppThemeTokens tokens) {
    if (_selectedTable == null) {
      return const EmptyState(
        title: _selectTableTitle,
        subtitle: _selectTableSubtitle,
        icon: Icons.table_chart_rounded,
        isCompact: true,
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tableData.isEmpty) {
      return const EmptyState(
        title: _noDataTitle,
        subtitle: _noDataSubtitleTemplate,
        icon: Icons.inbox_rounded,
        isCompact: true,
      );
    }

    final theme = Theme.of(context);
    final columns = _tableData.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_selectedTable (${_tableData.length} $_rowsSuffix)', style: theme.textTheme.titleMedium),
              Text(
                '${columns.length} $_columnsSuffix',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.md),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
                rows: _tableData
                    .map(
                      (row) => DataRow(
                        cells: columns
                            .map(
                              (col) => DataCell(
                                Text(
                                  _formatValue(row[col]),
                                  maxLines: _cellMaxLines,
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
    if (value == null) return _nullValue;
    if (value is String) return value;
    if (value is bool) return value ? _trueValue : _falseValue;
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }
}
