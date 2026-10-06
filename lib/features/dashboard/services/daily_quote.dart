import 'daily_quote_category.dart';

class DailyQuote {
  final DailyQuoteCategory category;
  final String arabic;
  final String english;
  final String sourceArabic;
  final String sourceEnglish;

  const DailyQuote({
    required this.category,
    required this.arabic,
    required this.english,
    required this.sourceArabic,
    required this.sourceEnglish,
  });
}
