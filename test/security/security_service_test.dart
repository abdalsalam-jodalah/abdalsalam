import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/repositories/security/security_repository.dart';
import 'package:abdalsalam/features/security/services/security_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};
  bool shouldFail = false;

  _InMemorySecureStorage();

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldFail) {
      throw PlatformException(code: 'keychain', message: 'keychain locked');
    }
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      values[key] = value;
    }
  }
}

class _ThrowingLocalAuthentication extends LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async {
    throw PlatformException(code: 'NotAvailable', message: 'no biometrics hardware');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityService', () {
    late SecurityService service;
    late _InMemorySecureStorage secureStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_security_service_test.db');
      final logger = LoggerService.forModule('SecurityServiceTest');
      secureStorage = _InMemorySecureStorage();
      service = SecurityService(
        SecurityRepositoryImpl(StorageGateway.instance, logger),
        logger,
        secureStorage: secureStorage,
        localAuth: _ThrowingLocalAuthentication(),
        reminders: ReminderService(
          storage: StorageGateway.instance,
          logger: logger,
          notifications: NotificationService(plugin: FlutterLocalNotificationsPlugin(), logger: logger),
          settings: SettingsService(StorageGateway.instance),
        ),
      );
    });

    test('should round-trip a password through encrypt and decrypt', () async {
      final encrypted = (await service.encryptPassword('s3cret!')).getOrThrow();

      final decrypted = await service.decryptPassword(encrypted);

      expect(decrypted.getOrThrow(), 's3cret!');
    });

    test('should return a failure when the encryption key cannot be read', () async {
      secureStorage.shouldFail = true;

      final result = await service.encryptPassword('s3cret!');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });

    test('should return a corrupt-data failure when the encrypted payload is not valid base64', () async {
      final result = await service.decryptPassword('!!!:???');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<CorruptDataError>());
    });

    test('should return an AuthError instead of throwing when biometrics throw', () async {
      final result = await service.authenticate();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<AuthError>());
    });

    test('should propagate the authentication failure from exportSecureVault', () async {
      final result = await service.exportSecureVault(sanitizeSensitive: true);

      expect(result.error, isA<AuthError>());
    });
  });
}
