import '../../core/constants/user_error_messages.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/app_error_code.dart';

class UserErrorMessageMapper {
  const UserErrorMessageMapper();

  String toUserMessage(Object error) {
    if (error is! AppError) {
      return UserErrorMessages.generic;
    }
    if (error is ValidationError && error.fieldErrors.isNotEmpty) {
      return error.fieldErrors.values.first;
    }
    switch (error.code) {
      case AppErrorCode.validation:
        return UserErrorMessages.validation;
      case AppErrorCode.notFound:
        return UserErrorMessages.notFound;
      case AppErrorCode.database:
        return UserErrorMessages.database;
      case AppErrorCode.corruptData:
        return UserErrorMessages.corruptData;
      case AppErrorCode.storageUnavailable:
        return UserErrorMessages.storageUnavailable;
      case AppErrorCode.network:
        return UserErrorMessages.network;
      case AppErrorCode.auth:
        return UserErrorMessages.auth;
      case AppErrorCode.export:
        return UserErrorMessages.export;
      case AppErrorCode.import:
      case AppErrorCode.importExport:
        return UserErrorMessages.import;
      default:
        return UserErrorMessages.generic;
    }
  }
}
