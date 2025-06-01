import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/transaction.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _stockCodeController = TextEditingController();
  final _stockNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _profitLossController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final List<String> _tags = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加交易'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveTransaction,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 股票信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '股票信息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockCodeController,
                      decoration: const InputDecoration(
                        labelText: '股票代码',
                        hintText: '例如: 000001',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
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
                        hintText: '例如: 平安银行',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
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

            // 交易信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '交易信息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('交易日期'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: '股数',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入股数';
                              }
                              if (double.tryParse(value) == null) {
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
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入单价';
                              }
                              if (double.tryParse(value) == null) {
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
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入盈亏金额';
                        }
                        if (double.tryParse(value) == null) {
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

            // 备注
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '备注',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: '备注信息',
                        hintText: '可选，记录交易相关信息',
                        border: OutlineInputBorder(),
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

  void _handleBackNavigation(BuildContext context) {
    // 检查URL参数中是否有来源信息
    final uri = GoRouterState.of(context).uri;
    final fromDashboard = uri.queryParameters['from'] == 'dashboard';

    if (fromDashboard) {
      // 如果是从仪表盘来的，直接返回仪表盘
      context.go('/dashboard');
    } else if (context.canPop()) {
      // 否则使用标准的返回逻辑
      context.pop();
    } else {
      // 默认返回交易页面（因为这是交易的子路由）
      context.go('/transactions');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户未登录')),
      );
      return;
    }

    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        userId: user.id,
        date: _selectedDate,
        stockCode: _stockCodeController.text.trim(),
        stockName: _stockNameController.text.trim(),
        amount: Decimal.parse(_amountController.text.trim()),
        unitPrice: Decimal.parse(_unitPriceController.text.trim()),
        profitLoss: Decimal.parse(_profitLossController.text.trim()),
        tags: _tags,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(transactionNotifierProvider.notifier).addTransaction(transaction);

      if (mounted) {
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('交易添加成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 询问用户是否跳转到交易记录页面
        final shouldNavigateToTransactions = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('添加成功'),
            content: const Text('交易记录已成功添加。是否查看交易记录？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('返回仪表盘'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('查看交易记录'),
              ),
            ],
          ),
        );

        if (mounted) {
          // 检查来源页面
          final uri = GoRouterState.of(context).uri;
          final fromDashboard = uri.queryParameters['from'] == 'dashboard';

          if (shouldNavigateToTransactions == true) {
            // 跳转到交易记录页面
            context.go('/transactions');
          } else {
            // 根据来源返回相应页面
            if (fromDashboard) {
              context.go('/dashboard');
            } else {
              context.go('/transactions');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }
}
