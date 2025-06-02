import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/device_users_provider.dart';
import '../../core/auth/device_users_manager.dart';

class DeviceUserSelectorDialog extends ConsumerStatefulWidget {
  final List<String> excludeUserIds;
  final Function(List<DeviceUser>) onUsersSelected;
  final bool multiSelect;
  final String title;

  const DeviceUserSelectorDialog({
    super.key,
    this.excludeUserIds = const [],
    required this.onUsersSelected,
    this.multiSelect = true,
    this.title = '选择用户',
  });

  @override
  ConsumerState<DeviceUserSelectorDialog> createState() => _DeviceUserSelectorDialogState();
}

class _DeviceUserSelectorDialogState extends ConsumerState<DeviceUserSelectorDialog> {
  final Set<String> _selectedUserIds = {};
  final TextEditingController _displayNameController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceUsersAsync = ref.watch(deviceUsersNotifierProvider);

    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.users,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),

            // 内容区域
            Flexible(
              child: deviceUsersAsync.when(
                data: (users) => _buildUserList(users),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '加载用户列表失败',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _showAddUserDialog,
                    icon: const Icon(LucideIcons.userPlus),
                    label: const Text('添加用户'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedUserIds.isEmpty ? null : _confirmSelection,
                    child: Text('确定 (${_selectedUserIds.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<DeviceUser> users) {
    final availableUsers = users
        .where((user) => !widget.excludeUserIds.contains(user.id))
        .toList();

    if (availableUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.userX,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无可选用户',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '请先添加用户账号',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: availableUsers.length,
      itemBuilder: (context, index) {
        final user = availableUsers[index];
        final isSelected = _selectedUserIds.contains(user.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              (user.displayName ?? user.email).substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(user.displayName ?? user.email),
          subtitle: user.displayName != null ? Text(user.email) : null,
          trailing: widget.multiSelect
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleUserSelection(user.id),
                )
              : isSelected
                  ? Icon(
                      LucideIcons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
          onTap: () => _toggleUserSelection(user.id),
        );
      },
    );
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (widget.multiSelect) {
        if (_selectedUserIds.contains(userId)) {
          _selectedUserIds.remove(userId);
        } else {
          _selectedUserIds.add(userId);
        }
      } else {
        _selectedUserIds.clear();
        _selectedUserIds.add(userId);
      }
    });
  }

  void _confirmSelection() async {
    final deviceUsersAsync = ref.read(deviceUsersNotifierProvider);
    final users = deviceUsersAsync.value ?? [];
    
    final selectedUsers = users
        .where((user) => _selectedUserIds.contains(user.id))
        .toList();
    
    widget.onUsersSelected(selectedUsers);
    Navigator.of(context).pop();
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加用户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入用户的显示名称：'),
            const SizedBox(height: 16),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: '显示名称',
                hintText: '例如：张三',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: _addUser,
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _addUser() {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) return;

    // 这里应该实现添加用户的逻辑
    // 暂时创建一个临时用户
    final newUser = DeviceUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: '$displayName@temp.local',
      displayName: displayName,
      addedAt: DateTime.now(),
    );

    ref.read(deviceUsersNotifierProvider.notifier).addUser(newUser);
    
    _displayNameController.clear();
    Navigator.of(context).pop();
  }
}
