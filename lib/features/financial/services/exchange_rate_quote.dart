class ExchangeRateQuote {
  final double rate;
  final DateTime? fetchedAt;
  final bool isFallback;

  const ExchangeRateQuote({
    required this.rate,
    required this.fetchedAt,
    required this.isFallback,
  });
}
