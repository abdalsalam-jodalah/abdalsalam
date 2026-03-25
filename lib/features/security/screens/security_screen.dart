import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class SecurityScreen extends StatelessWidget {
  static const routeName = '/security';

  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Security Vault',
      description: 'Store credentials safely with encryption and biometric access.',
      icon: Icons.lock_outline,
      metrics: [
        SectionMetric(label: 'Stored Entries', value: '18'),
        SectionMetric(label: 'Weak Passwords', value: '2'),
        SectionMetric(label: '2FA Enabled', value: '11'),
        SectionMetric(label: 'Last Audit', value: '2d ago'),
      ],
      focusItems: [
        'Rotate weak passwords',
        'Enable biometrics lock',
        'Backup encrypted vault',
      ],
      initialActivities: [
        'Password updated: Email account',
        'Security check completed',
      ],
      quickAddHint: 'Example: GitHub personal token',
    );
  }
}
