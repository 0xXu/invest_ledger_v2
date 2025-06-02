import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/auth/device_users_manager.dart';
import '../../providers/device_users_provider.dart';

class AccountSwitcherPage extends ConsumerWidget {
  const AccountSwitcherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceUsersAsync = ref.watch(deviceUsersNotifierProvider);
    final authState = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号切换'),
        actions: [
          IconButton(
            onPressed: () => _showAddAccountDialog(context, ref),
            icon: const Icon(LucideIcons.userPlus),
            tooltip: '添加账号',
          ),
        ],
      ),
      body: deviceUsersAsync.when(
        data: (users) => _buildUserList(context, ref, users, authState.user?.id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                '加载账号列表失败',
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
        ),
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    WidgetRef ref,
    List<DeviceUser> users,
    String? currentUserId,
  ) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.users,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无账号',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              '请添加一个账号开始使用',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddAccountDialog(context, ref),
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('添加账号'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user.id == currentUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrentUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (user.displayName ?? user.email).substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.displayName ?? user.email,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.displayName != null) Text(user.email),
                if (user.lastLoginAt != null)
                  Text(
                    '最后登录: ${_formatDateTime(user.lastLoginAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: isCurrentUser
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '当前',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, ref, value, user),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [
                            Icon(LucideIcons.logIn),
                            SizedBox(width: 8),
                            Text('切换到此账号'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.edit),
                            SizedBox(width: 8),
                            Text('编辑显示名称'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2, color: Colors.red),
                            SizedBox(width: 8),
                            Text('移除账号', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
            onTap: isCurrentUser ? null : () => _switchToAccount(context, ref, user),
          ),
        );
      },
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    DeviceUser user,
  ) {
    switch (action) {
      case 'switch':
        _switchToAccount(context, ref, user);
        break;
      case 'edit':
        _showEditDisplayNameDialog(context, ref, user);
        break;
      case 'remove':
        _showRemoveAccountDialog(context, ref, user);
        break;
    }
  }

  void _switchToAccount(BuildContext context, WidgetRef ref, DeviceUser user) {
    // 这里应该实现切换到指定账号的逻辑
    // 由于我们使用的是 Supabase，需要重新登录
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('请使用 ${user.email} 重新登录'),
        action: SnackBarAction(
          label: '去登录',
          onPressed: () => context.go('/auth/login'),
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加账号'),
        content: const Text('要添加新账号，请先退出当前账号，然后使用新的邮箱注册或登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/auth/login');
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  void _showEditDisplayNameDialog(BuildContext context, WidgetRef ref, DeviceUser user) {
    final controller = TextEditingController(text: user.displayName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑显示名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '显示名称',
            hintText: '输入新的显示名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(deviceUsersNotifierProvider.notifier)
                    .updateDisplayName(user.id, newName);
              }
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showRemoveAccountDialog(BuildContext context, WidgetRef ref, DeviceUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除账号'),
        content: Text('确定要移除账号 "${user.displayName ?? user.email}" 吗？\n\n这只会从设备上移除账号记录，不会删除实际的用户账户。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(deviceUsersNotifierProvider.notifier).removeUser(user.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
