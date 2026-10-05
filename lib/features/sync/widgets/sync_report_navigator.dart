// lib/features/sync/widgets/sync_report_navigator.dart — opens the full report screen for a finished sync.

import 'package:flutter/material.dart';

import '../../../data/models/sync/sync_session_report.dart';
import '../screens/sync_report_screen.dart';

class SyncReportNavigator {
  const SyncReportNavigator._();

  static Future<void> open(BuildContext context, SyncSessionReport report) {
    return Navigator.of(context).pushNamed<void>(SyncReportScreen.routeName, arguments: report);
  }
}
