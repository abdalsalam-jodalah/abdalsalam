import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/security/credential.dart';
import '../../../data/repositories/security/security_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';

class SecurityService extends BaseServiceImpl<Credential> {
  static const _keyName = 'vault_encryption_key_v1';

  final FlutterSecureStorage secureStorage;
  final LocalAuthentication localAuth;
  final ReminderService reminders;

  SecurityService(
    super.repository,
    super.logger, {
    required this.secureStorage,
    required this.localAuth,
    required this.reminders,
  });

  SecurityRepository get _repo => repository as SecurityRepository;

  @override
  String get serviceName => 'SecurityService';

  @override
  String get version => '1.0.0';

  @override
  Credential fromJson(Map<String, dynamic> json) => Credential.fromJson(json);

  @override
  Result<void, AppError> validate(Credential entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.title.trim().isEmpty) {
      return Failure(ValidationError('title is required'));
    }
    if (entity.username.trim().isEmpty) {
      return Failure(ValidationError('username is required'));
    }
    if (entity.encryptedPassword.trim().isEmpty) {
      return Failure(ValidationError('encryptedPassword is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }
    final weak = all.data!.where((item) => item.strength < 40).length;
    final expiring = all.data!
        .where((item) =>
            item.expiryDate != null &&
            item.expiryDate!.isBefore(DateTime.now().add(const Duration(days: 7))))
        .length;

    return Success(<String, dynamic>{
      'total': all.data!.length,
      'weakPasswords': weak,
      'expiringSoon': expiring,
    });
  }

  Future<Result<bool, AppError>> authenticate() async {
    final available = await localAuth.canCheckBiometrics;
    if (!available) {
      return Failure(AuthError('Biometric authentication is not available'));
    }
    final ok = await localAuth.authenticate(
      localizedReason: 'Authenticate to access Security Vault',
      options: const AuthenticationOptions(biometricOnly: true),
    );
    return Success(ok);
  }

  Future<Result<String, AppError>> encryptPassword(String plainText) async {
    try {
      final key = await _loadOrCreateKey();
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return Success('${iv.base64}:${encrypted.base64}');
    } catch (e) {
      return Failure(ServiceError('Unable to encrypt password: $e'));
    }
  }

  Future<Result<String, AppError>> decryptPassword(String payload) async {
    try {
      final parts = payload.split(':');
      if (parts.length != 2) {
        return Failure(ValidationError('Invalid encrypted payload format'));
      }
      final key = await _loadOrCreateKey();
      final iv = enc.IV.fromBase64(parts.first);
      final encrypted = enc.Encrypted.fromBase64(parts.last);
      final encrypter = enc.Encrypter(enc.AES(key));
      return Success(encrypter.decrypt(encrypted, iv: iv));
    } catch (e) {
      return Failure(ServiceError('Unable to decrypt password: $e'));
    }
  }

  int calculatePasswordStrength(String password) {
    var score = 0;
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 20;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 15;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score += 15;
    return score.clamp(0, 100);
  }

  String generatePassword({
    int length = 16,
    bool uppercase = true,
    bool lowercase = true,
    bool numbers = true,
    bool symbols = true,
  }) {
    final chars = StringBuffer();
    if (uppercase) chars.write('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    if (lowercase) chars.write('abcdefghijklmnopqrstuvwxyz');
    if (numbers) chars.write('0123456789');
    if (symbols) chars.write('!@#%^&*()-_=+[]{};:,.?/');

    final source = chars.toString();
    if (source.isEmpty) {
      return '';
    }

    final rand = Random.secure();
    return List<String>.generate(length, (_) => source[rand.nextInt(source.length)])
        .join();
  }

  Future<void> autoClearClipboardAfterDelay({
    Duration delay = const Duration(seconds: 30),
  }) async {
    await Future<void>.delayed(delay);
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  Future<Result<void, AppError>> scheduleExpiryReminder(Credential credential) async {
    if (credential.expiryDate == null) {
      return const Success(null);
    }
    await reminders.schedule(
      ReminderPayload(
        module: ReminderModule.security,
        targetId: credential.id,
        title: 'Credential expiry reminder',
        body: '${credential.title} expires in 7 days',
        scheduledAt: credential.expiryDate!.subtract(const Duration(days: 7)),
      ),
    );
    return const Success(null);
  }

  Future<enc.Key> _loadOrCreateKey() async {
    final current = await secureStorage.read(key: _keyName);
    if (current != null && current.isNotEmpty) {
      return enc.Key.fromBase64(current);
    }

    final random = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final encoded = base64Encode(random);
    await secureStorage.write(key: _keyName, value: encoded);
    return enc.Key.fromBase64(encoded);
  }

  String sanitizeForLogs(String raw) {
    final digest = sha256.convert(utf8.encode(raw)).toString();
    return 'sha256:$digest';
  }
}
