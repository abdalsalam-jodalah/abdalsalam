import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/calendar/event.dart';
import '../../../data/repositories/calendar/calendar_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/error_handler.dart';
import '../../../shared/services/reminder_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

class CalendarService extends BaseServiceImpl<Event> {
  final ReminderService reminders;
  final GoogleSignIn googleSignIn;

  CalendarService(
    super.repository,
    super.logger, {
    required this.reminders,
    GoogleSignIn? googleSignIn,
  }) : googleSignIn =
            googleSignIn ??
                GoogleSignIn.standard(scopes: const <String>[gcal.CalendarApi.calendarScope]);

  CalendarRepository get _repo => repository as CalendarRepository;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  @override
  String get serviceName => 'CalendarService';

  @override
  String get version => '1.0.0';

  @override
  Event fromJson(Map<String, dynamic> json) => Event.fromJson(json);

  @override
  Result<void, AppError> validate(Event entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.title.trim().isEmpty) {
      return Failure(ValidationError('title is required'));
    }
    if (entity.endTime.isBefore(entity.startTime)) {
      return Failure(ValidationError('endTime must be after startTime'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final now = DateTime.now();
    final events = all.data!;
    final upcoming = events.where((item) => item.startTime.isAfter(now)).length;
    final allDay = events.where((item) => item.allDay).length;

    return Success(<String, dynamic>{
      'total': events.length,
      'upcoming': upcoming,
      'allDay': allDay,
    });
  }

  Future<Result<List<Event>, AppError>> getUnifiedTimeline() async {
    return _repo.getUpcoming(DateTime.now().subtract(const Duration(days: 7)));
  }

  Future<Result<void, AppError>> scheduleEventReminders(Event event) async {
    try {
      for (final minutes in event.reminderMinutes) {
        final scheduled = event.startTime.subtract(Duration(minutes: minutes));
        await reminders.schedule(
          ReminderPayload(
            module: ReminderModule.calendar,
            targetId: event.id,
            title: event.title,
            body: 'Event starts in $minutes minutes',
            scheduledAt: scheduled,
          ),
        );
      }
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$serviceName.scheduleEventReminders', stackTrace: stackTrace));
    }
  }

  Future<Result<List<Event>, AppError>> pullGoogleCalendarEvents() async {
    try {
      final account = await googleSignIn.signInSilently();
      if (account == null) {
        return const Success(<Event>[]);
      }
      final authHeaders = await account.authHeaders;
      final client = _GoogleAuthClient(authHeaders);
      final api = gcal.CalendarApi(client);
      final result = await api.events.list('primary', maxResults: 50);

      final mapped = (result.items ?? const <gcal.Event>[])
          .where((item) => item.start?.dateTime != null)
          .map(
            (item) => Event(
              id: item.id ?? item.etag ?? DateTime.now().microsecondsSinceEpoch.toString(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              userId: 'local-user',
              title: item.summary ?? 'Untitled Event',
              description: item.description,
              startTime: item.start!.dateTime!,
              endTime: item.end?.dateTime ?? item.start!.dateTime!,
              allDay: false,
              location: item.location,
              attendees: (item.attendees ?? const <gcal.EventAttendee>[])
                  .where((a) => a.email != null)
                  .map((a) => a.email!)
                  .toList(growable: false),
              reminderMinutes: const <int>[10],
              googleEventId: item.id,
              color: '#00897B',
              category: 'google',
            ),
          )
          .toList(growable: false);

      return Success(mapped);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$serviceName.pullGoogleCalendarEvents', stackTrace: stackTrace));
    }
  }

  Future<Result<void, AppError>> pushEventToGoogleCalendar(Event event) async {
    try {
      final account = await googleSignIn.signInSilently();
      if (account == null) {
        return Failure(AuthError('Google account is not connected'));
      }
      final authHeaders = await account.authHeaders;
      final client = _GoogleAuthClient(authHeaders);
      final api = gcal.CalendarApi(client);

      final payload = gcal.Event(
        summary: event.title,
        description: event.description,
        location: event.location,
        start: gcal.EventDateTime(dateTime: event.startTime),
        end: gcal.EventDateTime(dateTime: event.endTime),
      );

      if (event.googleEventId != null && event.googleEventId!.isNotEmpty) {
        await api.events.patch(payload, 'primary', event.googleEventId!);
      } else {
        await api.events.insert(payload, 'primary');
      }
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$serviceName.pushEventToGoogleCalendar', stackTrace: stackTrace));
    }
  }

  Result<Event, AppError> resolveSyncConflict({
    required Event local,
    required Event remote,
    String strategy = 'latest',
  }) {
    if (strategy == 'local') {
      return Success(local);
    }
    if (strategy == 'remote') {
      return Success(remote);
    }
    return local.updatedAt.isAfter(remote.updatedAt)
        ? Success(local)
        : Success(remote);
  }

  Future<Result<void, AppError>> handleEventReminderTap(Event event) async {
    reminders.handleNotificationTap(
      ReminderPayload(
        module: ReminderModule.calendar,
        targetId: event.id,
        title: 'Open event',
        body: event.title,
        scheduledAt: DateTime.now(),
      ),
    );
    return const Success(null);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
