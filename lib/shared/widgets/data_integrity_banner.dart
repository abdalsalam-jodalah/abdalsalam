import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import 'log_viewer_screen.dart';

class DataIntegrityBanner extends ConsumerWidget {
  static const String _viewLabel = 'View';
  static const double _horizontalPadding = 12;
  static const double _verticalPadding = 6;
  static const double _iconSpacing = 8;

  final GlobalKey<NavigatorState> navigatorKey;

  const DataIntegrityBanner({super.key, required this.navigatorKey});

  static String messageFor(int corruptRecordCount) {
    return corruptRecordCount == 1
        ? '1 saved record could not be read and is hidden.'
        : '$corruptRecordCount saved records could not be read and are hidden.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corruptRecordCount = ref.watch(corruptRecordCountProvider).valueOrNull ?? 0;
    if (corruptRecordCount == 0) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: _verticalPadding),
          child: Row(
            children: [
              Icon(Icons.report_gmailerrorred, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: _iconSpacing),
              Expanded(
                child: Text(
                  messageFor(corruptRecordCount),
                  style: TextStyle(color: colorScheme.onTertiaryContainer),
                ),
              ),
              TextButton(
                onPressed: () => navigatorKey.currentState?.pushNamed(LogViewerScreen.routeName),
                child: const Text(_viewLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
