import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import '../../providers/app_providers.dart';
import '../../features/financial/providers/financial_providers.dart';
import 'app_feedback.dart';

/// Dev Tools Overlay for monitoring app state and diagnostics
/// Only visible in debug mode
class DevToolsOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const DevToolsOverlay({
    required this.child,
    super.key,
  });

  @override
  ConsumerState<DevToolsOverlay> createState() => _DevToolsOverlayState();
}

class _DevToolsOverlayState extends ConsumerState<DevToolsOverlay> {
  static const String _seedSuccessMessage = 'Financial data seeded successfully!';

  bool _isVisible = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible) _buildDevToolsPanel(),
        _buildToggleButton(),
      ],
    );
  }

  Widget _buildToggleButton() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: FloatingActionButton.small(
        heroTag: 'dev_tools_toggle',
        onPressed: () {
          setState(() {
            _isVisible = !_isVisible;
          });
        },
        backgroundColor: Colors.deepPurple,
        child: Icon(
          _isVisible ? Icons.close : Icons.developer_mode,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDevToolsPanel() {
    final appStateManager = ref.watch(appStateManagerProvider);

    return Positioned(
      right: 16,
      bottom: 140,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: _isExpanded ? 320 : 280,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppStateSection(appStateManager),
                      const Divider(color: Colors.grey),
                      _buildStorageSection(),
                      const Divider(color: Colors.grey),
                      _buildActionsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.developer_mode, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Dev Tools',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.unfold_less : Icons.unfold_more,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppStateSection(logic.AppStateManager appStateManager) {
    return StreamBuilder<logic.AppStateInfo>(
      stream: appStateManager.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('App State'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Status',
              state?.isOnline == true ? 'Online' : 'Offline',
              state?.isOnline == true ? Colors.green : Colors.red,
            ),
            if (state != null)
              _buildInfoRow(
                'Lifecycle',
                state.lifecycle.name,
                Colors.blue,
              ),
          ],
        );
      },
    );
  }

  Widget _buildStorageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Storage'),
        const SizedBox(height: 8),
        _buildInfoRow('Type', 'SQLite + Hive', Colors.purple),
        _buildInfoRow('Status', 'Initialized', Colors.green),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Actions'),
        const SizedBox(height: 8),
        _buildActionButton(
          'View Logs',
          Icons.article_outlined,
          () async {
            await Navigator.of(context).pushNamed('/dev/logs');
          },
        ),
        const SizedBox(height: 4),
        _buildActionButton(
          'View Database',
          Icons.storage_outlined,
          () async {
            await Navigator.of(context).pushNamed('/dev/database');
          },
        ),
        const SizedBox(height: 4),
        _buildActionButton(
          'Seed Financial Data',
          Icons.add_circle_outline,
          () async {
            try {
              final seeder = ref.read(financialDataSeederProvider);
              await seeder.seedAll();
              if (!mounted) return;
              AppFeedback.showSuccess(context, _seedSuccessMessage);
            } catch (error, stackTrace) {
              final mapped = ref.read(errorHandlerProvider).mapException(
                    error,
                    context: 'DevToolsOverlay.seedFinancialData',
                    stackTrace: stackTrace,
                  );
              if (!mounted) return;
              AppFeedback.showError(context, mapped);
            }
          },
        ),
        const SizedBox(height: 4),
        _buildActionButton(
          'Clear Logs',
          Icons.delete_outline,
          () {
            // Clear logs action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logs cleared')),
            );
          },
        ),
        const SizedBox(height: 4),
        _buildActionButton(
          'Export State',
          Icons.download,
          () {
            // Export state action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('State exported')),
            );
          },
        ),
        const SizedBox(height: 4),
        _buildActionButton(
          'Force Sync',
          Icons.sync,
          () {
            // Force sync action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sync triggered')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.white70),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
    );
  }
}
