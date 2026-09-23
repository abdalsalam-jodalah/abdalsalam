import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/security/credential.dart';
import 'package:abdalsalam/data/models/security/credential_category.dart';
import 'package:flutter_test/flutter_test.dart';

final _createdAt = DateTime.utc(2026, 3, 1, 8);
final _updatedAt = DateTime.utc(2026, 3, 2, 9);
final _deletedAt = DateTime.utc(2026, 3, 3, 10);
final _lastModified = DateTime.utc(2026, 3, 4, 11);
final _expiryDate = DateTime.utc(2027, 3, 1);
const _userId = 'user-1';

void main() {
  group('Credential.fromJson', () {
    final credential = Credential(
      id: 'cred-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      title: 'Bank',
      username: 'abdalsalam',
      encryptedPassword: 'cipher-text',
      website: 'https://bank.example',
      notes: 'main account',
      categoryId: 'cat-1',
      tags: const ['finance', 'important'],
      favorite: true,
      lastModified: _lastModified,
      strength: 4,
      expiryDate: _expiryDate,
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = credential.toJson();

      final parsed = Credential.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = <String, dynamic>{
        'id': 'cred-2',
        'createdAt': _createdAt.toIso8601String(),
        'encryptedPassword': 'cipher-text',
      };

      final parsed = Credential.fromJson(json);

      expect(parsed.title, '');
      expect(parsed.username, '');
      expect(parsed.tags, isEmpty);
      expect(parsed.favorite, isFalse);
      expect(parsed.strength, 0);
      expect(parsed.lastModified, _createdAt);
      expect(parsed.expiryDate, isNull);
    });

    test('should tolerate wrong types for int, bool and list fields', () {
      final json = {
        ...credential.toJson(),
        'strength': 3.0,
        'favorite': 'false',
        'tags': ['ok', 7],
      };

      final parsed = Credential.fromJson(json);

      expect(parsed.strength, 3);
      expect(parsed.favorite, isFalse);
      expect(parsed.tags, ['ok']);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {
        ...credential.toJson(),
        'updatedAt': 'bad',
        'deletedAt': 'bad',
        'lastModified': 'bad',
        'expiryDate': 'never',
      };

      final parsed = Credential.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
      expect(parsed.lastModified, _createdAt);
      expect(parsed.expiryDate, isNull);
    });

    test('should throw CorruptDataError when encryptedPassword is missing', () {
      final json = credential.toJson()..remove('encryptedPassword');

      expect(() => Credential.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when createdAt is invalid', () {
      final json = {...credential.toJson(), 'createdAt': 'bad'};

      expect(() => Credential.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('CredentialCategory.fromJson', () {
    final category = CredentialCategory(
      id: 'cat-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      name: 'Banking',
      color: '#0000FF',
      icon: 'bank',
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = category.toJson();

      final parsed = CredentialCategory.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = <String, dynamic>{
        'id': 'cat-2',
        'createdAt': _createdAt.toIso8601String(),
      };

      final parsed = CredentialCategory.fromJson(json);

      expect(parsed.name, '');
      expect(parsed.color, '');
      expect(parsed.icon, '');
      expect(parsed.userId, '');
    });

    test('should tolerate a number for a string field', () {
      final json = {...category.toJson(), 'name': 42};

      final parsed = CredentialCategory.fromJson(json);

      expect(parsed.name, '42');
    });

    test('should fall back when optional dates are invalid', () {
      final json = {...category.toJson(), 'updatedAt': 'bad', 'deletedAt': 'bad'};

      final parsed = CredentialCategory.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when id is missing', () {
      final json = category.toJson()..remove('id');

      expect(() => CredentialCategory.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });
}
