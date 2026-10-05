// test/sync/support/sync_test_storage.dart — one-time sqflite FFI setup shared by sync tests that touch StorageGateway.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String syncTestDatabaseName = 'test_sync.db';

void initializeSyncTestStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
