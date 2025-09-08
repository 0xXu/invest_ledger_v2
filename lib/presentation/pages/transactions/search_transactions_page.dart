import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/stock_investment_card.dart';

class SearchTransactionsPage extends ConsumerStatefulWidget {
  const SearchTransactionsPage({super.key});

  @override
  ConsumerState<SearchTransactionsPage> createState() => _SearchTransactionsPageState();
}

class _SearchTransactionsPageState extends ConsumerState<SearchTransactionsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showProfitOnly = false;
  bool _showLossOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索交易'),
        actions: [
          IconButton(
            onPressed: _clearFilters,
            icon: const Icon(LucideIcons.x),
            tooltip: '清除筛选',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // 搜索框
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: '搜索股票名称...',
                    prefixIcon: Icon(LucideIcons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // 筛选选项
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 日期范围筛选
                      _FilterChip(
                        label: _getDateRangeLabel(),
                        icon: LucideIcons.calendar,
                        onTap: _selectDateRange,
                        isSelected: _startDate != null || _endDate != null,
                      ),
                      const SizedBox(width: 8),
                      
                      // 盈利筛选
                      _FilterChip(
                        label: '仅盈利',
                        icon: LucideIcons.trendingUp,
                        onTap: () {
                          setState(() {
                            _showProfitOnly = !_showProfitOnly;
                            if (_showProfitOnly) _showLossOnly = false;
                          });
                        },
                        isSelected: _showProfitOnly,
                      ),
                      const SizedBox(width: 8),
                      
                      // 亏损筛选
                      _FilterChip(
                        label: '仅亏损',
                        icon: LucideIcons.trendingDown,
                        onTap: () {
                          setState(() {
                            _showLossOnly = !_showLossOnly;
                            if (_showLossOnly) _showProfitOnly = false;
                          });
                        },
                        isSelected: _showLossOnly,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 搜索结果
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filteredTransactions = _filterTransactions(transactions);
                
                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.searchX,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '没有找到匹配的交易记录',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '尝试调整搜索条件或筛选器',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StockInvestmentCard(
                        transaction: transaction,
                        onTap: () {
                          context.push('/transactions/${transaction.id}');
                        },
                        onEdit: () {
                          context.push('/transactions/edit/${transaction.id}');
                        },
                      ),
                    );
                  },
                );
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
                        ref.invalidate(transactionNotifierProvider);
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((transaction) {
      // 搜索查询筛选
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = transaction.stockCode.toLowerCase().contains(_searchQuery) ||
            transaction.stockName.toLowerCase().contains(_searchQuery);
        if (!matchesSearch) return false;
      }
      
      // 日期范围筛选
      if (_startDate != null && transaction.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && transaction.date.isAfter(_endDate!)) {
        return false;
      }
      
      // 盈亏筛选
      if (_showProfitOnly && transaction.profitLoss.toDouble() <= 0) {
        return false;
      }
      if (_showLossOnly && transaction.profitLoss.toDouble() >= 0) {
        return false;
      }
      
      return true;
    }).toList();
  }

  String _getDateRangeLabel() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}';
    } else if (_startDate != null) {
      return '从 ${DateFormat('MM/dd').format(_startDate!)}';
    } else if (_endDate != null) {
      return '到 ${DateFormat('MM/dd').format(_endDate!)}';
    }
    return '日期范围';
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      _showProfitOnly = false;
      _showLossOnly = false;
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected 
            ? theme.colorScheme.onPrimaryContainer 
            : theme.colorScheme.onSurface,
      ),
    );
  }
}
