class CorruptRecordReport {
  final String table;
  final String recordId;
  final String reason;
  final DateTime detectedAt;

  const CorruptRecordReport({
    required this.table,
    required this.recordId,
    required this.reason,
    required this.detectedAt,
  });
}
