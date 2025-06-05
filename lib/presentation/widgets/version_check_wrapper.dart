import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_state.dart';
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
      // 等待用户认证状态稳定
      await Future.delayed(const Duration(seconds: 2));

      // 检查用户是否已登录
      final authState = ref.read(authServiceProvider);
      if (authState.status != AuthStatus.authenticated) {
        debugPrint('用户未登录，跳过版本检查');
        return;
      }

      // 检查是否开启了自动检查更新
      final autoCheckEnabled = ref.read(autoCheckEnabledProvider);
      if (!autoCheckEnabled) {
        debugPrint('自动检查更新已关闭');
        return;
      }

      // 检查是否需要自动检查更新（避免频繁检查）
      final repository = ref.read(versionRepositoryProvider);
      final shouldCheck = await repository.shouldAutoCheck();

      if (!shouldCheck) {
        debugPrint('距离上次检查时间太短，跳过检查');
        return;
      }

      debugPrint('开始自动检查更新...');
      // 执行版本检查
      await ref.read(versionCheckProvider.notifier).autoCheckForUpdates();
    } catch (e) {
      // 静默处理错误，不影响应用正常启动
      debugPrint('版本检查失败: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    // 监听版本检查结果，在发现新版本时显示更新对话框
    ref.listen<AsyncValue<dynamic>>(
      versionCheckProvider,
      (previous, next) {
        next.whenData((result) {
          if (result.hasUpdate && result.latestVersion != null) {
            debugPrint('🔄 发现新版本: ${result.latestVersion.tagName}');

            // 检查用户是否已登录且开启了自动检查
            final authState = ref.read(authServiceProvider);
            final autoCheckEnabled = ref.read(autoCheckEnabledProvider);

            if (authState.status == AuthStatus.authenticated && autoCheckEnabled) {
              _showUpdateDialog(context, result);
            }
          }
        });
      },
    );

    return widget.child;
  }

  Future<void> _showUpdateDialog(BuildContext dialogContext, dynamic result) async {
    // 等待一小段时间，确保Navigator完全初始化
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      // 检查context是否有Navigator
      final navigator = Navigator.maybeOf(dialogContext);
      if (navigator == null) {
        debugPrint('Navigator未初始化，跳过显示更新对话框');
        return;
      }

      final currentVersion = await ref.read(currentVersionProvider.future);

      if (mounted && dialogContext.mounted) {
        UpdateDialog.show(
          dialogContext,
          versionInfo: result.latestVersion,
          currentVersion: currentVersion,
          canSkip: true, // 自动检查时允许跳过
        );
      }
    } catch (e) {
      debugPrint('显示更新对话框失败: $e');
    }
  }
}
