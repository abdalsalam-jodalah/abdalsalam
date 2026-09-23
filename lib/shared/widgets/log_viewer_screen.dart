import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../infrastructure/crash_log_recorder.dart';
import '../infrastructure/logger_service.dart';

/// Log Viewer Screen for viewing app logs
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isShowingPersistedErrors = false;
  List<String> _persistedErrors = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadPersistedErrors();
  }

  Future<void> _loadPersistedErrors() async {
    final entries = await CrashLogRecorder.instance.readEntries();
    if (!mounted) {
      return;
    }
    setState(() => _persistedErrors = entries);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isShowingPersistedErrors ? 'Saved Errors' : 'Log Viewer'),
        actions: [
          IconButton(
            icon: Icon(_isShowingPersistedErrors ? Icons.list_alt : Icons.history),
            onPressed: () => setState(() => _isShowingPersistedErrors = !_isShowingPersistedErrors),
            tooltip: _isShowingPersistedErrors ? 'Show Session Logs' : 'Show Saved Errors',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearLogs,
            tooltip: 'Clear Logs',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
            tooltip: 'Export Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search logs...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildLogList() {
    final logs = _visibleLogs;
    final filteredLogs = logs.where((log) {
      return _searchQuery.isEmpty || log.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No logs found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[filteredLogs.length - 1 - index]; // Reverse order
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(String log) {
    final color = _getLogLevelColor(log);
    final level = _extractLogLevel(log);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        onLongPress: () => _copyLogToClipboard(log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _extractModule(log),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _extractTime(log),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _extractMessage(log),
                style: const TextStyle(fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLogLevelColor(String log) {
    if (log.contains('[DEBUG]')) return Colors.grey;
    if (log.contains('[INFO]')) return Colors.blue;
    if (log.contains('[WARN]')) return Colors.orange;
    if (log.contains('[ERROR]')) return Colors.red;
    if (log.contains('[FATAL]')) return Colors.purple;
    return Colors.grey;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getLogLevelColor(log).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _extractLogLevel(log),
                style: TextStyle(
                  color: _getLogLevelColor(log),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _extractModule(log),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            log,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _copyLogToClipboard(log);
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _copyLogToClipboard(String log) {
    Clipboard.setData(ClipboardData(text: log));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  void _confirmClearLogs() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
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
                const SnackBar(content: Text('Logs cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    final logs = _visibleLogs;
    final text = logs.join('\n');

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${logs.length} logs copied to clipboard')),
    );
  }
}
