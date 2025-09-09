import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/models/investment_goal.dart';
import '../providers/investment_goal_provider.dart';

/// 投资目标设置对话框
class GoalSettingDialog extends ConsumerStatefulWidget {
  final InvestmentGoal? currentGoal;
  final bool isYearly; // true表示年度目标，false表示月度目标
  
  const GoalSettingDialog({
    super.key,
    this.currentGoal,
    required this.isYearly,
  });

  @override
  ConsumerState<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends ConsumerState<GoalSettingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  bool _autoCalculateOther = true; // 是否自动计算另一个目标
  String _calculatedAmount = ''; // 缓存计算结果

  @override
  void initState() {
    super.initState();
    if (widget.currentGoal != null) {
      _goalController.text = widget.currentGoal!.targetAmount.toStringAsFixed(0);
    }
    
    // 监听输入变化，实时更新计算结果
    _goalController.addListener(_updateCalculatedAmount);
    _updateCalculatedAmount(); // 初始化计算结果
  }

  @override
  void dispose() {
    _goalController.removeListener(_updateCalculatedAmount);
    _goalController.dispose();
    super.dispose();
  }

  void _updateCalculatedAmount() {
    setState(() {
      _calculatedAmount = _getCalculatedAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.isYearly ? LucideIcons.calendarDays : LucideIcons.calendar,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text('设置${widget.isYearly ? '年度' : '月度'}目标'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '请设置您的${widget.isYearly ? '年度' : '月度'}投资收益目标',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _goalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '目标金额 (¥)',
                hintText: '请输入目标收益金额',
                prefixIcon: const Icon(LucideIcons.target),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入目标金额';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return '请输入有效数字';
                }
                if (amount <= 0) {
                  return '目标金额必须大于0';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            CheckboxListTile(
              value: _autoCalculateOther,
              onChanged: (value) {
                setState(() {
                  _autoCalculateOther = value ?? true;
                  // 状态改变时重新计算
                  _updateCalculatedAmount();
                });
              },
              title: Text(
                widget.isYearly 
                  ? '自动计算月度目标 (年度目标÷12)'
                  : '自动计算年度目标 (月度目标×12)',
                style: theme.textTheme.bodyMedium,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            
            if (_autoCalculateOther) ...[
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _calculatedAmount.contains('请先输入') 
                      ? theme.colorScheme.outline.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calculator,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '自动计算结果：',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _calculatedAmount,
                        key: ValueKey(_calculatedAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _calculatedAmount.contains('请先输入')
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saveGoal,
          child: const Text('保存'),
        ),
      ],
    );
  }

  String _getCalculatedAmount() {
    final inputAmount = double.tryParse(_goalController.text) ?? 0;
    if (inputAmount <= 0) return '请先输入目标金额';
    
    if (widget.isYearly) {
      // 年度目标 -> 月度目标
      final monthlyTarget = inputAmount / 12;
      return '月度目标：¥${monthlyTarget.toStringAsFixed(2)}';
    } else {
      // 月度目标 -> 年度目标
      final yearlyTarget = inputAmount * 12;
      return '年度目标：¥${yearlyTarget.toStringAsFixed(0)}';
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final inputAmount = double.parse(_goalController.text.trim());
    
    try {
      final now = DateTime.now();
      final notifier = ref.read(investmentGoalNotifierProvider.notifier);
      
      debugPrint('🎯 设置目标: ${widget.isYearly ? "年度" : "月度"} - ¥$inputAmount');
      debugPrint('🔄 自动计算对应目标: $_autoCalculateOther');
      
      await notifier.setGoal(
        type: GoalType.profit,
        period: widget.isYearly ? GoalPeriod.yearly : GoalPeriod.monthly,
        year: now.year,
        month: widget.isYearly ? null : now.month,
        targetAmount: inputAmount,
        autoCalculateCounterpart: _autoCalculateOther,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _autoCalculateOther 
                ? '目标设置成功，已同步设置${widget.isYearly ? "月度" : "年度"}目标'
                : '目标设置成功'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 目标设置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }
}