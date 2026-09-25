import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateFormatter {
  static final DateFormat _date = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _time = DateFormat('h:mm a');

  const AppDateFormatter._();

  static String date(DateTime value) => _date.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value);

  static String time(DateTime value) => _time.format(value);

  static String timeOfDay(TimeOfDay value) => _time.format(DateTime(0, 1, 1, value.hour, value.minute));

  static String dateTime(DateTime value) => '${date(value)} · ${time(value)}';
}
