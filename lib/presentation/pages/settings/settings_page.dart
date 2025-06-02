import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/theme_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../providers/color_theme_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authServiceProvider);
    final colorTheme = ref.watch(colorThemeNotifierProvider);

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
                        child: Text(authState.user!.email![0].toUpperCase()),
                      ),
                      title: Text(authState.user!.email!),
                      subtitle: const Text('Supabase 用户'),
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
                  ListTile(
                    leading: const Icon(LucideIcons.download),
                    title: const Text('版本管理'),
                    subtitle: const Text('检查更新和版本信息'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      context.go('/settings/version');
                    },
                  ),
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
}
