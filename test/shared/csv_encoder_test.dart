import 'package:abdalsalam/shared/services/csv_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const encoder = CsvEncoder();

  group('CsvEncoder', () {
    test('should return an empty string when there are no rows', () {
      expect(encoder.encode(const []), '');
    });

    test('should write a header and one line per row with id first', () {
      final csv = encoder.encode([
        {'title': 'a', 'id': '1'},
        {'title': 'b', 'id': '2'},
      ]);

      expect(csv, 'id,title\r\n1,a\r\n2,b\r\n');
    });

    test('should use the union of keys and leave missing values empty', () {
      final csv = encoder.encode([
        {'id': '1', 'amount': 5},
        {'id': '2', 'note': 'x'},
      ]);

      expect(csv, 'id,amount,note\r\n1,5,\r\n2,,x\r\n');
    });

    test('should quote cells containing commas, quotes, and line breaks', () {
      final csv = encoder.encode([
        {'id': '1', 'text': 'a,b'},
        {'id': '2', 'text': 'say "hi"'},
        {'id': '3', 'text': 'line1\nline2'},
      ]);

      expect(csv, 'id,text\r\n1,"a,b"\r\n2,"say ""hi"""\r\n3,"line1\nline2"\r\n');
    });

    test('should keep Arabic text unchanged', () {
      final csv = encoder.encode([
        {'id': '1', 'text': 'سبحان الله'},
      ]);

      expect(csv, 'id,text\r\n1,سبحان الله\r\n');
    });

    test('should write nested maps and lists as quoted JSON', () {
      final csv = encoder.encode([
        {
          'id': '1',
          'tags': ['a', 'b'],
          'meta': {'k': 1},
        },
      ]);

      expect(csv, 'id,tags,meta\r\n1,"[""a"",""b""]","{""k"":1}"\r\n');
    });

    test('should write booleans and null values', () {
      final csv = encoder.encode([
        {'id': '1', 'done': true, 'deletedAt': null},
      ]);

      expect(csv, 'id,done,deletedAt\r\n1,true,\r\n');
    });
  });
}
