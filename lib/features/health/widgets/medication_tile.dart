import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/medication.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

class MedicationTile extends StatelessWidget {
  final Medication medication;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationTile({
    super.key,
    required this.medication,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = AppModuleAccents.forModule('health');
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.drag_handle_rounded, color: theme.colorScheme.outline),
          SizedBox(width: tokens.spacing.sm),
          IconBadge(icon: Icons.medication_outlined, color: accent),
          SizedBox(width: tokens.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  medication.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    decoration: medication.isActive ? null : TextDecoration.lineThrough,
                    color: medication.isActive ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text('${medication.dosage} • ${medication.frequency}', style: mutedStyle),
                Text('Times: ${medication.reminderTimes.join(", ")}', style: mutedStyle),
                if (medication.timing != MedicationTiming.anytime)
                  Text('Take: ${medication.timingLabel}', style: mutedStyle),
                if (medication.frequency == 'Weekly' && medication.weekDays.isNotEmpty)
                  Text('Days: ${medication.weekDaysLabel}', style: mutedStyle),
              ],
            ),
          ),
          PopupMenuButton<void>(
            itemBuilder: (menuContext) => [
              PopupMenuItem<void>(
                onTap: () => Future.delayed(Duration.zero, onToggleActive),
                child: Row(
                  children: [
                    Icon(medication.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    SizedBox(width: tokens.spacing.sm),
                    Text(medication.isActive ? 'Pause' : 'Resume'),
                  ],
                ),
              ),
              PopupMenuItem<void>(
                onTap: () => Future.delayed(Duration.zero, onEdit),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined),
                    SizedBox(width: tokens.spacing.sm),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<void>(
                onTap: () => Future.delayed(Duration.zero, onDelete),
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: tokens.colors.danger),
                    SizedBox(width: tokens.spacing.sm),
                    Text('Delete', style: theme.textTheme.bodyMedium?.copyWith(color: tokens.colors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
