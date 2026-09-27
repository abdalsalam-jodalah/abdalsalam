import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

class BiometricLockScreen extends StatelessWidget {
  static const routeName = '/security/lock';
  static const String _moduleKey = 'security';
  static const double _iconBadgeSize = 96;

  const BiometricLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule(_moduleKey);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icon: Icons.fingerprint, color: accent, size: _iconBadgeSize),
            SizedBox(height: tokens.spacing.md),
            Text('Authenticate to unlock vault', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: tokens.spacing.md),
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
