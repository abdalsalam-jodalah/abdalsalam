import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class StartupStatusBanner extends ConsumerStatefulWidget {
  const StartupStatusBanner({super.key});

  @override
  ConsumerState<StartupStatusBanner> createState() => _StartupStatusBannerState();
}

class _StartupStatusBannerState extends ConsumerState<StartupStatusBanner> {
  static const String _messagePrefix = 'Some features failed to start: ';
  static const String _dismissTooltip = 'Dismiss';
  static const double _horizontalPadding = 12;
  static const double _verticalPadding = 8;
  static const double _iconSpacing = 8;

  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(startupReportProvider);
    if (_isDismissed || !report.isDegraded) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: _verticalPadding),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer),
              const SizedBox(width: _iconSpacing),
              Expanded(
                child: Text(
                  '$_messagePrefix${report.degradedStepNames.join(', ')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
                ),
              ),
              IconButton(
                tooltip: _dismissTooltip,
                icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
                onPressed: () => setState(() => _isDismissed = true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
