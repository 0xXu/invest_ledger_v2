/// 应用异常基类
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException($code): $message';
    }
    return 'AppException: $message';
  }
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 版本服务异常
class VersionServiceException extends AppException {
  const VersionServiceException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 数据库异常
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 验证异常
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// AI服务异常
class AIServiceException extends AppException {
  const AIServiceException(
    super.message, {
    super.code,
    super.originalError,
  });
}
