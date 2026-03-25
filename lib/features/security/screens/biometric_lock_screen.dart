import 'package:flutter/material.dart';

class BiometricLockScreen extends StatelessWidget {
  static const routeName = '/security/lock';

  const BiometricLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 80),
            const SizedBox(height: 12),
            const Text('Authenticate to unlock vault'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Use Biometrics'),
            ),
          ],
        ),
      ),
    );
  }
}
