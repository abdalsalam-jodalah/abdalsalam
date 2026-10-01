// lib/shared/services/export_row_enricher.dart — contract for adding human-readable columns to exported rows.

abstract class ExportRowEnricher {
  Map<String, List<Map<String, dynamic>>> enrich(Map<String, List<Map<String, dynamic>>> rowsByTable);
}
