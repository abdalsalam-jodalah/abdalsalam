import 'daily_quote.dart';
import 'daily_quote_category.dart';
import 'daily_quotes.dart';

class DailyQuoteSelector {
  static const List<DailyQuoteCategory> _rotation = DailyQuoteCategory.values;

  const DailyQuoteSelector._();

  static int dayNumber(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(1970)).inDays;
  }

  static DailyQuote forDate(DateTime date, {int shift = 0, List<DailyQuote> quotes = DailyQuotes.all}) {
    final day = dayNumber(date) + shift;
    final category = _rotation[day % _rotation.length];
    final pool = quotes.where((quote) => quote.category == category).toList(growable: false);
    final candidates = pool.isEmpty ? quotes : pool;
    return candidates[(day ~/ _rotation.length) % candidates.length];
  }
}
