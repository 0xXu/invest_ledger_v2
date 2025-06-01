import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:decimal/decimal.dart';

import '../../../data/models/shared_investment.dart';
import '../../providers/shared_investment_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/animated_card.dart';

class EditSharedInvestmentPage extends ConsumerStatefulWidget {
  final String sharedInvestmentId;

  const EditSharedInvestmentPage({
    super.key,
    required this.sharedInvestmentId,
  });

  @override
  ConsumerState<EditSharedInvestmentPage> createState() => _EditSharedInvestmentPageState();
}

class _EditSharedInvestmentPageState extends ConsumerState<EditSharedInvestmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockCodeController = TextEditingController();
  final _stockNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _sellAmountController = TextEditingController();

  SharedInvestment? _originalInvestment;
  List<SharedInvestmentParticipant> _participants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSharedInvestment();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockCodeController.dispose();
    _stockNameController.dispose();
    _notesController.dispose();
    _sellAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedInvestment() async {
    setState(() => _isLoading = true);

    try {
      final sharedInvestments = await ref.read(sharedInvestmentNotifierProvider.future);
      _originalInvestment = sharedInvestments
          .where((si) => si.id == widget.sharedInvestmentId)
          .firstOrNull;

      if (_originalInvestment != null) {
        _nameController.text = _originalInvestment!.name;
        _stockCodeController.text = _originalInvestment!.stockCode;
        _stockNameController.text = _originalInvestment!.stockName;
        _notesController.text = _originalInvestment!.notes ?? '';
        _sellAmountController.text = _originalInvestment!.sellAmount?.toString() ?? '';
        _participants = List.from(_originalInvestment!.participants);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_originalInvestment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑共享投资')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('共享投资不存在'),
                  ],
                ),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑共享投资'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('保存'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnimatedCardList(
              staggerDelay: const Duration(milliseconds: 100),
              animationType: CardAnimationType.fadeSlideIn,
              slideDirection: SlideDirection.fromTop,
              enableScrollAnimation: true,
              children: [
                _buildBasicInfoCard(),
                const SizedBox(height: 16),
                _buildParticipantsCard(),
                const SizedBox(height: 16),
                _buildNotesCard(),
                const SizedBox(height: 16),
                _buildSellAmountCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.edit,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '基本信息',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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

            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
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

  Widget _buildParticipantsCard() {
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.users,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '参与者 (${_participants.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._participants.asMap().entries.map((entry) {
              final index = entry.key;
              final participant = entry.value;
              return _buildParticipantItem(participant, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantItem(SharedInvestmentParticipant participant, int index) {
    final theme = Theme.of(context);
    final profitLossController = TextEditingController(
      text: participant.profitLoss.toString(),
    );

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
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  participant.userName.isNotEmpty
                      ? participant.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '投资: ¥${participant.investmentAmount.toStringAsFixed(2)} | '
                      '股数: ${participant.shares.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: profitLossController,
            decoration: const InputDecoration(
              labelText: '盈亏金额',
              prefixIcon: Icon(LucideIcons.trendingUp),
              prefixText: '¥',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final profitLoss = Decimal.tryParse(value) ?? Decimal.zero;
              _participants[index] = participant.copyWith(profitLoss: profitLoss);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.fileText,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '备注',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注信息',
                hintText: '输入相关备注信息...',
                prefixIcon: Icon(LucideIcons.messageSquare),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellAmountCard() {
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.dollarSign,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '卖出金额',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _sellAmountController,
              decoration: const InputDecoration(
                labelText: '卖出总金额',
                prefixIcon: Icon(LucideIcons.dollarSign),
                prefixText: '¥',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sellAmount = _sellAmountController.text.trim().isNotEmpty
          ? Decimal.tryParse(_sellAmountController.text.trim())
          : null;

      // 重新计算总投资和总股数
      final totalAmount = _participants.fold(
        Decimal.zero,
        (sum, p) => sum + p.investmentAmount,
      );
      final totalShares = _participants.fold(
        Decimal.zero,
        (sum, p) => sum + p.shares,
      );

      final updatedInvestment = _originalInvestment!.copyWith(
        name: _nameController.text.trim(),
        stockCode: _stockCodeController.text.trim(),
        stockName: _stockNameController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        sellAmount: sellAmount,
        totalAmount: totalAmount,
        totalShares: totalShares,
        participants: _participants,
      );

      await ref.read(sharedInvestmentNotifierProvider.notifier)
          .updateSharedInvestment(updatedInvestment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.checkCircle, color: Colors.white),
                SizedBox(width: 8),
                Text('共享投资已更新'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('保存失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
