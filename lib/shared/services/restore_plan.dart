class RestorePlan {
  final Map<String, List<Map<String, dynamic>>> rowsByTable;
  final Map<String, dynamic> preferences;
  final int skippedRowCount;
  final List<String> unknownTables;

  const RestorePlan({
    required this.rowsByTable,
    required this.preferences,
    required this.skippedRowCount,
    required this.unknownTables,
  });
}
