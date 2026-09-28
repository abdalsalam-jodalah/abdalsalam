import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('plugin unavailable: ${invocation.memberName}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    late NotificationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      service = NotificationService(
        plugin: _FailingNotificationsPlugin(),
        logger: LoggerService.forModule('NotificationServiceTest'),
      );
    });

    test('should return a failure from initialize when the plugin cannot start', () async {
      final result = await service.initialize();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });

    test('should return a failure instead of throwing when showing a notification fails', () async {
      final result = await service.showNow(
        id: 1,
        title: 'Title',
        body: 'Body',
        channel: NotificationChannelType.health,
      );

      expect(result.isFailure, isTrue);
    });

    test('should return a failure instead of throwing when scheduling fails', () async {
      final result = await service.zonedSchedule(
        id: 2,
        title: 'Title',
        body: 'Body',
        channel: NotificationChannelType.calendar,
        scheduledAt: DateTime(2030, 1, 1, 8),
      );

      expect(result.isFailure, isTrue);
    });

    test('should return a failure instead of throwing when cancelling fails', () async {
      final cancelResult = await service.cancel(3);
      final cancelAllResult = await service.cancelAll();

      expect(cancelResult.isFailure, isTrue);
      expect(cancelAllResult.isFailure, isTrue);
    });

    test('should return a failure instead of throwing when requesting permissions fails', () async {
      final result = await service.requestPermissions();

      expect(result.isFailure, isTrue);
    });

    test('should return a failure instead of throwing when checking notification status fails', () async {
      final result = await service.areNotificationsEnabled();

      expect(result.isFailure, isTrue);
    });
  });
}
