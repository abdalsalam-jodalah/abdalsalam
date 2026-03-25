import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';

class BackupScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/backup';

  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String _status = 'No backup started';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final backup = await ref.read(backupServiceProvider).createCompressedBackup(
                  tables: ref.read(backupTablesProvider),
                );
                setState(() {
                  _status = backup.isSuccess
                      ? 'Backup created (${backup.data!.length} bytes)'
                      : backup.error.toString();
                });
              },
              child: const Text('Create Full Backup'),
            ),
          ],
        ),
      ),
    );
  }
}
