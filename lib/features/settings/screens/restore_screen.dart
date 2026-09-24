import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/restore';

  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  static const String _initialStatus = 'Paste backup JSON to restore';
  static const String _restoringStatus = 'Restoring...';
  static const String _restoredStatus = 'Restore completed';
  static const String _restoreFailedStatus = 'Restore failed';
  static const String _invalidJsonStatus = 'The pasted text is not valid backup data';

  final _controller = TextEditingController();
  String _status = _initialStatus;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Backup JSON',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: Text(_status)),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _restore,
              child: const Text('Restore Backup'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore() async {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(_controller.text) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      final mapped = ref.read(errorHandlerProvider).mapException(
            error,
            context: 'RestoreScreen.restore',
            stackTrace: stackTrace,
          );
      if (!mounted) return;
      setState(() => _status = _invalidJsonStatus);
      AppFeedback.showError(context, mapped);
      return;
    }

    setState(() => _status = _restoringStatus);
    final result = await ref.read(backupServiceProvider).restore(backup: json);
    if (!mounted) return;
    if (result.isFailure) {
      setState(() => _status = _restoreFailedStatus);
      AppFeedback.showError(context, result.error!);
      return;
    }
    setState(() => _status = _restoredStatus);
  }
}
