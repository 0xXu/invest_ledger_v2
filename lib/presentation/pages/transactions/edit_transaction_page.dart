import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../utils/loading_utils.dart';

class EditTransactionPage extends ConsumerStatefulWidget {
  final String transactionId;

  const EditTransactionPage({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends ConsumerState<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _stockCodeController = TextEditingController();
  final _stockNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _profitLossController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<String> _tags = [];
  Transaction? _originalTransaction;

  @override
  void dispose() {
    _stockCodeController.dispose();
    _stockNameController.dispose();
    _amountController.dispose();
    _unitPriceController.dispose();
    _profitLossController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm(Transaction transaction) {
    if (_originalTransaction != null) return; // 避免重复初始化

    _originalTransaction = transaction;
    _stockCodeController.text = transaction.stockCode;
    _stockNameController.text = transaction.stockName;
    _amountController.text = transaction.amount.toString();
    _unitPriceController.text = transaction.unitPrice.toString();
    _profitLossController.text = transaction.profitLoss.toString();
    _notesController.text = transaction.notes ?? '';
    _selectedDate = transaction.date;
    _tags = List.from(transaction.tags);
  }

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionProvider(widget.transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑交易'),
        actions: [
          transactionAsync.when(
            data: (transaction) => transaction != null
                ? TextButton(
                    onPressed: () => _saveTransaction(transaction),
                    child: const Text('保存'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) {
          if (transaction == null) {
            return const Center(child: Text('交易记录不存在'));
          }

          _initializeForm(transaction);

          return _buildForm();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(transactionProvider(widget.transactionId));
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 股票信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '股票信息',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _stockCodeController,
                      decoration: const InputDecoration(
                        labelText: '股票代码',
                        hintText: '例如：000001',
                        prefixIcon: Icon(LucideIcons.hash),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入股票代码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _stockNameController,
                      decoration: const InputDecoration(
                        labelText: '股票名称',
                        hintText: '例如：平安银行',
                        prefixIcon: Icon(LucideIcons.building),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入股票名称';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 交易信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '交易信息',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 交易日期
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '交易日期',
                          prefixIcon: Icon(LucideIcons.calendar),
                        ),
                        child: Text(
                          DateFormat('yyyy年MM月dd日').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: '股数',
                              hintText: '100',
                              prefixIcon: Icon(LucideIcons.package),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入股数';
                              }
                              if (Decimal.tryParse(value) == null) {
                                return '请输入有效数字';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _unitPriceController,
                            decoration: const InputDecoration(
                              labelText: '单价 (¥)',
                              hintText: '10.50',
                              prefixIcon: Icon(LucideIcons.dollarSign),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入单价';
                              }
                              if (Decimal.tryParse(value) == null) {
                                return '请输入有效数字';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _profitLossController,
                      decoration: const InputDecoration(
                        labelText: '盈亏 (¥)',
                        hintText: '正数为盈利，负数为亏损',
                        prefixIcon: Icon(LucideIcons.trendingUp),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入盈亏金额';
                        }
                        if (Decimal.tryParse(value) == null) {
                          return '请输入有效数字';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 标签和备注卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '标签和备注',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 标签显示和编辑
                    if (_tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() {
                              _tags.remove(tag);
                            });
                          },
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '添加标签',
                              hintText: '输入标签名称',
                              prefixIcon: Icon(LucideIcons.tag),
                            ),
                            onSubmitted: _addTag,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '添加备注信息...',
                        prefixIcon: Icon(LucideIcons.fileText),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
      });
    }
  }

  Future<void> _saveTransaction(Transaction originalTransaction) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户信息不存在')),
      );
      return;
    }

    try {
      final updatedTransaction = originalTransaction.copyWith(
        stockCode: _stockCodeController.text.trim(),
        stockName: _stockNameController.text.trim(),
        date: _selectedDate,
        amount: Decimal.parse(_amountController.text),
        unitPrice: Decimal.parse(_unitPriceController.text),
        profitLoss: Decimal.parse(_profitLossController.text),
        tags: _tags,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ref.withLoading(() async {
        await ref.read(transactionNotifierProvider.notifier)
            .updateTransaction(updatedTransaction);
      }, '正在保存交易记录...');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('交易记录已更新')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}
