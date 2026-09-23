import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/json/json_reader.dart';
import 'package:flutter_test/flutter_test.dart';

enum SampleKind { alpha, beta }

void main() {
  JsonReader readerOf(Map<String, dynamic> json) => JsonReader(json, source: 'Sample');

  group('JsonReader strings', () {
    test('should return the string when key holds a string', () {
      expect(readerOf({'name': 'x'}).requireString('name'), 'x');
    });

    test('should throw CorruptDataError naming the field when a required string is missing', () {
      expect(
        () => readerOf({}).requireString('name'),
        throwsA(isA<CorruptDataError>().having((error) => error.field, 'field', 'name')),
      );
    });

    test('should convert numbers to strings instead of crashing', () {
      expect(readerOf({'name': 42}).requireString('name'), '42');
    });

    test('should return the fallback when an optional string has the wrong type', () {
      expect(readerOf({'name': <String>[]}).readString('name', fallback: 'none'), 'none');
    });
  });

  group('JsonReader dates', () {
    test('should parse ISO-8601 strings', () {
      expect(readerOf({'at': '2026-01-02T03:04:05.000'}).requireDate('at'), DateTime(2026, 1, 2, 3, 4, 5));
    });

    test('should parse epoch milliseconds', () {
      final expected = DateTime.fromMillisecondsSinceEpoch(1000);
      expect(readerOf({'at': 1000}).requireDate('at'), expected);
    });

    test('should return null for an invalid optional date', () {
      expect(readerOf({'at': 'not-a-date'}).optionalDate('at'), isNull);
    });

    test('should throw CorruptDataError for an invalid required date', () {
      expect(() => readerOf({'at': 'not-a-date'}).requireDate('at'), throwsA(isA<CorruptDataError>()));
    });
  });

  group('JsonReader numbers', () {
    test('should accept a double where an int is expected', () {
      expect(readerOf({'count': 3.0}).requireInt('count'), 3);
    });

    test('should accept numeric strings', () {
      expect(readerOf({'count': '7'}).requireInt('count'), 7);
      expect(readerOf({'amount': '1.5'}).requireDouble('amount'), 1.5);
    });

    test('should accept an int where a double is expected', () {
      expect(readerOf({'amount': 2}).requireDouble('amount'), 2.0);
    });

    test('should return the fallback for a non-numeric value', () {
      expect(readerOf({'count': 'abc'}).readInt('count', fallback: 9), 9);
    });
  });

  group('JsonReader booleans', () {
    test('should accept bools, numbers, and strings', () {
      expect(readerOf({'flag': true}).readBool('flag'), isTrue);
      expect(readerOf({'flag': 1}).readBool('flag'), isTrue);
      expect(readerOf({'flag': 'false'}).readBool('flag', fallback: true), isFalse);
    });

    test('should return the fallback when missing', () {
      expect(readerOf({}).readBool('flag', fallback: true), isTrue);
    });
  });

  group('JsonReader enums', () {
    test('should resolve a known enum name', () {
      expect(readerOf({'kind': 'beta'}).readEnum('kind', SampleKind.values, fallback: SampleKind.alpha), SampleKind.beta);
    });

    test('should return the fallback for an unknown enum name', () {
      expect(readerOf({'kind': 'gamma'}).readEnum('kind', SampleKind.values, fallback: SampleKind.alpha), SampleKind.alpha);
    });

    test('should throw CorruptDataError for an unknown required enum', () {
      expect(() => readerOf({'kind': 'gamma'}).requireEnum('kind', SampleKind.values), throwsA(isA<CorruptDataError>()));
    });
  });

  group('JsonReader collections', () {
    test('should keep only strings in a string list', () {
      expect(readerOf({'tags': ['a', 1, null, 'b']}).readStringList('tags'), ['a', 'b']);
    });

    test('should return an empty list when the value is not a list', () {
      expect(readerOf({'tags': 'a'}).readStringList('tags'), isEmpty);
      expect(readerOf({'ids': {'a': 1}}).readIntList('ids'), isEmpty);
    });

    test('should normalise non-string map keys', () {
      expect(readerOf({'meta': {1: 'x'}}).readMap('meta'), {'1': 'x'});
    });

    test('should parse a list of objects', () {
      final items = readerOf({
        'items': [
          {'n': 1},
          {'n': 2},
        ],
      }).readObjectList('items', (item) => JsonReader(item, source: 'Item').requireInt('n'));

      expect(items, [1, 2]);
    });

    test('should throw CorruptDataError when a list of objects contains a non-object', () {
      expect(
        () => readerOf({'items': [1]}).readObjectList('items', (item) => item),
        throwsA(isA<CorruptDataError>()),
      );
    });
  });
}
