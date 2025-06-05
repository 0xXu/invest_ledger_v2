import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/import_result.dart';
import '../../providers/import_export_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/animated_card.dart';

class ImportExportPage extends ConsumerStatefulWidget {
  const ImportExportPage({super.key});

  @override
  ConsumerState<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends ConsumerState<ImportExportPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authServiceProvider);
    final importExportState = ref.watch(importExportNotifierProvider);
    final autoBackupNotifier = ref.watch(autoBackupNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
        actions: [
          RefreshButton.icon(
            onRefresh: () async {
              // 检查是否需要自动备份
              await autoBackupNotifier.performAutoBackup();
            },
            loadingMessage: '正在检查备份...',
            tooltip: '检查自动备份',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: importExportState.isLoading,
        child: authState.user == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.userX, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '请先登录',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 导出功能区
                SmartAnimatedCard(
                  initialDelay: const Duration(milliseconds: 100),
                  animationType: CardAnimationType.fadeSlideIn,
                  slideDirection: SlideDirection.fromTop,
                  enableInitialAnimation: true,
                  child: _ExportSection(),
                ),
                const SizedBox(height: 16),

                // 导入功能区
                SmartAnimatedCard(
                  initialDelay: const Duration(milliseconds: 200),
                  animationType: CardAnimationType.fadeSlideIn,
                  slideDirection: SlideDirection.fromTop,
                  enableInitialAnimation: true,
                  child: _ImportSection(),
                ),
                const SizedBox(height: 16),

                // 备份功能区
                SmartAnimatedCard(
                  initialDelay: const Duration(milliseconds: 300),
                  animationType: CardAnimationType.fadeSlideIn,
                  slideDirection: SlideDirection.fromTop,
                  enableInitialAnimation: true,
                  child: _BackupSection(),
                ),
                const SizedBox(height: 16),

                // 使用说明
                SmartAnimatedCard(
                  initialDelay: const Duration(milliseconds: 400),
                  animationType: CardAnimationType.fadeSlideIn,
                  slideDirection: SlideDirection.fromTop,
                  enableInitialAnimation: true,
                  child: _HelpSection(),
                ),
              ],
            ),
      ),
    );
  }
}

