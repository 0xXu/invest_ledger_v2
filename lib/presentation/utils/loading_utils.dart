import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/loading_provider.dart';

/// 全局加载器工具类
class LoadingUtils {
  /// 显示加载器
  static void show(WidgetRef ref, [String? message]) {
    ref.read(globalLoadingProvider.notifier).show(message);
  }

  /// 隐藏加载器
  static void hide(WidgetRef ref) {
    ref.read(globalLoadingProvider.notifier).hide();
  }

  /// 包装异步操作并显示加载器
  static Future<T> wrap<T>(
    WidgetRef ref,
    Future<T> Function() operation, [
    String? message,
  ]) async {
    return ref.read(globalLoadingProvider.notifier).wrap(operation, message);
  }

  /// 延迟操作（用于演示）
  static Future<void> delay([Duration duration = const Duration(seconds: 1)]) {
    return Future.delayed(duration);
  }
}

/// 扩展方法，让 WidgetRef 更容易使用加载器
extension LoadingExtension on WidgetRef {
  /// 显示全局加载器
  void showLoading([String? message]) {
    LoadingUtils.show(this, message);
  }

  /// 隐藏全局加载器
  void hideLoading() {
    LoadingUtils.hide(this);
  }

  /// 包装异步操作并显示加载器
  Future<T> withLoading<T>(
    Future<T> Function() operation, [
    String? message,
  ]) {
    return LoadingUtils.wrap(this, operation, message);
  }
}
