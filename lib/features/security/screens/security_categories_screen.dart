import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class SecurityCategoriesScreen extends StatelessWidget {
  static const routeName = '/security/categories';
  static const String _moduleKey = 'security';
  static const List<String> _categories = ['Banking', 'Email', 'Social Media', 'Work', 'Personal'];

  const SecurityCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule(_moduleKey);
    return Scaffold(
      appBar: AppBar(title: const Text('Credential Categories')),
      body: ListView.separated(
        padding: EdgeInsets.all(tokens.spacing.lg),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => SizedBox(height: tokens.spacing.sm),
        itemBuilder: (context, index) => EntityTile(
          icon: Icons.folder_outlined,
          accentColor: accent,
          title: _categories[index],
        ),
      ),
    );
  }
}
