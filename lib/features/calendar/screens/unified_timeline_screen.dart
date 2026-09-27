import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../widgets/calendar_widgets.dart';

class UnifiedTimelineScreen extends StatelessWidget {
  static const routeName = '/calendar/timeline';
  static const String _moduleKey = 'calendar';

  const UnifiedTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule(_moduleKey);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Unified Timeline')),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: TimelineView(
          items: [
            EntityTile(
              icon: Icons.mosque_rounded,
              accentColor: accent,
              title: 'Prayer Reminder',
              subtitle: 'Maghrib in 10 minutes',
              trailing: Text('18:12', style: textTheme.labelLarge),
            ),
            EntityTile(
              icon: Icons.fitness_center_rounded,
              accentColor: accent,
              title: 'Workout Session',
              subtitle: 'Push day',
              trailing: Text('19:00', style: textTheme.labelLarge),
            ),
            EntityTile(
              icon: Icons.medication_rounded,
              accentColor: accent,
              title: 'Medication',
              subtitle: 'Vitamin D dose',
              trailing: Text('21:00', style: textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}
