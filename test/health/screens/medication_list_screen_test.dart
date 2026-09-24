import 'package:abdalsalam/core/constants/user_error_messages.dart';
import 'package:abdalsalam/features/health/providers/health_providers.dart';
import 'package:abdalsalam/features/health/screens/medication_list_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../health_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHealthRepository medications;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    medications = FakeHealthRepository();
  });

  Widget host() => ProviderScope(
        overrides: [
          healthRepositoryProvider.overrideWithValue(medications),
          medicationLogRepositoryProvider.overrideWithValue(FakeMedicationLogRepository()),
          reminderServiceProvider.overrideWithValue(FakeReminderService()),
        ],
        child: const MaterialApp(home: MedicationListScreen()),
      );

  testWidgets('should show the friendly error instead of stale data when loading fails, and recover on retry',
      (tester) async {
    medications.shouldFailActiveOn = true;

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text(UserErrorMessages.database), findsOneWidget);
    expect(find.textContaining('fake'), findsNothing);

    medications.shouldFailActiveOn = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text(UserErrorMessages.database), findsNothing);
    expect(find.text('No medications scheduled for this day'), findsOneWidget);
  });
}
