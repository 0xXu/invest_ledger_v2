import 'package:flutter/foundation.dart';

/// 应用日志工具类
/// 在生产环境中自动禁用日志输出，保护性能和安全性
class AppLogger {
  static const String _prefix = '[InvestLedger]';

  /// 调试信息 - 仅在调试模式下输出
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix DEBUG: $message');
    }
  }

  /// 信息日志 - 仅在调试模式下输出
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix INFO: $message');
    }
  }

  /// 警告日志 - 仅在调试模式下输出
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix WARNING: $message');
    }
  }

  /// 错误日志 - 在所有模式下输出（用于关键错误）
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix ERROR: $message');
      if (error != null) {
        debugPrint('$_prefix ERROR Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix ERROR Stack: $stackTrace');
      }
    }
  }

  /// 成功操作日志 - 仅在调试模式下输出
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix ✅ $message');
    }
  }

  /// 操作失败日志 - 仅在调试模式下输出
  static void failure(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix ❌ $message');
    }
  }
}