import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class EventListScreen extends StatelessWidget {
  static const routeName = '/calendar/events';
  static const int _sampleEventCount = 5;
  static const String _moduleKey = 'calendar';

  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule(_moduleKey);
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda View')),
      body: ListView.separated(
        padding: EdgeInsets.all(tokens.spacing.lg),
        itemCount: _sampleEventCount,
        separatorBuilder: (context, index) => SizedBox(height: tokens.spacing.sm),
        itemBuilder: (context, index) => EntityTile(
          icon: Icons.event_rounded,
          accentColor: accent,
          title: 'Event ${index + 1}',
          subtitle: 'Agenda item details',
          trailing: Text('${9 + index}:00', style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}
