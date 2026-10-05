// lib/features/sync/widgets/sync_join_panel.dart — phone side of the hub: PIN entry, sync button, progress and history.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sync_constants.dart';
import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../settings/widgets/settings_section_header.dart';
import '../providers/sync_providers.dart';
import 'sync_history_section.dart';
import 'sync_progress_card.dart';
import 'sync_report_navigator.dart';

class SyncJoinPanel extends ConsumerStatefulWidget {
  const SyncJoinPanel({super.key});

  @override
  ConsumerState<SyncJoinPanel> createState() => _SyncJoinPanelState();
}

class _SyncJoinPanelState extends ConsumerState<SyncJoinPanel> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final state = ref.watch(syncJoinControllerProvider);
    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        const SettingsSectionHeader(SyncUiText.phoneSection),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(SyncUiText.phoneInstructions),
              SizedBox(height: spacing.md),
              TextField(
                controller: _pinController,
                enabled: !state.isJoining,
                keyboardType: TextInputType.number,
                maxLength: SyncConstants.pinLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: SyncUiText.pinFieldLabel),
                onSubmitted: (_) => _syncNow(),
              ),
              SizedBox(height: spacing.sm),
              FilledButton.icon(
                onPressed: state.isJoining ? null : _syncNow,
                icon: const Icon(Icons.sync_rounded),
                label: Text(state.isJoining ? SyncUiText.syncingLabel : SyncUiText.syncNowLabel),
              ),
            ],
          ),
        ),
        if (state.isJoining || state.progress != null) ...[
          const SettingsSectionHeader(SyncUiText.progressSection),
          SyncProgressCard(event: state.progress),
        ],
        const SyncHistorySection(),
      ],
    );
  }

  Future<void> _syncNow() async {
    final outcome = await ref.read(syncJoinControllerProvider.notifier).join(_pinController.text);
    if (!mounted) return;
    if (outcome.isFailure) {
      AppFeedback.showError(context, outcome.error!);
      return;
    }
    _pinController.clear();
    await SyncReportNavigator.open(context, outcome.data!);
  }
}
