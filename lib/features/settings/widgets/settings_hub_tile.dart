import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/entity_tile.dart';

class SettingsHubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;
  final VoidCallback onTap;

  const SettingsHubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return EntityTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
