import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/secure_credentials_manager.dart';
import '../../../core/auth/device_users_manager.dart';
import '../../providers/device_users_provider.dart';

class QuickLoginSettingsPage extends ConsumerStatefulWidget {
  const QuickLoginSettingsPage({super.key});

  @override
  ConsumerState<QuickLoginSettingsPage> createState() => _QuickLoginSettingsPageState();
}

class _QuickLoginSettingsPageState extends ConsumerState<QuickLoginSettingsPage> {
  bool _quickLoginEnabled = true;
  bool _autoLoginEnabled = false;
  String? _lastLoginUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final credentialsManager = SecureCredentialsManager.instance;
    
    final quickLoginEnabled = await credentialsManager.isQuickLoginEnabled();
    final autoLoginEnabled = await credentialsManager.isAutoLoginEnabled();
    final lastLoginUserId = await credentialsManager.getLastLoginUser();
    
    setState(() {
      _quickLoginEnabled = quickLoginEnabled;
      _autoLoginEnabled = autoLoginEnabled;
      _lastLoginUserId = lastLoginUserId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速登录设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 快速登录开关
          _buildQuickLoginSection(),
          const SizedBox(height: 24),
          
          // 自动登录设置
          _buildAutoLoginSection(),
          const SizedBox(height: 24),
          
          // 安全设置
          _buildSecuritySection(),
          const SizedBox(height: 24),
          
          // 数据管理
          _buildDataManagementSection(),
        ],
      ),
    );
  }

  Widget _buildQuickLoginSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.zap, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  '快速登录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '启用后，应用会安全保存您的登录凭据，支持一键快速登录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用快速登录'),
              subtitle: const Text('保存登录凭据，支持一键登录'),
              value: _quickLoginEnabled,
              onChanged: _toggleQuickLogin,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoLoginSection() {
    final deviceUsersAsync = ref.watch(deviceUsersNotifierProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.userCheck, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  '自动登录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '启用后，应用启动时会自动使用最后登录的账户',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用自动登录'),
              subtitle: const Text('应用启动时自动登录最后使用的账户'),
              value: _autoLoginEnabled && _quickLoginEnabled,
              onChanged: _quickLoginEnabled ? _toggleAutoLogin : null,
              contentPadding: EdgeInsets.zero,
            ),
            
            // 显示当前默认账户
            if (_autoLoginEnabled && _lastLoginUserId != null) ...[
              const Divider(),
              deviceUsersAsync.when(
                data: (users) {
                  final defaultUser = users.where((u) => u.id == _lastLoginUserId).firstOrNull;
                  if (defaultUser != null) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          defaultUser.displayName?.isNotEmpty == true
                              ? defaultUser.displayName![0].toUpperCase()
                              : defaultUser.email[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(defaultUser.displayName ?? defaultUser.email),
                      subtitle: const Text('默认登录账户'),
                      contentPadding: EdgeInsets.zero,
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.shield, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  '安全设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '管理您的登录安全选项',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // 安全提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '您的登录凭据使用加密技术安全存储在本设备上',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.database, color: Colors.purple),
                const SizedBox(width: 12),
                Text(
                  '数据管理',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 清除所有凭据
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text('清除所有保存的凭据'),
              subtitle: const Text('删除所有保存的登录信息'),
              onTap: _showClearCredentialsDialog,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleQuickLogin(bool value) async {
    final credentialsManager = SecureCredentialsManager.instance;
    await credentialsManager.setQuickLoginEnabled(value);
    
    // 如果禁用快速登录，也要禁用自动登录
    if (!value) {
      await credentialsManager.setAutoLoginEnabled(false);
    }
    
    setState(() {
      _quickLoginEnabled = value;
      if (!value) {
        _autoLoginEnabled = false;
      }
    });
  }

  Future<void> _toggleAutoLogin(bool value) async {
    final credentialsManager = SecureCredentialsManager.instance;
    await credentialsManager.setAutoLoginEnabled(value);
    
    setState(() {
      _autoLoginEnabled = value;
    });
  }

  void _showClearCredentialsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有凭据'),
        content: const Text(
          '确定要清除所有保存的登录凭据吗？\n\n'
          '这将删除所有账户的快速登录信息，您需要重新输入密码登录。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllCredentials();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllCredentials() async {
    try {
      final credentialsManager = SecureCredentialsManager.instance;
      await credentialsManager.clearAllCredentials();
      
      setState(() {
        _autoLoginEnabled = false;
        _lastLoginUserId = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有凭据已清除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除失败: $e')),
        );
      }
    }
  }
}
