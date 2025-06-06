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

// 添加模式枚举
enum AddTransactionMode {
  simple, // 简单模式（盈亏记录）
  detailed, // 详细模式（交易记录）
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

  // 添加模式状态
  AddTransactionMode _mode = AddTransactionMode.simple; // 默认简单模式

  // 交易类型相关状态（详细模式使用）
  String _transactionType = '买入'; // 买入/卖出
  bool _autoCalculateProfit = false; // 是否自动计算盈亏
  bool _isCalculatingProfit = false; // 是否正在计算盈亏

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
    _stockCodeController.dispose();
    _stockNameController.dispose();
    _amountController.dispose();
    _unitPriceController.dispose();
    _profitLossController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 根据URL参数初始化模式
  void _initializeModeFromUrl() {
    final uri = GoRouterState.of(context).uri;
    final modeParam = uri.queryParameters['mode'];

    if (modeParam == 'simple') {
      setState(() {
        _mode = AddTransactionMode.simple;
      });
    } else if (modeParam == 'detailed') {
      setState(() {
        _mode = AddTransactionMode.detailed;
      });
    }
    // 如果没有参数或参数无效，保持默认的简单模式
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == AddTransactionMode.simple ? '快速记录盈亏' : '添加交易记录'),
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
            // 模式切换器
            _buildModeSelector(),
            const SizedBox(height: 16),

            // 根据模式显示不同的内容
            if (_mode == AddTransactionMode.simple) ...[
              _buildSimpleModeContent(),
            ] else ...[
              _buildDetailedModeContent(),
            ],
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

