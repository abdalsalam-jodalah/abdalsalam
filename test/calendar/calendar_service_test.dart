import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/calendar/event.dart';
import 'package:abdalsalam/data/repositories/calendar/calendar_repository.dart';
import 'package:abdalsalam/features/calendar/services/calendar_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingReminderService extends ReminderService {
  final List<ReminderPayload> scheduled = [];
  bool shouldFail = false;

  _RecordingReminderService({
    required super.storage,
    required super.logger,
    required super.notifications,
    required super.settings,
  });

  @override
  Future<void> schedule(ReminderPayload payload) async {
    if (shouldFail) {
      throw DatabaseError('reminder storage unavailable');
    }
    scheduled.add(payload);
  }
}

class _ThrowingGoogleSignIn extends GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async {
    throw StateError('google services unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarService', () {
    late CalendarService service;
    late _RecordingReminderService reminders;

    Event buildEvent({List<int> reminderMinutes = const <int>[10, 30]}) {
      final start = DateTime(2030, 1, 1, 9);
      return Event(
        id: 'event-1',
        createdAt: start,
        updatedAt: start,
        userId: 'user',
        title: 'Planning',
        description: null,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        allDay: false,
        location: null,
        attendees: const <String>[],
        reminderMinutes: reminderMinutes,
        googleEventId: null,
        color: '#00897B',
        category: 'work',
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_calendar_service_test.db');
      final logger = LoggerService.forModule('CalendarServiceTest');
      reminders = _RecordingReminderService(
        storage: StorageGateway.instance,
        logger: logger,
        notifications: NotificationService(plugin: FlutterLocalNotificationsPlugin(), logger: logger),
        settings: SettingsService(StorageGateway.instance),
      );
      service = CalendarService(
        CalendarRepositoryImpl(StorageGateway.instance, logger),
        logger,
        reminders: reminders,
        googleSignIn: _ThrowingGoogleSignIn(),
      );
    });

    test('should schedule one reminder per configured offset', () async {
      final result = await service.scheduleEventReminders(buildEvent());

      expect(result.isSuccess, isTrue);
      expect(reminders.scheduled.map((item) => item.scheduledAt), [
        DateTime(2030, 1, 1, 8, 50),
        DateTime(2030, 1, 1, 8, 30),
      ]);
    });

    test('should return a failure instead of success when scheduling a reminder fails', () async {
      reminders.shouldFail = true;

      final result = await service.scheduleEventReminders(buildEvent());

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });

    test('should map a Google pull exception to a typed failure without raw text in the code', () async {
      final result = await service.pullGoogleCalendarEvents();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });

    test('should map a Google push exception to a typed failure', () async {
      final result = await service.pushEventToGoogleCalendar(buildEvent());

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });
  });
}
