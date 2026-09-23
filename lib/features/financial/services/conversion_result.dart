class ConversionResult {
  final double convertedAmount;
  final double rateUsed;
  final DateTime rateDate;
  final bool wasFallback;

  const ConversionResult({
    required this.convertedAmount,
    required this.rateUsed,
    required this.rateDate,
    required this.wasFallback,
  });
}
