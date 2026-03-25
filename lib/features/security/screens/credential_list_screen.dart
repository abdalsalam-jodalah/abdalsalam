import 'package:flutter/material.dart';

import '../widgets/security_widgets.dart';

class CredentialListScreen extends StatelessWidget {
  static const routeName = '/security/credentials';

  const CredentialListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credentials')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return CredentialCard(
            title: 'Account ${index + 1}',
            username: 'user${index + 1}@mail.com',
            maskedPassword: '••••••••••••',
            onReveal: () {},
          );
        },
      ),
    );
  }
}
