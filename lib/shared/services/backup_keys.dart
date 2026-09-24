class BackupKeys {
  const BackupKeys._();

  static const String currentVersion = '1.1.0';
  static const String legacyVersion = '1.0.0';
  static const Set<String> supportedVersions = <String>{currentVersion, legacyVersion};
  static const String metadata = 'metadata';
  static const String data = 'data';
  static const String preferences = 'preferences';
  static const String version = 'version';
  static const String checksum = 'checksum';
  static const String preferencesChecksum = 'preferencesChecksum';
  static const String tables = 'tables';
  static const String createdAt = 'createdAt';
}
