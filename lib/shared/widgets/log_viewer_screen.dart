import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../infrastructure/crash_log_recorder.dart';
import '../infrastructure/logger_service.dart';
import 'empty_state.dart';
import 'log_level_badge.dart';
import 'ui/app_card.dart';
import 'ui/show_confirm_dialog.dart';

class LogViewerScreen extends StatefulWidget {
  static const routeName = '/dev/logs';

  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  static const String _logsTitle = 'Log Viewer';
  static const String _savedErrorsTitle = 'Saved Errors';
  static const String _showSavedErrorsTooltip = 'Show Saved Errors';
  static const String _showSessionLogsTooltip = 'Show Session Logs';
  static const String _clearLogsTooltip = 'Clear Logs';
  static const String _exportLogsTooltip = 'Export Logs';
  static const String _searchHint = 'Search logs...';
  static const String _noLogsTitle = 'No logs found';
  static const String _noLogsSubtitle = 'Nothing has been logged yet, or your search has no matches.';
  static const String _closeLabel = 'Close';
  static const String _copyLabel = 'Copy';
  static const String _copiedMessage = 'Log copied to clipboard';
  static const String _clearLogsTitle = 'Clear Logs';
  static const String _clearLogsMessage = 'Are you sure you want to clear all logs?';
  static const String _clearLogsConfirmLabel = 'Clear';
  static const String _clearedMessage = 'Logs cleared';
  static const int _messageMaxLines = 3;
  static const String _monospaceFontFamily = 'monospace';

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isShowingPersistedErrors = false;
  List<String> _persistedErrors = const <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadPersistedErrors());
  }

  Future<void> _loadPersistedErrors() async {
    try {
      final entries = await CrashLogRecorder.instance.readEntries();
      if (!mounted) {
        return;
      }
      setState(() => _persistedErrors = entries);
    } catch (error, stackTrace) {
      LoggerService.forModule('LogViewer').warning('Saved errors could not be loaded: $error\n$stackTrace');
    }
  }

  List<String> get _visibleLogs {
    return _isShowingPersistedErrors ? _persistedErrors : LoggerService.getAllLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isShowingPersistedErrors ? _savedErrorsTitle : _logsTitle),
        actions: [
          IconButton(
            icon: Icon(_isShowingPersistedErrors ? Icons.list_alt_rounded : Icons.history_rounded),
            onPressed: () => setState(() => _isShowingPersistedErrors = !_isShowingPersistedErrors),
            tooltip: _isShowingPersistedErrors ? _showSessionLogsTooltip : _showSavedErrorsTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmClearLogs,
            tooltip: _clearLogsTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportLogs,
            tooltip: _exportLogsTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(tokens.spacing.md),
            child: _buildSearchBar(),
          ),
          Expanded(child: _buildLogList(tokens)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: _searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildLogList(AppThemeTokens tokens) {
    final logs = _visibleLogs;
    final filteredLogs = logs.where((log) {
      return _searchQuery.isEmpty || log.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredLogs.isEmpty) {
      return const EmptyState(
        title: _noLogsTitle,
        subtitle: _noLogsSubtitle,
        icon: Icons.inbox_rounded,
        isCompact: true,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[filteredLogs.length - 1 - index];
        return Padding(
          padding: EdgeInsets.only(bottom: tokens.spacing.sm),
          child: _buildLogItem(context, tokens, log),
        );
      },
    );
  }

  Widget _buildLogItem(BuildContext context, AppThemeTokens tokens, String log) {
    final color = _getLogLevelColor(tokens, log);
    final level = _extractLogLevel(log);
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => _showLogDetails(log),
      onLongPress: () => _copyLogToClipboard(log),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LogLevelBadge(level: level, color: color),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: Text(
                  _extractModule(log),
                  style: theme.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _extractTime(log),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.sm),
          Text(
            _extractMessage(log),
            style: theme.textTheme.bodySmall,
            maxLines: _messageMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(AppThemeTokens tokens, String log) {
    if (log.contains('[DEBUG]')) return tokens.colors.muted;
    if (log.contains('[INFO]')) return tokens.colors.info;
    if (log.contains('[WARN]')) return tokens.colors.warning;
    if (log.contains('[ERROR]')) return tokens.colors.danger;
    if (log.contains('[FATAL]')) return tokens.colors.danger;
    return tokens.colors.muted;
  }

  String _extractLogLevel(String log) {
    if (log.contains('[DEBUG]')) return 'DEBUG';
    if (log.contains('[INFO]')) return 'INFO';
    if (log.contains('[WARN]')) return 'WARNING';
    if (log.contains('[ERROR]')) return 'ERROR';
    if (log.contains('[FATAL]')) return 'FATAL';
    return 'LOG';
  }

  String _extractModule(String log) {
    final match = RegExp(r'\[([^\]]+)\]').allMatches(log).toList();
    if (match.length >= 2) {
      return match[1].group(1) ?? 'Unknown';
    }
    return 'Unknown';
  }

  String _extractTime(String log) {
    final match = RegExp(r'(\d{2}:\d{2}:\d{2})').firstMatch(log);
    return match?.group(1) ?? '';
  }

  String _extractMessage(String log) {
    final parts = log.split('] ');
    if (parts.length >= 3) {
      return parts.sublist(2).join('] ').trim();
    }
    return log;
  }

  void _showLogDetails(String log) {
    final tokens = AppThemeTokens.of(context);
    final color = _getLogLevelColor(tokens, log);
    final level = _extractLogLevel(log);
    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            LogLevelBadge(level: level, color: color),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Text(_extractModule(log), style: Theme.of(dialogContext).textTheme.titleMedium),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            log,
            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(fontFamily: _monospaceFontFamily),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(_closeLabel),
          ),
          TextButton(
            onPressed: () {
              _copyLogToClipboard(log);
              Navigator.pop(dialogContext);
            },
            child: const Text(_copyLabel),
          ),
        ],
      ),
    ));
  }

  void _copyLogToClipboard(String log) {
    unawaited(Clipboard.setData(ClipboardData(text: log)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_copiedMessage)),
    );
  }

  Future<void> _confirmClearLogs() async {
    final isConfirmed = await showConfirmDialog(
      context,
      title: _clearLogsTitle,
      message: _clearLogsMessage,
      confirmLabel: _clearLogsConfirmLabel,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!isConfirmed) {
      return;
    }
    if (_isShowingPersistedErrors) {
      await CrashLogRecorder.instance.clearEntries();
      _persistedErrors = const <String>[];
    } else {
      LoggerService.clearLogs();
    }
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_clearedMessage)),
    );
  }

  void _exportLogs() {
    final logs = _visibleLogs;
    final text = logs.join('\n');

    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${logs.length} logs copied to clipboard')),
    );
  }
}
