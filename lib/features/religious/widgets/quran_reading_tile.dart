import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../data/models/religious/quran_reading.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class QuranReadingTile extends StatelessWidget {
  final QuranReading log;

  const QuranReadingTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EntityTile(
      icon: Icons.menu_book_outlined,
      accentColor: scheme.secondary,
      title: log.surahNumber == 0 ? '${log.pagesRead} pages' : 'Surah ${log.surahNumber}: ${log.ayahFrom}-${log.ayahTo}',
      subtitle: '${log.pagesRead} pages • ${log.durationMinutes} min'
          '${log.place != null ? ' • ${log.place}' : ''}'
          ' • ${AppDateFormatter.time(log.readAt)}'
          '${log.memorized ? ' • Memorized' : ''}',
      trailing: log.memorized ? Icon(Icons.bookmark, color: scheme.secondary) : null,
    );
  }
}
