import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/progress_bar.dart';

class CredentialCard extends StatelessWidget {
  static const String _moduleKey = 'security';

  final String title;
  final String username;
  final String maskedPassword;
  final VoidCallback onReveal;

  const CredentialCard({
    super.key,
    required this.title,
    required this.username,
    required this.maskedPassword,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return EntityTile(
      icon: Icons.key_outlined,
      accentColor: AppModuleAccents.forModule(_moduleKey),
      title: title,
      subtitle: '$username\n$maskedPassword',
      subtitleMaxLines: 2,
      trailing: IconButton(
        icon: const Icon(Icons.visibility_outlined),
        onPressed: onReveal,
      ),
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  static const int _strongThreshold = 70;
  static const int _mediumThreshold = 40;

  final int value;

  const PasswordStrengthIndicator({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final color = value >= _strongThreshold
        ? tokens.colors.success
        : value >= _mediumThreshold
            ? tokens.colors.warning
            : tokens.colors.danger;
    final label = value >= _strongThreshold
        ? 'Strong'
        : value >= _mediumThreshold
            ? 'Medium'
            : 'Weak';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressBar(value: value / 100, color: color),
        SizedBox(height: tokens.spacing.xs),
        Text('$label ($value/100)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class PasswordGeneratorWidget extends StatelessWidget {
  static const String _monospaceFontFamily = 'monospace';

  final String password;
  final VoidCallback onGenerate;

  const PasswordGeneratorWidget({
    super.key,
    required this.password,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generated Password', style: textTheme.titleSmall),
          SizedBox(height: tokens.spacing.sm),
          SelectableText(
            password,
            style: textTheme.bodyLarge?.copyWith(fontFamily: _monospaceFontFamily),
          ),
          SizedBox(height: tokens.spacing.md),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Generate Again'),
          ),
        ],
      ),
    );
  }
}
