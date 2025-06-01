import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/shared_investment.dart';

class CancelInvestmentDialog extends StatefulWidget {
  final SharedInvestment sharedInvestment;
  final Function(String? reason) onCancel;

  const CancelInvestmentDialog({
    super.key,
    required this.sharedInvestment,
    required this.onCancel,
  });

  @override
  State<CancelInvestmentDialog> createState() => _CancelInvestmentDialogState();
}

class _CancelInvestmentDialogState extends State<CancelInvestmentDialog> {
  final _reasonController = TextEditingController();
  String? _selectedReason;

  final List<String> _predefinedReasons = [
    '市场条件变化',
    '参与者退出',
    '资金需求变化',
    '投资策略调整',
    '风险控制',
    '其他原因',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.xCircle,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('取消投资')),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 投资信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sharedInvestment.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.sharedInvestment.stockName} (${widget.sharedInvestment.stockCode})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.sharedInvestment.participants.length} 位参与者',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.dollarSign,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '¥${widget.sharedInvestment.totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 警告信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注意',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '取消投资后，该投资将被标记为已取消状态，无法恢复。请确认是否继续。',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 取消原因选择
              Text(
                '取消原因',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // 预定义原因选项
              ..._predefinedReasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                      if (value != '其他原因') {
                        _reasonController.text = value!;
                      } else {
                        _reasonController.clear();
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),

              // 自定义原因输入
              if (_selectedReason == '其他原因') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: '请输入具体原因',
                    hintText: '详细说明取消投资的原因...',
                    prefixIcon: Icon(LucideIcons.messageSquare),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
              ],

              const SizedBox(height: 20),

              // 参与者列表
              Text(
                '受影响的参与者',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.sharedInvestment.participants.length,
                  itemBuilder: (context, index) {
                    final participant = widget.sharedInvestment.participants[index];
                    return ListTile(
                      leading: CircleAvatar(
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
                      title: Text(
                        participant.userName,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        '投资金额: ¥${participant.investmentAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
        ElevatedButton(
          onPressed: _handleCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('确认取消'),
        ),
      ],
    );
  }

  void _handleCancel() {
    String? reason;

    if (_selectedReason != null) {
      if (_selectedReason == '其他原因') {
        reason = _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : '其他原因';
      } else {
        reason = _selectedReason;
      }
    }

    widget.onCancel(reason);
    Navigator.of(context).pop();
  }
}
