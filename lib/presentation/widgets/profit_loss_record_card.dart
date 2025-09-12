import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/models/transaction.dart';
import '../../core/utils/number_formatter.dart';
import '../providers/color_theme_provider.dart';

class ProfitLossRecordCard extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProfitLossRecordCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => _buildModernCard(context, theme, colors),
      loading: () => _buildLoadingCard(context, theme),
      error: (_, __) => _buildLoadingCard(context, theme),
    );
  }

  Widget _buildModernCard(BuildContext context, ThemeData theme, colors) {
    final profitLossValue = transaction.profitLoss.toDouble();
    final profitColor = colors.getColorByValue(profitLossValue);
    final isProfit = profitLossValue >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: profitColor.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: profitColor.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // 主要信息行
                Row(
                  children: [
                    // 现代化盈亏指示器
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: profitColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isProfit ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        color: profitColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 股票信息区域
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 股票名称
                          Text(
                            transaction.stockName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // 股票名称
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  transaction.stockName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: profitColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isProfit ? '盈利' : '亏损',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: profitColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 盈亏金额和日期
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormatter.formatCurrency(transaction.profitLoss.toDouble()),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: profitColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MM/dd').format(transaction.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 备注信息（优化显示）
                if (_getCleanNotes().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.stickyNote,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCleanNotes(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 操作按钮（现代化设计）
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: onEdit,
                            icon: Icon(
                              LucideIcons.edit3,
                              color: theme.colorScheme.primary,
                            ),
                            iconSize: 18,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ),
                      if (onDelete != null)
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              LucideIcons.trash2,
                              color: theme.colorScheme.error,
                            ),
                            iconSize: 18,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, ThemeData theme) {
    final profitLossValue = transaction.profitLoss.toDouble();
    final isProfit = profitLossValue >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isProfit ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              color: Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.stockName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.stockName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormatter.formatCurrency(transaction.profitLoss.toDouble(), showSign: false),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MM/dd').format(transaction.date),
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

  /// 获取清理后的备注（移除简单模式标识）
  String _getCleanNotes() {
    if (transaction.notes == null) return '';

    String notes = transaction.notes!;
    // 移除简单模式相关的标识
    notes = notes.replaceAll(RegExp(r'（简单模式.*?）'), '');
    notes = notes.replaceAll('从简单模式添加', '');

    // 如果清理后为空，但原始备注不为空，说明备注只包含简单模式标识
    // 这种情况下不显示备注区域
    final cleanedNotes = notes.trim();
    return cleanedNotes.isEmpty ? '' : cleanedNotes;
  }
}
