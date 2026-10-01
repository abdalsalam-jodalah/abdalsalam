// lib/shared/services/csv_encoder.dart — turns record maps into RFC 4180 CSV text.

import 'dart:convert';

class CsvEncoder {
  static const String _lineBreak = '\r\n';
  static const String _separator = ',';
  static const String _quote = '"';
  static const String _idColumn = 'id';

  const CsvEncoder();

  String encode(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return '';
    }
    final columns = _columnsOf(rows);
    final buffer = StringBuffer()..write(_line(columns))..write(_lineBreak);
    for (final row in rows) {
      buffer
        ..write(_line(columns.map((column) => _cell(row[column]))))
        ..write(_lineBreak);
    }
    return buffer.toString();
  }

  List<String> _columnsOf(List<Map<String, dynamic>> rows) {
    final columns = <String>{};
    if (rows.any((row) => row.containsKey(_idColumn))) {
      columns.add(_idColumn);
    }
    for (final row in rows) {
      columns.addAll(row.keys);
    }
    return columns.toList(growable: false);
  }

  String _line(Iterable<String> cells) => cells.map(_escape).join(_separator);

  String _cell(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }

  String _escape(String cell) {
    final needsQuoting = cell.contains(_separator) ||
        cell.contains(_quote) ||
        cell.contains('\n') ||
        cell.contains('\r');
    if (!needsQuoting) {
      return cell;
    }
    return '$_quote${cell.replaceAll(_quote, '$_quote$_quote')}$_quote';
  }
}
