class QuranLegacyImportReport {
  final int importedCount;
  final int alreadyImportedCount;
  final List<String> skippedLegacyIds;

  const QuranLegacyImportReport({
    required this.importedCount,
    required this.alreadyImportedCount,
    required this.skippedLegacyIds,
  });

  bool get hasSkippedEntries => skippedLegacyIds.isNotEmpty;
}
