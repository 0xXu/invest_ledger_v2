import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/models/version_info.dart';
import '../../data/services/download_service.dart';
import '../providers/version_provider.dart';
import '../providers/download_provider.dart';

class UpdateDialog extends ConsumerWidget {
  final VersionInfo versionInfo;
  final String currentVersion;
  final bool canSkip;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.currentVersion,
    this.canSkip = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(versionInfoProvider);
    final theme = Theme.of(context);
    final downloadState = ref.watch(downloadProvider);

    // 移动端适配：使用不同的对话框样式
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return _buildMobileDialog(context, ref, theme, formatter, downloadState);
    } else {
      return _buildDesktopDialog(context, ref, theme, formatter, downloadState);
    }
  }

  Widget _buildMobileDialog(BuildContext context, WidgetRef ref, ThemeData theme,
      dynamic formatter, DownloadState downloadState) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8; // 最大高度为屏幕高度的80%

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVersionInfo(theme, formatter),
                    const SizedBox(height: 16),
                    _buildUpdateContent(theme, formatter),
                    const SizedBox(height: 20),
                    if (downloadState.progress != null)
                      _buildDownloadProgress(theme, downloadState),
                  ],
                ),
              ),
            ),
            _buildActions(context, ref, theme, downloadState, isMobile: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDialog(BuildContext context, WidgetRef ref, ThemeData theme,
      dynamic formatter, DownloadState downloadState) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxContentHeight = screenHeight * 0.6; // 内容区域最大高度为屏幕高度的60%

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: _buildHeader(theme),
      content: SizedBox(
        width: 400,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxContentHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVersionInfo(theme, formatter),
                const SizedBox(height: 16),
                _buildUpdateContent(theme, formatter),
                if (downloadState.progress != null) ...[
                  const SizedBox(height: 20),
                  _buildDownloadProgress(theme, downloadState),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildActions(context, ref, theme, downloadState, isMobile: false),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.download,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发现新版本',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  versionInfo.tagName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(ThemeData theme, dynamic formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前版本',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatter.formatVersion(currentVersion),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Icon(
                LucideIcons.arrowRight,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '最新版本',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatter.formatVersion(versionInfo.tagName),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '发布于 ${formatter.formatPublishTime(versionInfo.publishedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateContent(ThemeData theme, dynamic formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '更新内容',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 150), // 限制最大高度
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: SingleChildScrollView(
            child: Text(
              formatter.formatReleaseNotes(versionInfo.body),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadProgress(ThemeData theme, DownloadState downloadState) {
    final progress = downloadState.progress!;
    final isDownloading = progress.status == DownloadStatus.downloading;
    final isCompleted = progress.status == DownloadStatus.completed;
    final isFailed = progress.status == DownloadStatus.failed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isDownloading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.progress,
                  ),
                )
              else if (isCompleted)
                const Icon(
                  LucideIcons.checkCircle,
                  color: Colors.green,
                  size: 16,
                )
              else if (isFailed)
                const Icon(
                  LucideIcons.xCircle,
                  color: Colors.red,
                  size: 16,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDownloading
                      ? '正在下载...'
                      : isCompleted
                          ? '下载完成'
                          : '下载失败',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isDownloading)
                Text(
                  '${(progress.progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DownloadService.formatFileSize(progress.downloaded)} / ${DownloadService.formatFileSize(progress.total)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (isFailed && progress.error != null) ...[
            const SizedBox(height: 8),
            Text(
              '错误: ${progress.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, ThemeData theme,
      DownloadState downloadState, {required bool isMobile}) {
    final progress = downloadState.progress;
    final isDownloading = progress?.status == DownloadStatus.downloading;
    final isCompleted = progress?.status == DownloadStatus.completed;
    final isFailed = progress?.status == DownloadStatus.failed;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            if (isCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(downloadProvider.notifier).installApk();
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('安装失败: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.package),
                  label: const Text('立即安装'),
                ),
              ),
              const SizedBox(height: 8),
            ] else if (isDownloading) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(downloadProvider.notifier).hideDialog();
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('后台下载'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(downloadProvider.notifier).cancelDownload();
                      },
                      child: const Text('取消下载'),
                    ),
                  ),
                ],
              ),
            ] else if (isFailed) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(downloadProvider.notifier).downloadApk(versionInfo);
                  },
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text('重新下载'),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(downloadProvider.notifier).downloadApk(versionInfo);
                  },
                  icon: const Icon(LucideIcons.download),
                  label: const Text('立即下载'),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 底部按钮行
            Row(
              children: [
                if (canSkip && !isDownloading)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        '稍后提醒',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                if (canSkip && !isDownloading) const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      isDownloading ? '关闭' : '忽略此版本',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // 桌面端按钮
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canSkip && !isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '稍后提醒',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (!isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '忽略此版本',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (isCompleted)
            FilledButton.icon(
              onPressed: () async {
                try {
                  await ref.read(downloadProvider.notifier).installApk();
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('安装失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.package, size: 18),
              label: const Text('立即安装'),
            )
          else if (isDownloading)
            OutlinedButton(
              onPressed: () {
                ref.read(downloadProvider.notifier).cancelDownload();
              },
              child: const Text('取消下载'),
            )
          else if (isFailed)
            FilledButton.icon(
              onPressed: () {
                ref.read(downloadProvider.notifier).downloadApk(versionInfo);
              },
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('重新下载'),
            )
          else
            FilledButton.icon(
              onPressed: () {
                ref.read(downloadProvider.notifier).downloadApk(versionInfo);
              },
              icon: const Icon(LucideIcons.download, size: 18),
              label: const Text('立即下载'),
            ),
        ],
      );
    }
  }

  /// 显示更新对话框
  static Future<bool?> show(
    BuildContext context, {
    required VersionInfo versionInfo,
    required String currentVersion,
    bool canSkip = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: canSkip,
      builder: (context) => UpdateDialog(
        versionInfo: versionInfo,
        currentVersion: currentVersion,
        canSkip: canSkip,
      ),
    );
  }
}