class _ExportSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.download,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '数据导出',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ActionTile(
              title: '导出交易记录',
              subtitle: '导出格式：日期,股票代码,股票名称,交易类型,数量,单价,盈亏,备注\n包含完整的交易记录和盈亏计算',
              icon: LucideIcons.fileSpreadsheet,
              color: Colors.green,
              onTap: () => _exportTransactions(context, ref),
            ),
            const SizedBox(height: 8),

            _ActionTile(
              title: '导出完整备份',
              subtitle: '导出所有数据（交易、共享投资、目标）为JSON备份文件',
              icon: LucideIcons.database,
              color: Colors.blue,
              onTap: () => _exportFullBackup(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTransactions(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(importExportNotifierProvider.notifier);
      final filePath = await notifier.exportTransactionsToCSV();

      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('交易记录已导出到:\n$filePath')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('导出失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportFullBackup(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(importExportNotifierProvider.notifier);
      final filePath = await notifier.exportFullBackup();

      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('完整备份已保存到:\n$filePath')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('备份失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ImportSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.upload,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '数据导入',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ActionTile(
              title: '导入CSV交易记录',
              subtitle: '格式：日期,股票代码,股票名称,交易类型,数量,单价,盈亏,备注\n系统自动计算卖出盈亏',
              icon: LucideIcons.fileSpreadsheet,
              color: Colors.green,
              onTap: () => _importTransactionsFromCSV(context, ref),
            ),
            const SizedBox(height: 8),

            _ActionTile(
              title: '导入TXT交易记录',
              subtitle: '格式：日期 股票代码 股票名称 数量 单价 备注\n数量负数=卖出，系统自动计算盈亏',
              icon: LucideIcons.fileText,
              color: Colors.blue,
              onTap: () => _importTransactionsFromTXT(context, ref),
            ),
            const SizedBox(height: 8),

            _ActionTile(
              title: '恢复完整备份',
              subtitle: '从JSON备份文件恢复所有数据（会覆盖现有数据）',
              icon: LucideIcons.refreshCw,
              color: Colors.red,
              onTap: () => _importFullBackup(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importTransactionsFromCSV(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(importExportNotifierProvider.notifier);
      final count = await notifier.importTransactionsFromCSV();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Text('成功从CSV导入 $count 条交易记录'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // 显示详细的错误信息对话框
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(LucideIcons.alertCircle, color: Colors.red),
            title: const Text('CSV导入失败'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '导入过程中发生错误：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      e.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '请检查：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• CSV文件格式是否正确'),
                  const Text('• 日期格式是否为 YYYY-MM-DD'),
                  const Text('• 数值字段是否包含非数字字符'),
                  const Text('• 文件编码是否为UTF-8'),
                  const Text('• 是否包含必需的字段：日期、股票代码、股票名称、交易类型、数量、单价'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _importTransactionsFromTXT(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(importExportNotifierProvider.notifier);
      final result = await notifier.importTransactionsFromTXT();

      if (context.mounted) {
        // 显示详细的导入结果对话框
        await _showImportResultDialog(context, result);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('TXT导入失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFullBackup(BuildContext context, WidgetRef ref) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(LucideIcons.alertTriangle, color: Colors.red),
        title: const Text('确认恢复数据'),
        content: const Text(
          '恢复数据将会覆盖当前所有数据，此操作不可撤销。\n\n'
          '建议在恢复前先导出当前数据作为备份。\n\n'
          '确定要继续吗？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final notifier = ref.read(importExportNotifierProvider.notifier);
      final result = await notifier.importFullBackup();

      if (context.mounted) {
        final message = '数据恢复完成:\n'
            '• 交易记录: ${result['transactions']} 条\n'
            '• 共享投资: ${result['sharedInvestments']} 个\n'
            '• 投资目标: ${result['investmentGoals']} 个';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('恢复失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示导入结果对话框
  Future<void> _showImportResultDialog(BuildContext context, TxtImportResult result) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.successCount > 0 ? LucideIcons.checkCircle : LucideIcons.alertCircle,
          color: result.successCount > 0 ? Colors.green : Colors.orange,
        ),
        title: const Text('导入结果'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总体统计
              _ResultStatItem(
                icon: LucideIcons.fileText,
                label: '检测格式',
                value: result.detectedFormat,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),

              _ResultStatItem(
                icon: LucideIcons.list,
                label: '总行数',
                value: '${result.totalLines}',
                color: Colors.grey,
              ),
              const SizedBox(height: 8),

              _ResultStatItem(
                icon: LucideIcons.checkCircle,
                label: '成功导入',
                value: '${result.successCount}',
                color: Colors.green,
              ),
              const SizedBox(height: 8),

              if (result.duplicateCount > 0) ...[
                _ResultStatItem(
                  icon: LucideIcons.copy,
                  label: '重复跳过',
                  value: '${result.duplicateCount}',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
              ],

              if (result.errorCount > 0) ...[
                _ResultStatItem(
                  icon: LucideIcons.alertCircle,
                  label: '解析失败',
                  value: '${result.errorCount}',
                  color: Colors.red,
                ),
                const SizedBox(height: 16),

                // 错误详情
                if (result.errors.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        '错误详情:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '共 ${result.errors.length} 个错误',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 300, // 增加高度以显示更多错误
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: result.errors.length, // 显示所有错误，不再限制为5个
                      itemBuilder: (context, index) {
                        final error = result.errors[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.alertTriangle,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '第 ${error.lineNumber} 行',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.red.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          error.errorType,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      error.lineContent,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      error.errorMessage,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 结果统计项组件
class _ResultStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _BackupSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastBackup = ref.watch(autoBackupNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.shield,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '自动备份',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (lastBackup != null) ...[
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '上次备份: ${_formatDate(lastBackup)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            _ActionTile(
              title: '立即备份',
              subtitle: '手动执行一次完整数据备份到应用目录',
              icon: LucideIcons.save,
              color: Colors.purple,
              onTap: () => _performManualBackup(context, ref),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(LucideIcons.info, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '应用会每周自动备份一次数据到本地目录',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _performManualBackup(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(importExportNotifierProvider.notifier);
      final backupPath = await notifier.autoBackup();

      // 更新最后备份时间
      ref.read(autoBackupNotifierProvider.notifier).setLastBackupTime(DateTime.now());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('备份完成:\n$backupPath')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('备份失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _HelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.helpCircle,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '使用说明',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _HelpItem(
              icon: LucideIcons.fileSpreadsheet,
              title: 'CSV格式说明',
              content: '导出的CSV文件包含：日期、股票代码、股票名称、交易类型、数量、价格、总金额、手续费、备注等字段。',
            ),
            const SizedBox(height: 12),

            _HelpItem(
              icon: LucideIcons.fileText,
              title: 'TXT格式说明',
              content: 'TXT文件支持多种分隔符：制表符、逗号、空格、竖线、分号。格式：日期 股票代码 股票名称 数量 单价 [备注]。支持多种日期格式，可使用#或//添加注释。',
            ),
            const SizedBox(height: 12),

            _HelpItem(
              icon: LucideIcons.database,
              title: 'JSON备份说明',
              content: 'JSON备份包含完整的应用数据，包括用户信息、交易记录、共享投资和投资目标。',
            ),
            const SizedBox(height: 12),

            _HelpItem(
              icon: LucideIcons.shield,
              title: '数据安全',
              content: '所有数据都存储在本地，不会上传到云端。建议定期备份重要数据。',
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(50)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
