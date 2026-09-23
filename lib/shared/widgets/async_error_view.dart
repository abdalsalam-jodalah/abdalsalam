import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class AsyncErrorView extends ConsumerWidget {
  static const String _retryLabel = 'Retry';
  static const double _padding = 24;
  static const double _compactPadding = 12;
  static const double _iconSize = 48;
  static const double _compactIconSize = 24;
  static const double _spacing = 12;

  final Object error;
  final VoidCallback? onRetry;
  final bool isCompact;

  const AsyncErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(userErrorMessageMapperProvider).toUserMessage(error);
    final colorScheme = Theme.of(context).colorScheme;
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.all(_compactPadding),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: _compactIconSize),
            const SizedBox(width: _spacing),
            Expanded(child: Text(message)),
            if (onRetry != null) TextButton(onPressed: onRetry, child: const Text(_retryLabel)),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: _iconSize),
            const SizedBox(height: _spacing),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (onRetry != null) ...[
              const SizedBox(height: _spacing),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(_retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
