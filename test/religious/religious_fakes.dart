import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/features/religious/services/prayer_times_cache_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReminderService extends Fake implements ReminderService {
  final List<ReminderPayload> scheduled = [];
  bool shouldFail;

  FakeReminderService({this.shouldFail = false});

  @override
  Future<void> schedule(ReminderPayload payload) async {
    if (shouldFail) {
      throw StateError('notifications unavailable');
    }
    scheduled.add(payload);
  }

  @override
  void handleNotificationTap(ReminderPayload payload) {}
}

class FakeAssetBundle extends CachingAssetBundle {
  final String? content;

  FakeAssetBundle(this.content);

  @override
  Future<ByteData> load(String key) async {
    final value = content;
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

class FakePrayerTimesCacheService extends Fake implements PrayerTimesCacheService {
  Result<Map<String, DateTime>?, AppError> readResult;
  Result<void, AppError> writeResult;
  final List<Map<String, DateTime>> written = [];

  FakePrayerTimesCacheService({
    this.readResult = const Success(null),
    this.writeResult = const Success(null),
  });

  @override
  Future<Result<Map<String, DateTime>?, AppError>> getForDate(DateTime date, String method) async {
    return readResult;
  }

  @override
  Future<Result<void, AppError>> cacheForDate({
    required DateTime date,
    required String method,
    required Map<String, DateTime> times,
  }) async {
    written.add(times);
    return writeResult;
  }
}
