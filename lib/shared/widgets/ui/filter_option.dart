import 'package:flutter/widgets.dart';

class FilterOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const FilterOption(this.value, this.label, {this.icon});
}
