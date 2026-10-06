import 'package:abdalsalam/features/dashboard/services/daily_quote.dart';
import 'package:abdalsalam/features/dashboard/services/daily_quote_category.dart';
import 'package:abdalsalam/features/dashboard/services/daily_quote_selector.dart';
import 'package:abdalsalam/features/dashboard/services/daily_quotes.dart';
import 'package:flutter_test/flutter_test.dart';

final RegExp _arabicLetters = RegExp(r'[؀-ۿ]');
final RegExp _latinLetters = RegExp(r'[A-Za-z]');

void main() {
  group('DailyQuotes library', () {
    test('should hold a large collection with enough quotes in every category', () {
      expect(DailyQuotes.all.length, greaterThanOrEqualTo(50));
      for (final category in DailyQuoteCategory.values) {
        final count = DailyQuotes.all.where((quote) => quote.category == category).length;
        expect(count, greaterThanOrEqualTo(10), reason: '${category.name} has only $count quotes');
      }
    });

    test('should give every quote text and a source in both languages', () {
      for (final quote in DailyQuotes.all) {
        expect(quote.arabic.trim(), isNotEmpty);
        expect(quote.english.trim(), isNotEmpty);
        expect(quote.sourceArabic.trim(), isNotEmpty, reason: quote.english);
        expect(quote.sourceEnglish.trim(), isNotEmpty, reason: quote.english);
      }
    });

    test('should keep Arabic text in Arabic and English text in English', () {
      for (final quote in DailyQuotes.all) {
        expect(_arabicLetters.hasMatch(quote.arabic), isTrue, reason: quote.english);
        expect(_latinLetters.hasMatch(quote.english), isTrue, reason: quote.arabic);
        expect(_arabicLetters.hasMatch(quote.english), isFalse, reason: quote.english);
        expect(_arabicLetters.hasMatch(quote.sourceArabic), isTrue, reason: quote.english);
      }
    });

    test('should not repeat a quote', () {
      final arabic = DailyQuotes.all.map((quote) => quote.arabic).toList();
      final english = DailyQuotes.all.map((quote) => quote.english).toList();

      expect(arabic.toSet().length, arabic.length);
      expect(english.toSet().length, english.length);
    });

    test('should wrap Quran verses in Quran brackets and cite the Quran', () {
      for (final quote in DailyQuotes.all.where((quote) => quote.sourceEnglish.startsWith('Quran'))) {
        expect(quote.arabic.startsWith('﴿') && quote.arabic.endsWith('﴾'), isTrue, reason: quote.sourceEnglish);
      }
      expect(DailyQuotes.all.where((quote) => quote.arabic.startsWith('﴿')).every((quote) => quote.sourceEnglish.startsWith('Quran')), isTrue);
    });

    test('should include religious and time management quotes', () {
      expect(DailyQuotes.all.any((quote) => quote.sourceEnglish.startsWith('Quran')), isTrue);
      expect(DailyQuotes.all.any((quote) => quote.sourceEnglish == 'Bukhari'), isTrue);
      expect(DailyQuotes.all.any((quote) => quote.category == DailyQuoteCategory.time), isTrue);
    });
  });

  group('DailyQuoteSelector', () {
    final day = DateTime(2026, 10, 6);

    test('should pick the same quote for the same day however the time of day changes', () {
      final morning = DailyQuoteSelector.forDate(DateTime(2026, 10, 6, 6));
      final night = DailyQuoteSelector.forDate(DateTime(2026, 10, 6, 23, 59));

      expect(identical(morning, night), isTrue);
    });

    test('should pick a different quote on consecutive days', () {
      final today = DailyQuoteSelector.forDate(day);
      final tomorrow = DailyQuoteSelector.forDate(day.add(const Duration(days: 1)));

      expect(identical(today, tomorrow), isFalse);
    });

    test('should rotate through the categories day after day', () {
      final categories = [
        for (var offset = 0; offset < DailyQuoteCategory.values.length; offset++)
          DailyQuoteSelector.forDate(day, shift: offset).category,
      ];

      expect(categories.toSet().length, DailyQuoteCategory.values.length);
    });

    test('should move to a different quote when shifted', () {
      final first = DailyQuoteSelector.forDate(day);
      final next = DailyQuoteSelector.forDate(day, shift: 1);

      expect(identical(first, next), isFalse);
    });

    test('should show every quote over enough days', () {
      final seen = <DailyQuote>{
        for (var offset = 0; offset < DailyQuotes.all.length * DailyQuoteCategory.values.length; offset++)
          DailyQuoteSelector.forDate(day, shift: offset),
      };

      expect(seen.length, DailyQuotes.all.length);
    });

    test('should fall back to any quote when a category has none', () {
      const only = DailyQuote(
        category: DailyQuoteCategory.faith,
        arabic: 'نص',
        english: 'Text',
        sourceArabic: 'مصدر',
        sourceEnglish: 'Source',
      );

      for (var offset = 0; offset < 3; offset++) {
        expect(DailyQuoteSelector.forDate(day, shift: offset, quotes: const [only]), same(only));
      }
    });

    test('should count days from a fixed origin regardless of daylight saving', () {
      expect(DailyQuoteSelector.dayNumber(DateTime(1970)), 0);
      expect(DailyQuoteSelector.dayNumber(DateTime(2026, 3, 29)) - DailyQuoteSelector.dayNumber(DateTime(2026, 3, 28)), 1);
    });
  });
}
