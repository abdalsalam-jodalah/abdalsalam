import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/bootstrap/bootstrap_app.dart';
import 'app/error_handling/global_error_handlers.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      GlobalErrorHandlers.install();
      runApp(const BootstrapApp());
    },
    (error, stackTrace) => GlobalErrorHandlers.reportUncaughtError(error, stackTrace, source: 'zone'),
  );
}
