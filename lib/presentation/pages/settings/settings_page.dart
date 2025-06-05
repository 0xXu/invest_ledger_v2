import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/theme_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../providers/color_theme_provider.dart';
import '../../providers/version_provider.dart';
import '../../../data/models/color_theme_setting.dart';
import '../dev/dev_tools_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _developerTapCount = 0;
  bool _showDevTools = false;
  bool _hasTriggeredVersionCheck = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authServiceProvider);
    final colorTheme = ref.watch(colorThemeNotifierProvider);

    // 如果用户已登录且还没有触发过版本检查，触发一次版本检查
    if (authState.user != null && !_hasTriggeredVersionCheck) {
      _hasTriggeredVersionCheck = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(versionCheckProvider.notifier).autoCheckForUpdates();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          if (authState.user != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户信息',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(_getDisplayInitial(authState.user!)),
                      ),
                      title: Text(_getDisplayName(authState.user!)),
                      subtitle: Text(_getDisplaySubtitle(authState.user!)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.go('/settings/accounts');
                            },
                            icon: const Icon(LucideIcons.users),
                            label: const Text('账号管理'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref.read(authServiceProvider.notifier).signOut();
                              if (context.mounted) {
                                context.go('/auth/login');
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('退出登录'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '外观设置',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('主题模式'),
                    subtitle: Text(_getThemeModeText(themeMode)),
                    trailing: _buildThemeModeDropdown(themeMode),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('盈亏颜色'),
                    subtitle: Text(colorTheme.colorScheme.description),
                    trailing: _buildColorSchemeDropdown(colorTheme.colorScheme),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 数据管理
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '数据管理',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(LucideIcons.database),
                    title: const Text('导入导出'),
                    subtitle: const Text('备份和恢复数据'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      context.go('/import-export');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 开发工具 (隐藏功能，需要点击8次开发者才显示)
          if (_showDevTools)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '开发工具',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.developer_mode),
                      title: const Text('开发工具'),
                      subtitle: const Text('示例数据和调试功能'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DevToolsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_showDevTools) const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '关于',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildVersionManagementTile(context),
                  const Divider(),
                  ListTile(
                    title: const Text('开发者'),
                    subtitle: const Text('0xXu'),
                    onTap: _onDeveloperTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主题模式下拉框
  Widget _buildThemeModeDropdown(ThemeMode currentMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: currentMode,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (ThemeMode? newMode) {
            if (newMode != null) {
              ref.read(themeProvider.notifier).setThemeMode(newMode);
            }
          },
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('跟随系统'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('浅色模式'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('深色模式'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建颜色方案下拉框
  Widget _buildColorSchemeDropdown(ProfitLossColorScheme currentScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProfitLossColorScheme>(
          value: currentScheme,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (ProfitLossColorScheme? newScheme) {
            if (newScheme != null) {
              ref.read(colorThemeNotifierProvider.notifier).setColorScheme(newScheme);
            }
          },
          items: ProfitLossColorScheme.values.map((scheme) {
            return DropdownMenuItem(
              value: scheme,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: scheme.profitColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: scheme.lossColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(scheme.displayName),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 开发者点击事件
  void _onDeveloperTap() {
    setState(() {
      _developerTapCount++;
    });

    if (_developerTapCount >= 8) {
      setState(() {
        _showDevTools = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 开发工具已解锁！'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // 给用户一些提示
      final remaining = 8 - _developerTapCount;
      if (_developerTapCount >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('还需要点击 $remaining 次...'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  /// 构建版本管理列表项，包含新版本提示
  Widget _buildVersionManagementTile(BuildContext context) {
    final versionCheckAsync = ref.watch(versionCheckProvider);

    return versionCheckAsync.when(
      data: (result) {
        final hasUpdate = result.hasUpdate && result.latestVersion != null;

        return ListTile(
          leading: Stack(
            children: [
              Icon(
                LucideIcons.download,
                color: hasUpdate
                  ? Theme.of(context).colorScheme.primary
                  : null,
              ),
              if (hasUpdate)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Text(
                '版本管理',
                style: hasUpdate ? TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ) : null,
              ),
              if (hasUpdate) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            hasUpdate
              ? '发现新版本 ${result.latestVersion!.tagName}，点击查看详情'
              : '检查更新和版本信息',
            style: hasUpdate ? TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ) : null,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasUpdate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '有更新',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                color: hasUpdate
                  ? Theme.of(context).colorScheme.primary
                  : null,
              ),
            ],
          ),
          onTap: () {
            context.go('/settings/version');
          },
        );
      },
      loading: () => ListTile(
        leading: const Icon(LucideIcons.download),
        title: const Text('版本管理'),
        subtitle: const Text('检查更新和版本信息'),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () {
          context.go('/settings/version');
        },
      ),
      error: (error, stack) => ListTile(
        leading: const Icon(LucideIcons.download),
        title: const Text('版本管理'),
        subtitle: const Text('检查更新和版本信息'),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () {
          context.go('/settings/version');
        },
      ),
    );
  }

  /// 获取显示名称（优先显示用户名，否则显示邮箱）
  String _getDisplayName(dynamic user) {
    // 尝试从用户元数据中获取用户名，按优先级顺序
    final userMetadata = user.userMetadata;
    if (userMetadata != null) {
      // 优先级：username > display_name > name
      final username = userMetadata['username'] as String?;
      final displayName = userMetadata['display_name'] as String?;
      final name = userMetadata['name'] as String?;

      if (username != null && username.isNotEmpty && username != user.email) {
        return username;
      }

      if (displayName != null && displayName.isNotEmpty && displayName != user.email) {
        return displayName;
      }

      if (name != null && name.isNotEmpty && name != user.email) {
        return name;
      }
    }

    // 如果没有有效的用户名，返回邮箱
    return user.email ?? '未知用户';
  }

  /// 获取显示的副标题
  String _getDisplaySubtitle(dynamic user) {
    // 检查是否有有效的用户名
    final userMetadata = user.userMetadata;
    bool hasUsername = false;

    if (userMetadata != null) {
      final username = userMetadata['username'] as String?;
      final displayName = userMetadata['display_name'] as String?;
      final name = userMetadata['name'] as String?;

      hasUsername = (username != null && username.isNotEmpty && username != user.email) ||
                   (displayName != null && displayName.isNotEmpty && displayName != user.email) ||
                   (name != null && name.isNotEmpty && name != user.email);
    }

    if (hasUsername) {
      // 如果有用户名，副标题显示邮箱
      return user.email ?? 'Supabase 用户';
    } else {
      // 如果没有用户名，副标题显示用户类型
      return 'Supabase 用户';
    }
  }

  /// 获取头像显示的首字母
  String _getDisplayInitial(dynamic user) {
    // 尝试从用户元数据中获取用户名，按优先级顺序
    final userMetadata = user.userMetadata;
    if (userMetadata != null) {
      final username = userMetadata['username'] as String?;
      final displayName = userMetadata['display_name'] as String?;
      final name = userMetadata['name'] as String?;

      if (username != null && username.isNotEmpty && username != user.email) {
        return username[0].toUpperCase();
      }

      if (displayName != null && displayName.isNotEmpty && displayName != user.email) {
        return displayName[0].toUpperCase();
      }

      if (name != null && name.isNotEmpty && name != user.email) {
        return name[0].toUpperCase();
      }
    }

    // 如果没有有效的用户名，使用邮箱首字母
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return 'U'; // 默认显示 U (User)
  }
}
