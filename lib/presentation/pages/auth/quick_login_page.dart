import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/auth/device_users_manager.dart';
import '../../../core/auth/secure_credentials_manager.dart';
import '../../../core/auth/device_users_cleaner.dart';
import '../../providers/device_users_provider.dart';
import '../../utils/loading_utils.dart';
import 'quick_login_settings_page.dart';

class QuickLoginPage extends ConsumerStatefulWidget {
  const QuickLoginPage({super.key});

  @override
  ConsumerState<QuickLoginPage> createState() => _QuickLoginPageState();
}

class _QuickLoginPageState extends ConsumerState<QuickLoginPage> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  /// 初始化页面
  Future<void> _initPage() async {
    // 先清理重复用户
    await _cleanDuplicateUsers();

    // 然后检查自动登录
    await _checkAutoLogin();
  }

  /// 清理重复用户和无效用户
  Future<void> _cleanDuplicateUsers() async {
    try {
      final cleaner = DeviceUsersCleaner.instance;
      final hasDuplicates = await cleaner.hasDuplicateUsers();

      if (hasDuplicates) {
        await cleaner.cleanDuplicateUsers();
      }

      // 清理没有凭据的用户
      await _cleanUsersWithoutCredentials();

      // 刷新用户列表
      if (mounted) {
        ref.invalidate(deviceUsersNotifierProvider);
      }
    } catch (e) {
      debugPrint('清理重复用户失败: $e');
    }
  }

  /// 清理没有凭据的用户
  Future<void> _cleanUsersWithoutCredentials() async {
    try {
      final deviceUsersManager = DeviceUsersManager.instance;
      final credentialsManager = SecureCredentialsManager.instance;
      final users = await deviceUsersManager.getDeviceUsers();

      final usersToRemove = <String>[];

      for (final user in users) {
        final hasCredentials = await credentialsManager.hasCredentials(user.id);
        if (!hasCredentials) {
          usersToRemove.add(user.id);
        }
      }

      for (final userId in usersToRemove) {
        await deviceUsersManager.removeDeviceUser(userId);
        debugPrint('🧹 移除无凭据用户: $userId');
      }

      if (usersToRemove.isNotEmpty) {
        debugPrint('✅ 清理了 ${usersToRemove.length} 个无凭据用户');
      }
    } catch (e) {
      debugPrint('清理无凭据用户失败: $e');
    }
  }

  /// 检查是否需要自动登录
  Future<void> _checkAutoLogin() async {
    final credentialsManager = SecureCredentialsManager.instance;
    final isAutoLoginEnabled = await credentialsManager.isAutoLoginEnabled();

    if (isAutoLoginEnabled) {
      final lastLoginUserId = await credentialsManager.getLastLoginUser();
      if (lastLoginUserId != null) {
        // 延迟一下，让页面先显示
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // 自动登录也使用全局加载动画
          await _quickLogin(lastLoginUserId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceUsersAsync = ref.watch(deviceUsersNotifierProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 头部
              _buildHeader(),
              const SizedBox(height: 32),
              
              // 用户列表
              Expanded(
                child: deviceUsersAsync.when(
                  data: (users) => _buildUserList(users),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorWidget(error),
                ),
              ),
              
              // 底部操作
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo 和标题
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            LucideIcons.piggyBank,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '投资账本',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '选择账户快速登录',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        
        // 错误信息
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserList(List<DeviceUser> users) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(DeviceUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _quickLogin(user.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _getUserDisplayName(user)[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getUserDisplayName(user),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '最后登录: ${_formatLastLogin(user.lastLoginAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 箭头图标
              Icon(
                LucideIcons.chevronRight,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无保存的账户',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '请先登录一个账户',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.refresh(deviceUsersNotifierProvider),
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        // 添加新账户
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/auth/login'),
            icon: const Icon(LucideIcons.plus),
            label: const Text('添加新账户'),
          ),
        ),
        const SizedBox(height: 12),
        
        // 设置
        TextButton.icon(
          onPressed: () => _showQuickLoginSettings(),
          icon: const Icon(LucideIcons.settings),
          label: const Text('快速登录设置'),
        ),
      ],
    );
  }

  /// 快速登录
  Future<void> _quickLogin(String userId) async {
    // 清除之前的错误信息
    setState(() {
      _errorMessage = null;
    });

    try {
      // 使用全局加载动画包装整个登录流程
      await ref.withLoading(() async {
        final credentialsManager = SecureCredentialsManager.instance;
        final credentials = await credentialsManager.getCredentials(userId);

        if (credentials == null) {
          // 如果没有凭据，从设备用户列表中移除该用户
          final deviceUsersManager = DeviceUsersManager.instance;
          await deviceUsersManager.removeDeviceUser(userId);

          // 刷新用户列表
          if (mounted) {
            ref.invalidate(deviceUsersNotifierProvider);
          }

          throw Exception('登录信息已过期，请重新登录');
        }

        final authService = ref.read(authServiceProvider.notifier);
        await authService.signInWithEmail(
          email: credentials['email']!,
          password: credentials['password']!,
        );

        // 更新最后登录用户
        await credentialsManager.setLastLoginUser(userId);
      }, '正在快速登录...');

      // 登录成功，跳转到仪表板
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// 显示快速登录设置
  void _showQuickLoginSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuickLoginSettingsPage(),
      ),
    );
  }

  /// 获取用户显示名称
  String _getUserDisplayName(DeviceUser user) {
    // 如果有显示名称且不是邮箱，优先使用显示名称
    if (user.displayName != null &&
        user.displayName!.isNotEmpty &&
        user.displayName != user.email &&
        !user.displayName!.contains('@')) {
      return user.displayName!;
    }

    // 否则从邮箱提取用户名部分
    final emailParts = user.email.split('@');
    if (emailParts.isNotEmpty) {
      return emailParts.first;
    }

    return user.email;
  }

  String _formatLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return '从未登录';

    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${lastLogin.month}月${lastLogin.day}日';
    }
  }
}
