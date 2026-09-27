import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../widgets/security_widgets.dart';

class CredentialListScreen extends StatelessWidget {
  static const routeName = '/security/credentials';
  static const int _sampleCredentialCount = 4;

  const CredentialListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Credentials')),
      body: ListView.separated(
        padding: EdgeInsets.all(tokens.spacing.lg),
        itemCount: _sampleCredentialCount,
        separatorBuilder: (context, index) => SizedBox(height: tokens.spacing.sm),
        itemBuilder: (context, index) => CredentialCard(
          title: 'Account ${index + 1}',
          username: 'user${index + 1}@mail.com',
          maskedPassword: '••••••••••••',
          onReveal: () {},
        ),
      ),
    );
  }
}
