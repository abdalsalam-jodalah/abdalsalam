class RestoreReport {
  final int restoredTableCount;
  final int restoredRowCount;
  final int skippedRowCount;
  final int restoredPreferenceCount;
  final List<String> skippedUnknownTables;
  final String safetyBackupPath;

  const RestoreReport({
    required this.restoredTableCount,
    required this.restoredRowCount,
    required this.skippedRowCount,
    required this.restoredPreferenceCount,
    required this.skippedUnknownTables,
    required this.safetyBackupPath,
  });
}
