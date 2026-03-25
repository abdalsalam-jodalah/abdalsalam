import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/restore';

  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _controller = TextEditingController();
  String _status = 'Paste backup JSON to restore';

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
              onPressed: () async {
                try {
                  final json = jsonDecode(_controller.text) as Map<String, dynamic>;
                  final result = await ref.read(backupServiceProvider).restore(backup: json);
                  setState(() {
                    _status = result.isSuccess ? 'Restore completed' : result.error.toString();
                  });
                } catch (e) {
                  setState(() => _status = 'Invalid JSON: $e');
                }
              },
              child: const Text('Restore Backup'),
            ),
          ],
        ),
      ),
    );
  }
}
