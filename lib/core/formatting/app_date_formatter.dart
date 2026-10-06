import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateFormatter {
  static final DateFormat _date = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _weekdayShort = DateFormat('EEE');
  static final DateFormat _weekdayFull = DateFormat('EEEE');
  static final DateFormat _dayOfMonth = DateFormat('d');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _time = DateFormat('h:mm a');

  const AppDateFormatter._();

  static String date(DateTime value) => _date.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value);

  static String weekdayShort(DateTime value) => _weekdayShort.format(value);

  static String weekdayFull(DateTime value) => _weekdayFull.format(value);

  static String dayOfMonth(DateTime value) => _dayOfMonth.format(value);

  static String monthYear(DateTime value) => _monthYear.format(value);

  static String time(DateTime value) => _time.format(value);

  static String timeOfDay(TimeOfDay value) => _time.format(DateTime(0, 1, 1, value.hour, value.minute));

  static String dateTime(DateTime value) => '${date(value)} · ${time(value)}';
}
