// lib/features/sync/widgets/sync_host_panel.dart — Mac side of the hub: cable check, link controls, PIN, progress and history.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../settings/widgets/settings_section_header.dart';
import '../providers/sync_host_state.dart';
import '../providers/sync_providers.dart';
import 'sync_connection_card.dart';
import 'sync_history_section.dart';
import 'sync_manual_command_card.dart';
import 'sync_pin_card.dart';
import 'sync_progress_card.dart';
import 'sync_report_navigator.dart';

class SyncHostPanel extends ConsumerStatefulWidget {
  const SyncHostPanel({super.key});

  @override
  ConsumerState<SyncHostPanel> createState() => _SyncHostPanelState();
}

class _SyncHostPanelState extends ConsumerState<SyncHostPanel> {
  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.microtask(() => ref.read(syncHostControllerProvider.notifier).refreshAdbStatus()));
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final state = ref.watch(syncHostControllerProvider);
    final controller = ref.read(syncHostControllerProvider.notifier);
    ref.listen<SyncHostState>(syncHostControllerProvider, _openReportOnCompletion);
    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        const SettingsSectionHeader(SyncUiText.connectionSection),
        SyncConnectionCard(
          status: state.adbStatus,
          isChecking: state.isCheckingAdb,
          onCheckAgain: state.isLinkOpen ? controller.openTunnel : controller.refreshAdbStatus,
        ),
        if (state.manualCommand != null) ...[
          SizedBox(height: spacing.md),
          SyncManualCommandCard(command: state.manualCommand!, failureReason: _failureReason(state)),
        ],
        const SettingsSectionHeader(SyncUiText.linkSection),
        SyncPinCard(
          pin: state.hostInfo?.pin,
          linkState: state.linkState,
          onStart: _startLink,
          onStop: controller.stopLink,
        ),
        if (state.isLinkOpen) ...[
          const SettingsSectionHeader(SyncUiText.progressSection),
          SyncProgressCard(event: state.progress),
        ],
        const SyncHistorySection(),
      ],
    );
  }

  String? _failureReason(SyncHostState state) {
    return state.reverseFailure ?? state.adbStatus?.detail;
  }

  Future<void> _startLink() async {
    final error = await ref.read(syncHostControllerProvider.notifier).startLink();
    if (error != null && mounted) {
      AppFeedback.showError(context, error);
    }
  }

  void _openReportOnCompletion(SyncHostState? previous, SyncHostState next) {
    final report = next.lastReport;
    if (report == null || report == previous?.lastReport || !mounted) {
      return;
    }
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      unawaited(SyncReportNavigator.open(context, report));
    }
  }
}
