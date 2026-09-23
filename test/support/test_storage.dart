import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeTestDatabaseFactory() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Future<void> resetTestStorage({
  required String databaseName,
  required List<String> tables,
}) async {
  SharedPreferences.setMockInitialValues({});
  await LoggerService.initialize();
  await StorageGateway.instance.initialize(databaseName: databaseName);
  await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
  for (final table in tables) {
    await StorageGateway.instance.clearTable(table);
  }
}
