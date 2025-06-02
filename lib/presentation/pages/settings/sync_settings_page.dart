import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../data/datasources/remote/supabase_auth_service.dart';
import '../../widgets/sync_status_widget.dart';

class SyncSettingsPage extends ConsumerStatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  ConsumerState<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends ConsumerState<SyncSettingsPage> {
  final _authService = SupabaseAuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据同步设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 同步状态卡片
            _buildSyncStatusCard(context, syncStatusAsync),
            const SizedBox(height: 24),
            
            // 账户管理
            _buildAccountSection(context),
            const SizedBox(height: 24),
            
            // 同步设置
            _buildSyncSettingsSection(context),
            const SizedBox(height: 24),
            
            // 数据管理
            _buildDataManagementSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context, AsyncValue syncStatusAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '同步状态',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                const SyncStatusWidget(),
              ],
            ),
            const SizedBox(height: 16),
            if (SupabaseConfig.isLoggedIn) ...[
              Text('当前用户: ${SupabaseConfig.currentUser?.email ?? '未知'}'),
              const SizedBox(height: 8),
              Text(
                '数据将自动同步到云端，确保您在不同设备上都能访问最新数据。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const Text('未登录，数据仅保存在本地'),
              const SizedBox(height: 8),
              Text(
                '登录后可以将数据同步到云端，实现多设备访问。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '账户管理',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (SupabaseConfig.isLoggedIn) ...[
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            subtitle: const Text('退出后将只能访问本地数据'),
            onTap: _handleSignOut,
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('账户信息'),
            subtitle: Text(SupabaseConfig.currentUser?.email ?? ''),
            onTap: () {
              // TODO: 实现账户信息页面
            },
          ),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('登录账户'),
            subtitle: const Text('登录以启用云端同步'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/auth/login');
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSyncSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '同步设置',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('手动同步'),
          subtitle: const Text('立即同步本地数据到云端'),
          enabled: SupabaseConfig.isLoggedIn,
          onTap: SupabaseConfig.isLoggedIn ? _handleManualSync : null,
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download),
          title: const Text('从云端恢复'),
          subtitle: const Text('用云端数据覆盖本地数据'),
          enabled: SupabaseConfig.isLoggedIn,
          onTap: SupabaseConfig.isLoggedIn ? _handleRestoreFromCloud : null,
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('同步设置'),
          subtitle: const Text('配置自动同步选项'),
          onTap: () {
            // TODO: 实现同步设置页面
          },
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '数据管理',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('备份数据'),
          subtitle: const Text('导出数据到本地文件'),
          onTap: () {
            // TODO: 实现数据备份功能
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('恢复数据'),
          subtitle: const Text('从本地文件恢复数据'),
          onTap: () {
            // TODO: 实现数据恢复功能
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('清除本地数据', style: TextStyle(color: Colors.red)),
          subtitle: const Text('删除所有本地数据（不可恢复）'),
          onTap: _handleClearLocalData,
        ),
      ],
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出登录后，您将只能访问本地数据。确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已退出登录')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('退出失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleManualSync() async {
    setState(() => _isLoading = true);
    try {
      final syncManager = ref.read(syncManagerProvider);
      await syncManager.manualSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestoreFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('这将用云端数据覆盖本地数据，本地的未同步更改将丢失。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: 实现从云端恢复数据的逻辑
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('功能开发中...')),
        );
      }
    }
  }

  Future<void> _handleClearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('危险操作'),
        content: const Text('这将删除所有本地数据，包括交易记录、目标设置等。此操作不可恢复！确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: 实现清除本地数据的逻辑
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('功能开发中...')),
        );
      }
    }
  }
}
