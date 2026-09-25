import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../core/constants/dashboard_card_catalog.dart';

class DashboardAgendaCard extends StatelessWidget {
  const DashboardAgendaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final items = <(IconData, String, String, String)>[
      (Icons.mosque_rounded, 'Maghrib', 'in 40 min', 'religious'),
      (Icons.medication_rounded, 'Vitamin D', '20:00', 'medications'),
      (Icons.fitness_center_rounded, 'Push session', '19:00', 'sports'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: DashboardCardCatalog.labels[DashboardCardCatalog.agenda]!),
        for (final (icon, title, time, module) in items)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: EntityTile(
              icon: icon,
              accentColor: AppModuleAccents.forModule(module),
              title: title,
              trailing: Text(time, style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
      ],
    );
  }
}
