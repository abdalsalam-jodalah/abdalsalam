import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/services/user_error_message_mapper.dart';
import 'critical_startup_failure.dart';
import 'startup_error_details.dart';

class StartupRecoveryScreen extends StatelessWidget {
  static const String _title = "The app couldn't start";
  static const String _retryLabel = 'Try again';
  static const String _copyLabel = 'Copy error details';
  static const String _copiedMessage = 'Error details copied to clipboard';
  static const double _padding = 24;
  static const double _spacing = 16;
  static const double _iconSize = 56;

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  const StartupRecoveryScreen({
    super.key,
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  Object get _rootError {
    final startupError = error;
    return startupError is CriticalStartupFailure ? startupError.failure.error : startupError;
  }

  String? get _failedStepName {
    final startupError = error;
    return startupError is CriticalStartupFailure ? startupError.failure.stepName : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepName = _failedStepName;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: _iconSize, color: theme.colorScheme.error),
                const SizedBox(height: _spacing),
                Text(_title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: _spacing),
                Text(
                  const UserErrorMessageMapper().toUserMessage(_rootError),
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (stepName != null) ...[
                  const SizedBox(height: _spacing / 2),
                  Text('Failed step: $stepName', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                ],
                const SizedBox(height: _spacing * 2),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text(_retryLabel),
                ),
                const SizedBox(height: _spacing / 2),
                TextButton.icon(
                  onPressed: () => _copyErrorDetails(context),
                  icon: const Icon(Icons.copy),
                  label: const Text(_copyLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyErrorDetails(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final details = await const StartupErrorDetails().build(error, stackTrace);
    await Clipboard.setData(ClipboardData(text: details));
    messenger.showSnackBar(const SnackBar(content: Text(_copiedMessage)));
  }
}
