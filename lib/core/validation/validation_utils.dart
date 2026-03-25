class ValidationUtils {
  const ValidationUtils._();

  static String? requiredField(dynamic value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (value is String && value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value is Iterable && value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? dateRange({
    required DateTime? start,
    required DateTime? end,
    required String startField,
    required String endField,
  }) {
    if (start == null || end == null) {
      return null;
    }
    if (end.isBefore(start)) {
      return '$endField must be after $startField';
    }
    return null;
  }

  static String? numericRange({
    required num? value,
    required String fieldName,
    num? min,
    num? max,
  }) {
    if (value == null) {
      return null;
    }
    if (min != null && value < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && value > max) {
      return '$fieldName must be at most $max';
    }
    return null;
  }

  static String? enumValue({
    required String? value,
    required String fieldName,
    required List<String> allowed,
  }) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (!allowed.contains(value)) {
      return '$fieldName must be one of: ${allowed.join(', ')}';
    }
    return null;
  }

  static String? foreignKey({
    required String? id,
    required String fieldName,
    required bool exists,
  }) {
    if (id == null || id.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (!exists) {
      return '$fieldName references a missing record';
    }
    return null;
  }

  static String? email(String? value, {String fieldName = 'Email'}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) {
      return '$fieldName format is invalid';
    }
    return null;
  }

  static String? url(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !(uri.hasScheme && uri.hasAuthority)) {
      return '$fieldName format is invalid';
    }
    return null;
  }

  static String? passwordStrength(String? value, {String fieldName = 'Password'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final hasLength = value.length >= 8;
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasLower = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));

    if (!(hasLength && hasUpper && hasLower && hasDigit)) {
      return '$fieldName must be 8+ chars with upper, lower, and number';
    }
    return null;
  }

  static Map<String, String> collect(List<MapEntry<String, String?>> rules) {
    final errors = <String, String>{};
    for (final rule in rules) {
      if (rule.value != null) {
        errors[rule.key] = rule.value!;
      }
    }
    return errors;
  }
}
