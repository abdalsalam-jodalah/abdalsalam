import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import 'biometric_lock_screen.dart';
import 'credential_form_screen.dart';
import 'credential_list_screen.dart';
import 'password_generator_screen.dart';
import 'security_categories_screen.dart';

class SecurityScreen extends StatelessWidget {
  static const routeName = '/security';
  static const String _moduleKey = 'security';

  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = AppModuleAccents.forModule(_moduleKey);
    return Scaffold(
      appBar: AppBar(title: const Text('Security Vault')),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [
          AppCard(
            accentColor: accent,
            child: Row(
              children: [
                IconBadge(icon: Icons.shield_rounded, color: accent),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vault Status', style: theme.textTheme.titleMedium),
                      SizedBox(height: tokens.spacing.xs),
                      Text(
                        'Biometric protection enabled and auto-lock set to 5 minutes.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          EntityTile(
            icon: Icons.fingerprint,
            accentColor: accent,
            title: 'Biometric Lock',
            subtitle: 'Authenticate to open vault',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(BiometricLockScreen.routeName),
          ),
          SizedBox(height: tokens.spacing.sm),
          EntityTile(
            icon: Icons.key_outlined,
            accentColor: accent,
            title: 'Credentials',
            subtitle: 'Browse masked credentials',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(CredentialListScreen.routeName),
          ),
          SizedBox(height: tokens.spacing.sm),
          EntityTile(
            icon: Icons.add_card,
            accentColor: accent,
            title: 'Add Credential',
            subtitle: 'Save a new account safely',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(CredentialFormScreen.routeName),
          ),
          SizedBox(height: tokens.spacing.sm),
          EntityTile(
            icon: Icons.password_outlined,
            accentColor: accent,
            title: 'Password Generator',
            subtitle: 'Generate strong random passwords',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(PasswordGeneratorScreen.routeName),
          ),
          SizedBox(height: tokens.spacing.sm),
          EntityTile(
            icon: Icons.category_outlined,
            accentColor: accent,
            title: 'Categories',
            subtitle: 'Organize credentials by type',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(SecurityCategoriesScreen.routeName),
          ),
        ],
      ),
    );
  }
}