    final authState = ref.read(authServiceProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户未登录')),
      );
      return;
    }

    try {
      Transaction transaction;

      if (_mode == AddTransactionMode.simple) {
        // 简单模式：只记录盈亏
        transaction = _createSimpleModeTransaction(authState.user!.id);
      } else {
        // 详细模式：记录买入卖出
        transaction = await _createDetailedModeTransaction(authState.user!.id);
      }

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

  /// 构建盈亏输入区域
  Widget _buildProfitLossSection() {
    if (_transactionType == '买入') {
      // 买入交易：盈亏固定为0
      return TextFormField(
        key: const ValueKey('buy_profit_loss'),
        decoration: const InputDecoration(
          labelText: '盈亏 (¥)',
          hintText: '买入交易盈亏为0',
          border: OutlineInputBorder(),
        ),
        enabled: false,
        initialValue: '0',
      );
    } else {
      // 卖出交易：可以手动输入或自动计算
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _profitLossController,
                  decoration: InputDecoration(
                    labelText: '盈亏 (¥)',
                    hintText: _autoCalculateProfit ? '系统将自动计算' : '正数为盈利，负数为亏损',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isCalculatingProfit
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_autoCalculateProfit && !_isCalculatingProfit,
                  validator: (value) {
                    if (_autoCalculateProfit) return null;
                    if (value == null || value.trim().isEmpty) {
                      return '请输入盈亏金额或选择自动计算';
                    }
                    if (double.tryParse(value) == null) {
                      return '请输入有效数字';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isCalculatingProfit ? null : _toggleAutoCalculate,
                icon: Icon(_autoCalculateProfit ? Icons.edit : Icons.calculate),
                label: Text(_autoCalculateProfit ? '手动输入' : '自动计算'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _autoCalculateProfit ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_autoCalculateProfit) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '系统将根据FIFO原则自动计算此次卖出的盈亏',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
  }

  /// 切换自动计算盈亏
  void _toggleAutoCalculate() {
    setState(() {
      _autoCalculateProfit = !_autoCalculateProfit;
      if (_autoCalculateProfit) {
        _profitLossController.text = '自动计算';
      } else {
        _profitLossController.clear();
      }
    });
  }

  /// 构建模式切换器
  Widget _buildModeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  '记录模式',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _mode == AddTransactionMode.simple
                            ? Colors.blue
                            : Colors.grey.withValues(alpha: 0.3),
                        width: _mode == AddTransactionMode.simple ? 2 : 1,
                      ),
                      color: _mode == AddTransactionMode.simple
                          ? Colors.blue.withValues(alpha: 0.1)
                          : null,
                    ),
                    child: RadioListTile<AddTransactionMode>(
                      title: const Text('简单模式'),
                      subtitle: const Text('快速记录盈亏\n适合日常使用'),
                      value: AddTransactionMode.simple,
                      groupValue: _mode,
                      onChanged: (value) {
                        setState(() {
                          _mode = value!;
                          _clearFormData();
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _mode == AddTransactionMode.detailed
                            ? Colors.blue
                            : Colors.grey.withValues(alpha: 0.3),
                        width: _mode == AddTransactionMode.detailed ? 2 : 1,
                      ),
                      color: _mode == AddTransactionMode.detailed
                          ? Colors.blue.withValues(alpha: 0.1)
                          : null,
                    ),
                    child: RadioListTile<AddTransactionMode>(
                      title: const Text('详细模式'),
                      subtitle: const Text('完整交易记录\n包含买入卖出'),
                      value: AddTransactionMode.detailed,
                      groupValue: _mode,
                      onChanged: (value) {
                        setState(() {
                          _mode = value!;
                          _clearFormData();
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 清空表单数据（切换模式时保留公共字段）
  void _clearFormData() {
    // 保留股票名称、日期、备注
    final stockName = _stockNameController.text;
    final notes = _notesController.text;

    // 清空其他字段
    _stockCodeController.clear();
    _amountController.clear();
    _unitPriceController.clear();
    _profitLossController.clear();

    // 恢复保留的字段
    _stockNameController.text = stockName;
    _notesController.text = notes;

    // 重置状态
    _transactionType = '买入';
    _autoCalculateProfit = false;
    _isCalculatingProfit = false;
    _profitLossType = '盈利'; // 重置盈亏类型
  }

  /// 构建简单模式内容
  Widget _buildSimpleModeContent() {
    return Column(
      children: [
        // 简单模式说明
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '简单模式：快速记录股票盈亏，无需输入详细交易信息',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 股票信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '股票信息',
                      style: Theme.of(context).textTheme.titleMedium,
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
                  pairedController: _stockCodeController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入股票名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                StockAutocompleteField(
                  controller: _stockCodeController,
                  labelText: '股票代码（可选）',
                  hintText: '例如: 000001，留空将自动生成',
                  prefixIcon: Icons.tag,
                  isStockName: false,
                  pairedController: _stockNameController,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 盈亏信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '盈亏记录',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ListTile(
                  title: const Text('交易日期'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: Colors.blue),
                ),
                const SizedBox(height: 16),

                // 盈亏类型选择
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _profitLossType == '盈利'
                                ? Colors.green
                                : Colors.grey.withValues(alpha: 0.3),
                            width: _profitLossType == '盈利' ? 2 : 1,
                          ),
                          color: _profitLossType == '盈利'
                              ? Colors.green.withValues(alpha: 0.1)
                              : null,
                        ),
                        child: RadioListTile<String>(
                          title: const Text('盈利'),
                          value: '盈利',
                          groupValue: _profitLossType,
                          onChanged: (value) {
                            setState(() {
                              _profitLossType = value!;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _profitLossType == '亏损'
                                ? Colors.red
                                : Colors.grey.withValues(alpha: 0.3),
                            width: _profitLossType == '亏损' ? 2 : 1,
                          ),
                          color: _profitLossType == '亏损'
                              ? Colors.red.withValues(alpha: 0.1)
                              : null,
                        ),
                        child: RadioListTile<String>(
                          title: const Text('亏损'),
                          value: '亏损',
                          groupValue: _profitLossType,
                          onChanged: (value) {
                            setState(() {
                              _profitLossType = value!;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _profitLossController,
                  decoration: InputDecoration(
                    labelText: '金额 (¥)',
                    hintText: '请输入$_profitLossType金额',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      _profitLossType == '盈利' ? Icons.trending_up : Icons.trending_down,
                      color: _profitLossType == '盈利' ? Colors.green : Colors.red,
                    ),
                    helperText: '例如：1000 表示$_profitLossType 1000元',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入$_profitLossType金额';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return '请输入有效的正数';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建详细模式内容
  Widget _buildDetailedModeContent() {
    return Column(
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
                StockAutocompleteField(
                  controller: _stockCodeController,
                  labelText: '股票代码',
                  hintText: '例如: 000001',
                  prefixIcon: Icons.tag,
                  isStockName: false,
                  pairedController: _stockNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入股票代码';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                StockAutocompleteField(
                  controller: _stockNameController,
                  labelText: '股票名称',
                  hintText: '例如: 平安银行',
                  prefixIcon: Icons.business,
                  isStockName: true,
                  pairedController: _stockCodeController,
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

                // 交易类型选择
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('买入'),
                        value: '买入',
                        groupValue: _transactionType,
                        onChanged: (value) {
                          setState(() {
                            _transactionType = value!;
                            _autoCalculateProfit = false;
                            _profitLossController.text = '0';
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('卖出'),
                        value: '卖出',
                        groupValue: _transactionType,
                        onChanged: (value) {
                          setState(() {
                            _transactionType = value!;
                            _autoCalculateProfit = false;
                            _profitLossController.clear();
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ListTile(
                  title: const Text('交易日期'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: '股数',
                          hintText: _transactionType == '买入' ? '买入股数' : '卖出股数',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入股数';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return '请输入有效的正数';
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
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return '请输入有效的正数';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 盈亏输入区域
                _buildProfitLossSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 创建简单模式交易记录
  Transaction _createSimpleModeTransaction(String userId) {
    final amount = Decimal.parse(_profitLossController.text.trim());
    // 根据选择的盈亏类型设置正负值
    final profitLoss = _profitLossType == '盈利' ? amount : -amount;

    // 生成股票代码（如果用户没有输入）
    String stockCode = _stockCodeController.text.trim();
    if (stockCode.isEmpty) {
      stockCode = _generateStockCode(_stockNameController.text.trim());
    }

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

  /// 创建详细模式交易记录
  Future<Transaction> _createDetailedModeTransaction(String userId) async {
    // 根据交易类型调整数量的正负
    final rawAmount = Decimal.parse(_amountController.text.trim());
    final amount = _transactionType == '卖出' ? -rawAmount : rawAmount;

    // 处理盈亏
    Decimal profitLoss;
    if (_transactionType == '买入') {
      profitLoss = Decimal.zero;
    } else if (_autoCalculateProfit) {
      // 卖出且自动计算盈亏
      setState(() {
        _isCalculatingProfit = true;
      });

      // 创建临时交易记录用于计算盈亏
      final tempTransaction = Transaction(
        id: null,
        userId: userId,
        date: _selectedDate,
        stockCode: _stockCodeController.text.trim(),
        stockName: _stockNameController.text.trim(),
        amount: amount,
        unitPrice: Decimal.parse(_unitPriceController.text.trim()),
        profitLoss: Decimal.zero,
        createdAt: DateTime.now(),
      );

      // 使用导入服务的计算方法
      final importService = ref.read(importExportServiceProvider);
      final calculatedTransaction = await importService.calculateProfitLoss(tempTransaction, userId);
      profitLoss = calculatedTransaction.profitLoss;

      setState(() {
        _isCalculatingProfit = false;
        _profitLossController.text = profitLoss.toString();
      });
    } else {
      // 手动输入的盈亏
      profitLoss = Decimal.parse(_profitLossController.text.trim());
    }

    return Transaction(
      id: const Uuid().v4(),
      userId: userId,
      date: _selectedDate,
      stockCode: _stockCodeController.text.trim(),
      stockName: _stockNameController.text.trim(),
      amount: amount,
      unitPrice: Decimal.parse(_unitPriceController.text.trim()),
      profitLoss: profitLoss,
      tags: const [],
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
