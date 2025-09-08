import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/transaction.dart';
import '../../../core/auth/auth_service.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/import_export_provider.dart';
import '../../widgets/stock_autocomplete_field.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}


class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _stockNameController = TextEditingController();
  final _profitLossController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  // 简单模式盈亏类型
  String _profitLossType = '盈利'; // 盈利/亏损

  @override
  void initState() {
    super.initState();
    // 在下一帧初始化模式，确保context可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeModeFromUrl();
    });
  }

  @override
  void dispose() {
    _stockNameController.dispose();
    _profitLossController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 根据URL参数初始化盈亏类型
  void _initializeModeFromUrl() {
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type']; // profit 或 loss

    // 根据type参数预设盈亏类型
    if (typeParam == 'profit') {
      setState(() {
        _profitLossType = '盈利';
      });
    } else if (typeParam == 'loss') {
      setState(() {
        _profitLossType = '亏损';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
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
            _buildSimpleModeContent(),
            const SizedBox(height: 24),

            // 备注区域
            _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type'];
    if (typeParam == 'profit') {
      return '记录盈利';
    } else if (typeParam == 'loss') {
      return '记录亏损';
    } else {
      return '快速记录';
    }
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

    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户未登录')),
      );
      return;
    }

    try {
      // 创建简单模式交易记录
      final transaction = _createSimpleModeTransaction(authState.user!.id);
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





  /// 构建简单模式内容（大幅简化）
  Widget _buildSimpleModeContent() {
    final theme = Theme.of(context);
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type'];
    final isProfit = typeParam == 'profit';
    
    return Column(
      children: [
        // 简化的信息提示
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isProfit ? Colors.green : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isProfit ? Colors.green : Colors.red).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: isProfit ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '快速记录${isProfit ? '盈利' : '亏损'}，只需输入必要信息',
                  style: TextStyle(
                    color: (isProfit ? Colors.green : Colors.red).shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 股票名称（简化为单个字段）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '股票信息',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StockAutocompleteField(
                  controller: _stockNameController,
                  labelText: '股票名称',
                  hintText: '例如: 平安银行、贵州茅台',
                  prefixIcon: Icons.business,
                  isStockName: true,
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

        // 盈亏金额和日期（简化布局）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: isProfit ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isProfit ? '盈利' : '亏损'}详情',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 金额输入
                TextFormField(
                  controller: _profitLossController,
                  decoration: InputDecoration(
                    labelText: '金额 (¥)',
                    hintText: '请输入${isProfit ? '盈利' : '亏损'}金额',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: isProfit ? Colors.green : Colors.red,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入${isProfit ? '盈利' : '亏损'}金额';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return '请输入有效的正数';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 日期选择
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '交易日期',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy年MM月dd日').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建备注区域
  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, size: 20),
                const SizedBox(width: 8),
                Text(
                  '备注（可选）',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注信息',
                hintText: '记录交易相关信息',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }


  /// 创建简单模式交易记录
  Transaction _createSimpleModeTransaction(String userId) {
    final amount = Decimal.parse(_profitLossController.text.trim());
    // 根据选择的盈亏类型设置正负值
    final profitLoss = _profitLossType == '盈利' ? amount : -amount;

    // 生成股票代码（根据股票名称）
    final stockCode = _generateStockCode(_stockNameController.text.trim());

    return Transaction(
      id: const Uuid().v4(),
      userId: userId,
      date: _selectedDate,
      stockCode: stockCode,
      stockName: _stockNameController.text.trim(),
      amount: Decimal.one, // 默认数量为1
      unitPrice: amount, // 单价设为输入的金额
      profitLoss: profitLoss,
      tags: const [],
      notes: _notesController.text.trim().isEmpty
          ? '从简单模式添加（$_profitLossType）'
          : '${_notesController.text.trim()}（简单模式-$_profitLossType）',
      createdAt: DateTime.now(),
    );
  }


  /// 生成股票代码（简单模式使用）
  String _generateStockCode(String stockName) {
    if (stockName.isEmpty) return 'UNKNOWN';

    // 简单的代码生成逻辑：取股票名称的前几个字符
    final cleanName = stockName.replaceAll(RegExp(r'[^\u4e00-\u9fa5a-zA-Z0-9]'), '');
    if (cleanName.length >= 3) {
      return cleanName.substring(0, 3).toUpperCase();
    } else {
      return cleanName.toUpperCase().padRight(3, 'X');
    }
  }
}
