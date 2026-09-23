import '../errors/app_error.dart';

class JsonReader {
  final Map<String, dynamic> json;
  final String source;

  const JsonReader(this.json, {required this.source});

  String requireString(String key) {
    final value = optionalString(key);
    if (value == null) {
      throw _missing(key);
    }
    return value;
  }

  String? optionalString(String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  String readString(String key, {String fallback = ''}) {
    return optionalString(key) ?? fallback;
  }

  DateTime requireDate(String key) {
    final value = optionalDate(key);
    if (value == null) {
      throw _missing(key);
    }
    return value;
  }

  DateTime? optionalDate(String key) {
    final value = json[key];
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  DateTime readDate(String key, {required DateTime fallback}) {
    return optionalDate(key) ?? fallback;
  }

  int requireInt(String key) {
    final value = optionalInt(key);
    if (value == null) {
      throw _missing(key);
    }
    return value;
  }

  int? optionalInt(String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  int readInt(String key, {int fallback = 0}) {
    return optionalInt(key) ?? fallback;
  }

  double requireDouble(String key) {
    final value = optionalDouble(key);
    if (value == null) {
      throw _missing(key);
    }
    return value;
  }

  double? optionalDouble(String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  double readDouble(String key, {double fallback = 0}) {
    return optionalDouble(key) ?? fallback;
  }

  bool? optionalBool(String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return null;
  }

  bool readBool(String key, {bool fallback = false}) {
    return optionalBool(key) ?? fallback;
  }

  T? optionalEnum<T extends Enum>(String key, List<T> values) {
    final name = optionalString(key);
    if (name == null) {
      return null;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  T readEnum<T extends Enum>(String key, List<T> values, {required T fallback}) {
    return optionalEnum(key, values) ?? fallback;
  }

  T requireEnum<T extends Enum>(String key, List<T> values) {
    final value = optionalEnum(key, values);
    if (value == null) {
      throw _missing(key);
    }
    return value;
  }

  List<String> readStringList(String key) {
    final value = json[key];
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }

  List<int> readIntList(String key) {
    final value = json[key];
    if (value is! List) {
      return const <int>[];
    }
    return value.whereType<num>().map((item) => item.toInt()).toList(growable: false);
  }

  Map<String, dynamic>? optionalMap(String key) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue));
    }
    return null;
  }

  Map<String, dynamic> readMap(String key) {
    return optionalMap(key) ?? const <String, dynamic>{};
  }

  List<T> readObjectList<T>(String key, T Function(Map<String, dynamic> item) parse) {
    final value = json[key];
    if (value is! List) {
      return <T>[];
    }
    final items = <T>[];
    for (final item in value) {
      if (item is! Map) {
        throw _missing(key);
      }
      items.add(parse(item.map((mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue))));
    }
    return items;
  }

  CorruptDataError _missing(String key) {
    return CorruptDataError(
      '$source: missing or invalid "$key"',
      source: source,
      field: key,
    );
  }
}
