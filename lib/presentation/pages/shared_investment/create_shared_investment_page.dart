import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/shared_investment.dart';
import '../../providers/shared_investment_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/device_users_manager.dart';
import '../../widgets/device_user_selector_dialog.dart';
import '../../utils/loading_utils.dart';

class CreateSharedInvestmentPage extends ConsumerStatefulWidget {
  const CreateSharedInvestmentPage({super.key});

  @override
  ConsumerState<CreateSharedInvestmentPage> createState() => _CreateSharedInvestmentPageState();
}

class _CreateSharedInvestmentPageState extends ConsumerState<CreateSharedInvestmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockCodeController = TextEditingController();
  final _stockNameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _totalSharesController = TextEditingController();
  final _notesController = TextEditingController();

  final List<ParticipantData> _participants = [];

  // 计算相关的状态
  double get _totalInvestment => _participants.fold(0.0, (sum, p) =>
    sum + p.investmentAmount);

  double get _totalShares => _participants.fold(0.0, (sum, p) =>
    sum + (double.tryParse(p.shares) ?? 0.0));

  double get _averageBuyPrice => _totalShares > 0 ? _totalInvestment / _totalShares : 0.0;

  double get _sellPrice => double.tryParse(_sellPriceController.text) ?? 0.0;

  double get _totalProfitLoss => _totalShares * (_sellPrice - _averageBuyPrice);

  @override
  void initState() {
    super.initState();
    // 添加当前用户作为第一个参与者
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authServiceProvider);
      if (authState.user != null) {
        setState(() {
          _participants.add(ParticipantData(
            userName: authState.user!.email ?? 'Current User',
            userId: authState.user!.id,
            buyPrice: '',
            shares: '',
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockCodeController.dispose();
    _stockNameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _totalSharesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建共享投资'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 股票基本信息
              _buildStockInfoSection(),
              const SizedBox(height: 16),

              // 交易信息
              _buildTradeInfoSection(),
              const SizedBox(height: 16),

              // 参与者投资金额
              _buildParticipantsSection(),
              const SizedBox(height: 16),

              // 盈亏分配预览
              _buildProfitLossPreview(),
              const SizedBox(height: 16),

              // 备注
              _buildNotesSection(),
              const SizedBox(height: 32),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(LucideIcons.calculator),
                  label: const Text('创建并分配盈亏'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '股票信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 投资名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '投资名称',
                prefixIcon: Icon(LucideIcons.tag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入投资名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 股票代码和名称
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _stockCodeController,
                    decoration: const InputDecoration(
                      labelText: '股票代码',
                      prefixIcon: Icon(LucideIcons.hash),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入股票代码';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _stockNameController,
                    decoration: const InputDecoration(
                      labelText: '股票名称',
                      prefixIcon: Icon(LucideIcons.building),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入股票名称';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.barChart3,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '交易汇总',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 显示汇总信息
            if (_participants.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      '总投资',
                      '¥${_totalInvestment.toStringAsFixed(2)}',
                      LucideIcons.wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      '总股数',
                      '${_totalShares.toStringAsFixed(0)}股',
                      LucideIcons.package,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      '平均成本',
                      '¥${_averageBuyPrice.toStringAsFixed(2)}',
                      LucideIcons.calculator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.arrowUp,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '卖出价格',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _sellPriceController,
                            decoration: const InputDecoration(
                              prefixText: '¥',
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入卖出价格';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return '请输入有效价格';
                              }
                              return null;
                            },
                            onChanged: (value) => setState(() {}), // 触发重新计算
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // 显示总盈亏
            if (_totalShares > 0 && _averageBuyPrice > 0 && _sellPrice > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _totalProfitLoss >= 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _totalProfitLoss >= 0 ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _totalProfitLoss >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      color: _totalProfitLoss >= 0 ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '总盈亏：',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${_totalProfitLoss >= 0 ? '+' : ''}¥${_totalProfitLoss.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _totalProfitLoss >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossPreview() {
    if (_participants.isEmpty || _totalProfitLoss == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.calculator,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '盈亏分配预览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 分配列表
            ..._participants.where((p) => p.investmentAmount > 0).map((participant) {
              final investment = participant.investmentAmount;
              final ratio = _totalInvestment > 0 ? investment / _totalInvestment : 0.0;
              final profitLoss = _totalProfitLoss * ratio;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        participant.userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '¥${investment.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${(ratio * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${profitLoss >= 0 ? '+' : ''}¥${profitLoss.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: profitLoss >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // 表头
            if (_participants.any((p) => p.investmentAmount > 0)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '参与者',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '投资额',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '占比',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '分配盈亏',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.users,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '参与者投资 (${_participants.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addParticipant,
                  icon: const Icon(LucideIcons.userPlus),
                  tooltip: '添加参与者',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 参与者列表
            ..._participants.asMap().entries.map((entry) {
              final index = entry.key;
              final participant = entry.value;
              return _buildParticipantItem(index, participant);
            }),

            if (_participants.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '暂无参与者\n点击右上角按钮添加参与者',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            // 总投资显示
            if (_participants.isNotEmpty && _totalInvestment > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.wallet,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '总投资金额：',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '¥${_totalInvestment.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantItem(int index, ParticipantData participant) {
    final authState = ref.read(authServiceProvider);
    final isCurrentUser = authState.user?.id == participant.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isCurrentUser ? LucideIcons.userCheck : LucideIcons.user,
                  size: 16,
                  color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    participant.userName + (isCurrentUser ? ' (我)' : ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (!isCurrentUser)
                  IconButton(
                    onPressed: () => _removeParticipant(index),
                    icon: const Icon(LucideIcons.trash2),
                    iconSize: 16,
                    tooltip: '移除参与者',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: participant.buyPrice,
                    decoration: const InputDecoration(
                      labelText: '买入价格',
                      prefixText: '¥',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      participant.buyPrice = value;
                      setState(() {}); // 触发重新计算
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入买入价格';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return '请输入有效价格';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: participant.shares,
                    decoration: const InputDecoration(
                      labelText: '股数',
                      suffixText: '股',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      participant.shares = value;
                      setState(() {}); // 触发重新计算
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入股数';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return '请输入有效股数';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 显示计算出的投资金额
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calculator,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '投资金额：¥${participant.investmentAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '备注信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '记录投资相关的备注信息...',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _addParticipant() {
    // 获取已选择的用户ID列表
    final excludeUserIds = _participants.map((p) => p.userId).toList();

    showDialog(
      context: context,
      builder: (context) => DeviceUserSelectorDialog(
        excludeUserIds: excludeUserIds,
        onUsersSelected: (selectedUsers) {
          setState(() {
            for (final user in selectedUsers) {
              _participants.add(ParticipantData(
                userName: user.displayName ?? user.email,
                userId: user.id,
                buyPrice: '',
                shares: '',
              ));
            }
          });
        },
      ),
    );
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个参与者')),
      );
      return;
    }

    try {
      // 计算每个参与者的盈亏
      final participants = _participants.where((p) => p.investmentAmount > 0).map((p) {
        final investment = p.investmentAmount;
        final ratio = _totalInvestment > 0 ? investment / _totalInvestment : 0.0;
        final profitLoss = _totalProfitLoss * ratio;
        final shares = double.tryParse(p.shares) ?? 0.0;

        return SharedInvestmentParticipant(
          id: const Uuid().v4(),
          sharedInvestmentId: '', // 将在创建时设置
          userId: p.userId,
          userName: p.userName,
          investmentAmount: Decimal.parse(investment.toStringAsFixed(2)),
          shares: Decimal.parse(shares.toStringAsFixed(2)),
          profitLoss: Decimal.parse(profitLoss.toStringAsFixed(2)),
        );
      }).toList();

      await ref.withLoading(() async {
        await ref.read(sharedInvestmentNotifierProvider.notifier).createSharedInvestment(
          name: _nameController.text.trim(),
          stockCode: _stockCodeController.text.trim(),
          stockName: _stockNameController.text.trim(),
          participants: participants,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }, '正在创建共享投资并分配盈亏...');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('共享投资创建成功！已为${participants.length}位参与者分配盈亏'),
            duration: const Duration(seconds: 3),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }
}

class ParticipantData {
  final String userName;
  final String userId;
  String buyPrice;      // 买入价格
  String shares;        // 股数

  // 计算投资金额
  double get investmentAmount {
    final price = double.tryParse(buyPrice) ?? 0.0;
    final shareCount = double.tryParse(shares) ?? 0.0;
    return price * shareCount;
  }

  ParticipantData({
    required this.userName,
    required this.userId,
    this.buyPrice = '',
    this.shares = '',
  });
}


