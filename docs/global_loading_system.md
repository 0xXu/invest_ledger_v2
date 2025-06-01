# 全局加载器系统

## 概述

全局加载器系统为应用提供了统一的加载状态管理和用户界面反馈。当执行异步操作时，会自动显示一个覆盖整个应用的加载动画和可选的消息。

## 功能特性

- 🎯 **全局覆盖**: 加载器覆盖整个应用界面，防止用户在加载期间进行其他操作
- 🎨 **自定义动画**: 使用投资主题的自定义加载动画（旋转的趋势图标）
- 💬 **可选消息**: 支持显示加载状态的描述信息
- 🔄 **异步包装**: 提供便捷的异步操作包装方法
- 🎭 **状态管理**: 基于 Riverpod 的响应式状态管理

## 核心组件

### 1. LoadingProvider
状态管理提供者，管理全局加载状态。

```dart
// 显示加载器
ref.read(globalLoadingProvider.notifier).show('正在加载...');

// 隐藏加载器
ref.read(globalLoadingProvider.notifier).hide();

// 包装异步操作
await ref.read(globalLoadingProvider.notifier).wrap(() async {
  // 异步操作
}, '操作描述');
```

### 2. GlobalLoadingOverlay
UI 组件，显示加载覆盖层和动画。

### 3. LoadingUtils
工具类，提供便捷的加载器操作方法。

```dart
// 使用工具类
LoadingUtils.show(ref, '正在保存...');
LoadingUtils.hide(ref);

// 或使用扩展方法
ref.showLoading('正在加载...');
ref.hideLoading();
await ref.withLoading(() async {
  // 异步操作
}, '操作描述');
```

## 使用示例

### 基本使用

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await ref.withLoading(() async {
          // 模拟网络请求
          await Future.delayed(Duration(seconds: 2));
          // 执行实际操作
        }, '正在处理请求...');
      },
      child: Text('执行操作'),
    );
  }
}
```

### 在 Provider 中使用

```dart
@riverpod
class DataNotifier extends _$DataNotifier {
  Future<void> saveData(Data data) async {
    final loading = ref.read(globalLoadingProvider.notifier);
    await loading.wrap(() async {
      final repository = ref.read(dataRepositoryProvider);
      await repository.save(data);
      ref.invalidateSelf();
    }, '正在保存数据...');
  }
}
```

## 集成步骤

### 1. 添加到应用根部
在 `app.dart` 中包装 MaterialApp：

```dart
return GlobalLoadingOverlay(
  child: MaterialApp.router(
    // 应用配置
  ),
);
```

### 2. 在需要的地方使用
在任何 ConsumerWidget 中使用加载器：

```dart
// 简单显示/隐藏
ref.showLoading('加载中...');
ref.hideLoading();

// 包装异步操作（推荐）
await ref.withLoading(() async {
  // 异步操作
}, '操作描述');
```

## 当前应用中的使用

### 交易操作
- 添加交易：显示"正在添加交易..."
- 更新交易：显示"正在更新交易..."
- 删除交易：显示"正在删除交易..."

### 目标管理
- 保存目标：显示"正在保存目标..."
- 删除目标：显示"正在删除目标..."

### 数据刷新
- 仪表盘刷新：显示"正在刷新数据..."

## 自定义选项

### 修改加载动画
在 `GlobalLoadingOverlay` 中的 `_CustomLoadingIndicator` 组件可以自定义：
- 动画类型
- 颜色主题
- 图标选择
- 动画速度

### 修改覆盖层样式
在 `_LoadingOverlay` 中可以调整：
- 背景透明度
- 容器样式
- 文字样式
- 布局方式

## 最佳实践

1. **使用包装方法**: 优先使用 `withLoading()` 而不是手动显示/隐藏
2. **提供有意义的消息**: 让用户知道正在执行什么操作
3. **避免嵌套**: 不要在已有加载状态时再次显示加载器
4. **错误处理**: 确保在异常情况下也能正确隐藏加载器
5. **性能考虑**: 避免在快速操作中使用加载器（如本地数据操作）

## 注意事项

- 加载器会阻止用户交互，请谨慎使用
- 确保所有异步操作都有适当的错误处理
- 避免长时间显示加载器而没有进度反馈
- 在组件销毁时确保加载器被正确隐藏
