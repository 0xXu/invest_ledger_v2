import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loading_provider.g.dart';

@riverpod
class GlobalLoading extends _$GlobalLoading {
  @override
  LoadingState build() => const LoadingState();

  void show([String? message]) {
    state = LoadingState(isLoading: true, message: message);
  }

  void hide() {
    state = const LoadingState();
  }

  // 异步操作包装器
  Future<T> wrap<T>(Future<T> Function() operation, [String? message]) async {
    show(message);
    try {
      final result = await operation();
      hide();
      return result;
    } catch (e) {
      hide();
      rethrow;
    }
  }
}

class LoadingState {
  final bool isLoading;
  final String? message;

  const LoadingState({
    this.isLoading = false,
    this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          message == other.message;

  @override
  int get hashCode => isLoading.hashCode ^ message.hashCode;
}
