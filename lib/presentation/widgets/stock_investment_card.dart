import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction.dart';
import '../providers/color_theme_provider.dart';

class StockInvestmentCard extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StockInvestmentCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => _buildCard(context, theme, colorScheme, colors),
      loading: () => _buildLoadingCard(context, theme, colorScheme),
      error: (_, __) => _buildLoadingCard(context, theme, colorScheme),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, colors) {
    final profitLossValue = transaction.profitLoss.toDouble();
    final profitColor = colors.getColorByValue(profitLossValue);
    final isProfit = profitLossValue > 0;
    final isBuy = transaction.amount.toDouble() > 0;
    final transactionType = isBuy ? '买入' : '卖出';
    final transactionAmount = transaction.amount.abs();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 交易类型图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBuy
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isBuy ? Icons.add_shopping_cart : Icons.sell,
                      color: isBuy ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 股票信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isBuy
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isBuy
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                transactionType,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isBuy ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${transaction.stockName} (${transaction.stockCode})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transactionAmount.toStringAsFixed(0)}股 × ￥${transaction.unitPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右侧信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (profitLossValue != 0) ...[
                        Text(
                          '￥${transaction.profitLoss.abs().toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: profitColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '￥${(transactionAmount * transaction.unitPrice).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

              // 交易信息
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    label: isBuy ? '投资金额' : '卖出金额',
                    value: '￥${(transactionAmount * transaction.unitPrice).toStringAsFixed(2)}',
                  ),
                  const SizedBox(width: 8),
                  if (profitLossValue != 0) ...[
                    _InfoChip(
                      label: isProfit ? '盈利' : '亏损',
                      value: '￥${transaction.profitLoss.abs().toStringAsFixed(2)}',
                      valueColor: profitColor,
                    ),
                  ] else ...[
                    _InfoChip(
                      label: '盈亏',
                      value: '￥0.00',
                      valueColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),

              // 标签
              if (transaction.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: transaction.tags.map((tag) => Chip(
                    label: Text(tag),
                    labelStyle: theme.textTheme.bodySmall,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],

              // 备注
              if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  transaction.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 操作按钮
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        iconSize: 20,
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        iconSize: 20,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final profitLossValue = transaction.profitLoss.toDouble();
    final isBuy = transaction.amount.toDouble() > 0;
    final transactionType = isBuy ? '买入' : '卖出';
    final transactionAmount = transaction.amount.abs();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 交易类型图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isBuy ? Icons.add_shopping_cart : Icons.sell,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 股票信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                transactionType,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${transaction.stockName} (${transaction.stockCode})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transactionAmount.toStringAsFixed(0)}股 × ￥${transaction.unitPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右侧信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (profitLossValue != 0) ...[
                        Text(
                          '￥${transaction.profitLoss.abs().toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '￥${(transactionAmount * transaction.unitPrice).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

              // 交易信息
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    label: isBuy ? '投资金额' : '卖出金额',
                    value: '￥${(transactionAmount * transaction.unitPrice).toStringAsFixed(2)}',
                  ),
                  const SizedBox(width: 8),
                  if (profitLossValue != 0) ...[
                    _InfoChip(
                      label: profitLossValue > 0 ? '盈利' : '亏损',
                      value: '￥${transaction.profitLoss.abs().toStringAsFixed(2)}',
                      valueColor: Colors.grey,
                    ),
                  ] else ...[
                    _InfoChip(
                      label: '盈亏',
                      value: '￥0.00',
                      valueColor: Colors.grey,
                    ),
                  ],
                ],
              ),

              // 标签
              if (transaction.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: transaction.tags.map((tag) => Chip(
                    label: Text(tag),
                    labelStyle: theme.textTheme.bodySmall,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],

              // 备注
              if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  transaction.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 操作按钮
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        iconSize: 20,
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        iconSize: 20,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
