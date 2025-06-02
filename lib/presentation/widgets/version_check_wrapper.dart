import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/version_provider.dart';
import 'update_dialog.dart';

class VersionCheckWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const VersionCheckWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends ConsumerState<VersionCheckWrapper> {
  bool _hasCheckedOnStartup = false;

  @override
  void initState() {
    super.initState();
    // 延迟执行版本检查，确保应用完全启动后再检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performStartupVersionCheck();
    });
  }

  Future<void> _performStartupVersionCheck() async {
    if (_hasCheckedOnStartup) return;
    _hasCheckedOnStartup = true;

    try {
      // 检查是否需要自动检查更新
      final repository = ref.read(versionRepositoryProvider);
      final shouldCheck = await repository.shouldAutoCheck();

      if (!shouldCheck) return;

      // 执行版本检查
      await ref.read(versionCheckProvider.notifier).autoCheckForUpdates();
    } catch (e) {
      // 静默处理错误，不影响应用正常启动
      debugPrint('版本检查失败: $e');
    }
  }

  Future<void> _showUpdateDialogIfNeeded(dynamic result) async {
    // 确保在主线程中显示对话框
    if (!mounted) return;
    
    // 等待一小段时间，确保应用界面完全加载
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;

    try {
      final currentVersion = await ref.read(currentVersionProvider.future);
      
      if (mounted) {
        UpdateDialog.show(
          context,
          versionInfo: result.latestVersion,
          currentVersion: currentVersion,
          canSkip: true, // 启动时的检查允许跳过
        );
      }
    } catch (e) {
      debugPrint('显示更新对话框失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 在 build 方法中监听版本检查结果
    ref.listen<AsyncValue<dynamic>>(
      versionCheckProvider,
      (previous, next) {
        next.whenData((result) {
          if (result.hasUpdate && result.latestVersion != null) {
            _showUpdateDialogIfNeeded(result);
          }
        });
      },
    );

    return widget.child;
  }
}
