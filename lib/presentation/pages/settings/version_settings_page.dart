import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/version_provider.dart';
import '../../widgets/update_dialog.dart';
import '../../../shared/widgets/loading_overlay.dart';

class VersionSettingsPage extends ConsumerStatefulWidget {
  const VersionSettingsPage({super.key});

  @override
  ConsumerState<VersionSettingsPage> createState() => _VersionSettingsPageState();
}

class _VersionSettingsPageState extends ConsumerState<VersionSettingsPage> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final autoCheckEnabled = ref.watch(autoCheckEnabledProvider);
    final versionCheckAsync = ref.watch(versionCheckProvider);
    final lastCheckTimeAsync = ref.watch(lastCheckTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('版本管理'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前版本信息
              _buildCurrentVersionCard(packageInfoAsync, theme),

              const SizedBox(height: 24),

              // 更新检查设置
              _buildUpdateSettingsCard(autoCheckEnabled, theme),

              const SizedBox(height: 24),

              // 检查更新
              _buildCheckUpdateCard(versionCheckAsync, lastCheckTimeAsync, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentVersionCard(AsyncValue<dynamic> packageInfoAsync, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.info,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '应用信息',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            packageInfoAsync.when(
              data: (packageInfo) => Column(
                children: [
                  _buildInfoRow('应用名称', packageInfo.appName, theme),
                  _buildInfoRow('版本号', packageInfo.version, theme),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('加载失败: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSettingsCard(bool autoCheckEnabled, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.settings,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '更新设置',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('自动检查更新'),
              subtitle: const Text('应用启动时自动检查新版本'),
              value: autoCheckEnabled,
              onChanged: (value) {
                ref.read(autoCheckEnabledProvider.notifier).setAutoCheckEnabled(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCheckUpdateCard(
    AsyncValue<dynamic> versionCheckAsync,
    AsyncValue<DateTime?> lastCheckTimeAsync,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.download,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '检查更新',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 最后检查时间
            lastCheckTimeAsync.when(
              data: (lastCheck) => Text(
                lastCheck != null 
                    ? '最后检查: ${_formatDateTime(lastCheck)}'
                    : '尚未检查过更新',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 12),
            
            // 检查结果
            versionCheckAsync.when(
              data: (result) => _buildCheckResult(result, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '检查失败: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _checkForUpdates,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('立即检查'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckResult(dynamic result, ThemeData theme) {
    if (result.hasUpdate && result.latestVersion != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '发现新版本 ${result.latestVersion.tagName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showUpdateDialog(result),
              child: const Text('查看'),
            ),
          ],
        ),
      );
    } else if (result.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.xCircle,
              color: theme.colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.checkCircle,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '当前已是最新版本',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
  }



  Future<void> _checkForUpdates() async {
    await ref.read(versionCheckProvider.notifier).checkForUpdates();
    ref.invalidate(lastCheckTimeProvider);
  }

  Future<void> _showUpdateDialog(dynamic result) async {
    final currentVersion = await ref.read(currentVersionProvider.future);
    
    if (mounted) {
      UpdateDialog.show(
        context,
        versionInfo: result.latestVersion,
        currentVersion: currentVersion,
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }


}
