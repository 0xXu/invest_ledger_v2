import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:decimal/decimal.dart';

import '../../../data/models/shared_investment.dart';
import '../../../data/models/color_theme_setting.dart';
import '../../providers/color_theme_provider.dart';

class CompleteInvestmentDialog extends ConsumerStatefulWidget {
  final SharedInvestment sharedInvestment;
  final Function(Decimal? sellAmount, Map<String, Decimal> participantProfitLoss) onComplete;

  const CompleteInvestmentDialog({
    super.key,
    required this.sharedInvestment,
    required this.onComplete,
  });

  @override
  ConsumerState<CompleteInvestmentDialog> createState() => _CompleteInvestmentDialogState();
}

class _CompleteInvestmentDialogState extends ConsumerState<CompleteInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sellAmountController = TextEditingController();
  final Map<String, TextEditingController> _profitLossControllers = {};

  bool _autoCalculate = true;
  Decimal? _totalSellAmount;

  @override
  void initState() {
    super.initState();

    // 初始化参与者盈亏控制器
    for (final participant in widget.sharedInvestment.participants) {
      _profitLossControllers[participant.id] = TextEditingController(
        text: participant.profitLoss.toString(),
      );
    }

    // 如果已有卖出金额，使用它
    if (widget.sharedInvestment.sellAmount != null) {
      _sellAmountController.text = widget.sharedInvestment.sellAmount!.toString();
      _totalSellAmount = widget.sharedInvestment.sellAmount;
      _calculateProfitLoss();
    }
  }

  @override
  void dispose() {
    _sellAmountController.dispose();
    for (final controller in _profitLossControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.checkCircle,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('完成投资')),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '投资名称: ${widget.sharedInvestment.name}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '股票: ${widget.sharedInvestment.stockName} (${widget.sharedInvestment.stockCode})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 卖出总金额
                  TextFormField(
                    controller: _sellAmountController,
                    decoration: const InputDecoration(
                      labelText: '卖出总金额',
                      prefixIcon: Icon(LucideIcons.dollarSign),
                      prefixText: '¥',
                      helperText: '输入股票卖出的总金额',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入卖出总金额';
                      }
                      final amount = Decimal.tryParse(value.trim());
                      if (amount == null || amount <= Decimal.zero) {
                        return '请输入有效的金额';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final amount = Decimal.tryParse(value.trim());
                      if (amount != null) {
                        setState(() {
                          _totalSellAmount = amount;
                          if (_autoCalculate) {
                            _calculateProfitLoss();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 自动计算开关
                  Row(
                    children: [
                      Switch(
                        value: _autoCalculate,
                        onChanged: (value) {
                          setState(() {
                            _autoCalculate = value;
                            if (value && _totalSellAmount != null) {
                              _calculateProfitLoss();
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '自动按比例计算盈亏',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 参与者盈亏
                  Text(
                    '参与者盈亏分配',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...widget.sharedInvestment.participants.map((participant) {
                    final controller = _profitLossControllers[participant.id]!;
                    final profitLoss = Decimal.tryParse(controller.text) ?? Decimal.zero;
                    final profitLossColor = colors.getColorByValue(profitLoss.toDouble());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  participant.userName.isNotEmpty
                                      ? participant.userName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      participant.userName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '投资: ¥${participant.investmentAmount.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: '盈亏金额',
                              prefixIcon: Icon(
                                profitLoss >= Decimal.zero
                                    ? LucideIcons.trendingUp
                                    : LucideIcons.trendingDown,
                                color: profitLossColor,
                              ),
                              prefixText: '¥',
                              labelStyle: TextStyle(color: profitLossColor),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: profitLossColor.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: profitLossColor),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            enabled: !_autoCalculate,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入盈亏金额';
                              }
                              final amount = Decimal.tryParse(value.trim());
                              if (amount == null) {
                                return '请输入有效的金额';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // 总计信息
                  _buildSummaryCard(theme, colors),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _handleComplete,
            child: const Text('完成投资'),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Icon(Icons.error)),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, ProfitLossColors colors) {
    final totalProfitLoss = _profitLossControllers.values.fold(
      Decimal.zero,
      (sum, controller) => sum + (Decimal.tryParse(controller.text) ?? Decimal.zero),
    );

    final totalInvestment = widget.sharedInvestment.totalAmount;
    final sellAmount = _totalSellAmount ?? Decimal.zero;
    final expectedProfitLoss = sellAmount - totalInvestment;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '汇总信息',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('总投资:'),
              Text('¥${totalInvestment.toStringAsFixed(2)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('卖出金额:'),
              Text('¥${sellAmount.toStringAsFixed(2)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('预期盈亏:'),
              Text(
                '¥${expectedProfitLoss.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.getColorByValue(expectedProfitLoss.toDouble()),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('分配盈亏:'),
              Text(
                '¥${totalProfitLoss.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.getColorByValue(totalProfitLoss.toDouble()),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if ((expectedProfitLoss - totalProfitLoss).abs() > Decimal.parse('0.01'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '分配盈亏与预期盈亏不匹配',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _calculateProfitLoss() {
    if (_totalSellAmount == null) return;

    final totalInvestment = widget.sharedInvestment.totalAmount;
    final totalProfitLoss = _totalSellAmount! - totalInvestment;

    for (final participant in widget.sharedInvestment.participants) {
      final investmentRatio = participant.investmentAmount / totalInvestment;
      final participantProfitLoss = Decimal.parse((totalProfitLoss.toDouble() * investmentRatio.toDouble()).toStringAsFixed(2));

      _profitLossControllers[participant.id]!.text =
          participantProfitLoss.toStringAsFixed(2);
    }
  }

  void _handleComplete() {
    if (!_formKey.currentState!.validate()) return;

    final sellAmount = Decimal.tryParse(_sellAmountController.text.trim());
    final participantProfitLoss = <String, Decimal>{};

    for (final entry in _profitLossControllers.entries) {
      final profitLoss = Decimal.tryParse(entry.value.text.trim()) ?? Decimal.zero;
      participantProfitLoss[entry.key] = profitLoss;
    }

    widget.onComplete(sellAmount, participantProfitLoss);
    Navigator.of(context).pop();
  }
}
