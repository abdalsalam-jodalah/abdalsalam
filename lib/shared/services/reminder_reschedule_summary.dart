class ReminderRescheduleSummary {
  final int rescheduledCount;
  final int skippedCount;
  final int failedCount;

  const ReminderRescheduleSummary({
    required this.rescheduledCount,
    required this.skippedCount,
    required this.failedCount,
  });

  bool get hasFailures => failedCount > 0;
}
