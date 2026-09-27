import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import '../../providers/app_providers.dart';
import '../../features/financial/providers/financial_providers.dart';
import '../../core/theme/app_theme_tokens.dart';
import 'app_feedback.dart';
import 'dev_action_button.dart';
import 'dev_info_row.dart';
import 'ui/component_gallery_screen.dart';
import 'ui/glass_surface.dart';

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
  static const String _title = 'Dev Tools';
  static const String _appStateTitle = 'App State';
  static const String _storageTitle = 'Storage';
  static const String _actionsTitle = 'Actions';
  static const String _statusLabel = 'Status';
  static const String _lifecycleLabel = 'Lifecycle';
  static const String _typeLabel = 'Type';
  static const String _onlineValue = 'Online';
  static const String _offlineValue = 'Offline';
  static const String _storageTypeValue = 'SQLite + Hive';
  static const String _initializedValue = 'Initialized';
  static const String _componentGalleryLabel = 'Component Gallery';
  static const String _viewLogsLabel = 'View Logs';
  static const String _viewDatabaseLabel = 'View Database';
  static const String _seedFinancialDataLabel = 'Seed Financial Data';
  static const String _clearLogsLabel = 'Clear Logs';
  static const String _exportStateLabel = 'Export State';
  static const String _forceSyncLabel = 'Force Sync';
  static const String _logsClearedMessage = 'Logs cleared';
  static const String _stateExportedMessage = 'State exported';
  static const String _syncTriggeredMessage = 'Sync triggered';
  static const String _logsRoute = '/dev/logs';
  static const String _databaseRoute = '/dev/database';

  static const double _toggleRight = 16;
  static const double _toggleBottom = 80;
  static const double _panelRight = 16;
  static const double _panelBottom = 140;
  static const double _collapsedWidth = 280;
  static const double _expandedWidth = 320;
  static const double _maxHeightFraction = 0.7;
  static const double _headerIconSize = 20;

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
      right: _toggleRight,
      bottom: _toggleBottom,
      child: FloatingActionButton.small(
        heroTag: 'dev_tools_toggle',
        onPressed: () {
          setState(() {
            _isVisible = !_isVisible;
          });
        },
        child: Icon(_isVisible ? Icons.close_rounded : Icons.developer_mode_rounded),
      ),
    );
  }

  Widget _buildDevToolsPanel() {
    final appStateManager = ref.watch(appStateManagerProvider);
    final tokens = AppThemeTokens.of(context);

    return Positioned(
      right: _panelRight,
      bottom: _panelBottom,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * _maxHeightFraction),
        child: GlassSurface(
          isBlurred: true,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: _isExpanded ? _expandedWidth : _collapsedWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(tokens),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(tokens.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppStateSection(tokens, appStateManager),
                        const Divider(),
                        _buildStorageSection(tokens),
                        const Divider(),
                        _buildActionsSection(tokens),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeTokens tokens) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(tokens.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.vertical(top: tokens.radius.largeBorder.topLeft),
      ),
      child: Row(
        children: [
          Icon(Icons.developer_mode_rounded, color: colorScheme.onTertiaryContainer, size: _headerIconSize),
          SizedBox(width: tokens.spacing.sm),
          Text(
            _title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              color: colorScheme.onTertiaryContainer,
              size: _headerIconSize,
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

  Widget _buildAppStateSection(AppThemeTokens tokens, logic.AppStateManager appStateManager) {
    return StreamBuilder<logic.AppStateInfo>(
      stream: appStateManager.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(_appStateTitle),
            SizedBox(height: tokens.spacing.sm),
            DevInfoRow(
              label: _statusLabel,
              value: state?.isOnline == true ? _onlineValue : _offlineValue,
              accentColor: state?.isOnline == true ? tokens.colors.success : tokens.colors.danger,
            ),
            if (state != null)
              DevInfoRow(label: _lifecycleLabel, value: state.lifecycle.name, accentColor: tokens.colors.info),
          ],
        );
      },
    );
  }

  Widget _buildStorageSection(AppThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_storageTitle),
        SizedBox(height: tokens.spacing.sm),
        DevInfoRow(label: _typeLabel, value: _storageTypeValue, accentColor: tokens.colors.info),
        DevInfoRow(label: _statusLabel, value: _initializedValue, accentColor: tokens.colors.success),
      ],
    );
  }

  Widget _buildActionsSection(AppThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_actionsTitle),
        SizedBox(height: tokens.spacing.sm),
        DevActionButton(
          label: _componentGalleryLabel,
          icon: Icons.palette_outlined,
          onPressed: () async {
            await Navigator.of(context).pushNamed(ComponentGalleryScreen.routeName);
          },
        ),
        SizedBox(height: tokens.spacing.xs),
        DevActionButton(
          label: _viewLogsLabel,
          icon: Icons.article_outlined,
          onPressed: () async {
            await Navigator.of(context).pushNamed(_logsRoute);
          },
        ),
        SizedBox(height: tokens.spacing.xs),
        DevActionButton(
          label: _viewDatabaseLabel,
          icon: Icons.storage_outlined,
          onPressed: () async {
            await Navigator.of(context).pushNamed(_databaseRoute);
          },
        ),
        SizedBox(height: tokens.spacing.xs),
        DevActionButton(
          label: _seedFinancialDataLabel,
          icon: Icons.add_circle_outline,
          onPressed: () async {
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
        SizedBox(height: tokens.spacing.xs),
        DevActionButton(
          label: _clearLogsLabel,
          icon: Icons.delete_outline_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(_logsClearedMessage)),
            );
          },
        ),
        SizedBox(height: tokens.spacing.xs),
        DevActionButton(
          label: _exportStateLabel,
          icon: Icons.download_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(_stateExportedMessage)),
            );
          },
        ),
        SizedBox(height: tokens.spacing.xs),
        DevActionButton(
          label: _forceSyncLabel,
          icon: Icons.sync_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(_syncTriggeredMessage)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold));
  }
}
