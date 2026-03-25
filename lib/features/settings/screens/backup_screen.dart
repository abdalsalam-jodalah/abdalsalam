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
  String? _lastPath;

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
                setState(() => _status = 'Creating backup...');
                final backup = await ref.read(backupServiceProvider).createCompressedBackup(
                  tables: ref.read(backupTablesProvider),
                );
                if (backup.isFailure) {
                  setState(() => _status = backup.error.toString());
                  return;
                }

                final save = await ref.read(backupServiceProvider).saveBackupToDevice(
                      content: backup.data!,
                      fileName: 'abdalsalam-backup-${DateTime.now().millisecondsSinceEpoch}.b64',
                    );
                setState(() {
                  _lastPath = save.data;
                  _status = save.isSuccess
                      ? 'Backup saved: ${save.data}'
                      : save.error.toString();
                });
              },
              child: const Text('Create Full Backup'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _lastPath == null
                  ? null
                  : () async {
                      final share = await ref.read(backupServiceProvider).shareBackup(_lastPath!);
                      setState(() {
                        _status = share.isSuccess
                            ? 'Backup shared successfully'
                            : share.error.toString();
                      });
                    },
              child: const Text('Share Last Backup'),
            ),
          ],
        ),
      ),
    );
  }
}
