class ValidationErrorMessages {
  const ValidationErrorMessages._();

  static String map(String field, String code) {
    switch (code) {
      case 'required':
        return '$field is required';
      case 'date_range':
        return 'Please choose a valid date range';
      case 'numeric_range':
        return '$field is out of range';
      case 'enum':
        return '$field has an invalid value';
      case 'foreign_key':
        return 'The selected $field no longer exists';
      case 'email':
        return 'Please enter a valid email';
      case 'url':
        return 'Please enter a valid URL';
      case 'password_strength':
        return 'Password must be 8+ chars with upper, lower, and number';
      default:
        return 'Invalid $field';
    }
  }
}
