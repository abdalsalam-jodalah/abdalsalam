import 'package:flutter/material.dart';

import 'biometric_lock_screen.dart';
import 'credential_form_screen.dart';
import 'credential_list_screen.dart';
import 'password_generator_screen.dart';
import 'security_categories_screen.dart';

class SecurityScreen extends StatelessWidget {
  static const routeName = '/security';

  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Vault')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Vault Status', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Biometric protection enabled and auto-lock set to 5 minutes.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.fingerprint,
            title: 'Biometric Lock',
            subtitle: 'Authenticate to open vault',
            route: BiometricLockScreen.routeName,
          ),
          _tile(
            context,
            icon: Icons.key_outlined,
            title: 'Credentials',
            subtitle: 'Browse masked credentials',
            route: CredentialListScreen.routeName,
          ),
          _tile(
            context,
            icon: Icons.add_card,
            title: 'Add Credential',
            subtitle: 'Save a new account safely',
            route: CredentialFormScreen.routeName,
          ),
          _tile(
            context,
            icon: Icons.password_outlined,
            title: 'Password Generator',
            subtitle: 'Generate strong random passwords',
            route: PasswordGeneratorScreen.routeName,
          ),
          _tile(
            context,
            icon: Icons.category_outlined,
            title: 'Categories',
            subtitle: 'Organize credentials by type',
            route: SecurityCategoriesScreen.routeName,
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed(route),
      ),
    );
  }
}
