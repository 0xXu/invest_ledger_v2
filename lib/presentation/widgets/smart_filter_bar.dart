import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/services/transaction_stats_service.dart';
import '../providers/transaction_provider.dart';

/// 时间范围选项
enum TimeRange {
  all('全部', LucideIcons.calendar),
  today('今日', LucideIcons.clock),
  thisWeek('本周', LucideIcons.calendarDays),
  thisMonth('本月', LucideIcons.calendar);

  const TimeRange(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 排序选项
enum SortOption {
  dateDesc('时间降序', LucideIcons.arrowDownWideNarrow),
  dateAsc('时间升序', LucideIcons.arrowUpNarrowWide),
  profitDesc('盈亏降序', LucideIcons.trendingDown),
  profitAsc('盈亏升序', LucideIcons.trendingUp);

  const SortOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 筛选状态管理
class FilterState {
  final TimeRange timeRange;
  final ProfitLossFilter profitLossFilter;
  final List<String> selectedStocks;
  final SortOption sortOption;

  const FilterState({
    this.timeRange = TimeRange.all,
    this.profitLossFilter = ProfitLossFilter.all,
    this.selectedStocks = const [],
    this.sortOption = SortOption.dateDesc,
  });

  FilterState copyWith({
    TimeRange? timeRange,
    ProfitLossFilter? profitLossFilter,
    List<String>? selectedStocks,
    SortOption? sortOption,
  }) {
    return FilterState(
      timeRange: timeRange ?? this.timeRange,
      profitLossFilter: profitLossFilter ?? this.profitLossFilter,
      selectedStocks: selectedStocks ?? this.selectedStocks,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasActiveFilters {
    return timeRange != TimeRange.all ||
           profitLossFilter != ProfitLossFilter.all ||
           selectedStocks.isNotEmpty ||
           sortOption != SortOption.dateDesc;
  }
}

/// 筛选状态Provider
final filterStateProvider = StateProvider<FilterState>((ref) => const FilterState());

/// 智能筛选工具栏
class SmartFilterBar extends ConsumerWidget {
  final Function(List<String>)? onStocksChanged;
  final VoidCallback? onSearchPressed;

  const SmartFilterBar({
    super.key,
    this.onStocksChanged,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(filterStateProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 第一行：时间范围和盈亏筛选
          Row(
            children: [
              Expanded(
                child: _TimeRangeSelector(
                  selected: filterState.timeRange,
                  onChanged: (timeRange) {
                    ref.read(filterStateProvider.notifier).update(
                      (state) => state.copyWith(timeRange: timeRange),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              _ProfitLossFilterChips(
                selected: filterState.profitLossFilter,
                onChanged: (filter) {
                  ref.read(filterStateProvider.notifier).update(
                    (state) => state.copyWith(profitLossFilter: filter),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 第二行：股票筛选、排序和搜索
          Row(
            children: [
              Expanded(
                child: _StockFilterSelector(
                  selectedStocks: filterState.selectedStocks,
                  onChanged: (stocks) {
                    ref.read(filterStateProvider.notifier).update(
                      (state) => state.copyWith(selectedStocks: stocks),
                    );
                    onStocksChanged?.call(stocks);
                  },
                ),
              ),
              const SizedBox(width: 8),
              _SortSelector(
                selected: filterState.sortOption,
                onChanged: (sortOption) {
                  ref.read(filterStateProvider.notifier).update(
                    (state) => state.copyWith(sortOption: sortOption),
                  );
                },
              ),
              const SizedBox(width: 8),
              _SearchButton(onPressed: onSearchPressed),
              if (filterState.hasActiveFilters) ...[
                const SizedBox(width: 8),
                _ClearFiltersButton(
                  onPressed: () {
                    ref.read(filterStateProvider.notifier).state = const FilterState();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 时间范围选择器
class _TimeRangeSelector extends StatelessWidget {
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  const _TimeRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TimeRange.values.map((timeRange) {
          final isSelected = timeRange == selected;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) => onChanged(timeRange),
              avatar: Icon(
                timeRange.icon,
                size: 16,
                color: isSelected 
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(
                timeRange.label,
                style: TextStyle(
                  color: isSelected 
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              backgroundColor: isSelected
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.secondaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 盈亏筛选芯片
class _ProfitLossFilterChips extends StatelessWidget {
  final ProfitLossFilter selected;
  final ValueChanged<ProfitLossFilter> onChanged;

  const _ProfitLossFilterChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterChip(
          context,
          label: '盈',
          icon: LucideIcons.trendingUp,
          isSelected: selected == ProfitLossFilter.profitOnly,
          color: Colors.green,
          onTap: () => onChanged(
            selected == ProfitLossFilter.profitOnly 
              ? ProfitLossFilter.all 
              : ProfitLossFilter.profitOnly
          ),
        ),
        const SizedBox(width: 4),
        _buildFilterChip(
          context,
          label: '亏',
          icon: LucideIcons.trendingDown,
          isSelected: selected == ProfitLossFilter.lossOnly,
          color: Colors.red,
          onTap: () => onChanged(
            selected == ProfitLossFilter.lossOnly 
              ? ProfitLossFilter.all 
              : ProfitLossFilter.lossOnly
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? color.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 股票筛选选择器
class _StockFilterSelector extends ConsumerWidget {
  final List<String> selectedStocks;
  final ValueChanged<List<String>> onChanged;

  const _StockFilterSelector({
    required this.selectedStocks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stockNamesAsync = ref.watch(uniqueStockNamesProvider);
    
    return stockNamesAsync.when(
      data: (stockNames) {
        if (stockNames.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return GestureDetector(
          onTap: () => _showStockSelector(context, stockNames),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selectedStocks.isNotEmpty
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selectedStocks.isNotEmpty
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.filter,
                  size: 16,
                  color: selectedStocks.isNotEmpty
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedStocks.isEmpty
                      ? '筛选股票'
                      : selectedStocks.length == 1
                        ? selectedStocks.first
                        : '${selectedStocks.length}只股票',
                    style: TextStyle(
                      color: selectedStocks.isNotEmpty
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                      fontWeight: selectedStocks.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showStockSelector(BuildContext context, List<String> stockNames) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockSelectorBottomSheet(
        stockNames: stockNames,
        selectedStocks: selectedStocks,
        onChanged: onChanged,
      ),
    );
  }
}

/// 排序选择器
class _SortSelector extends StatelessWidget {
  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  const _SortSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopupMenuButton<SortOption>(
      onSelected: onChanged,
      itemBuilder: (context) {
        return SortOption.values.map((option) {
          return PopupMenuItem<SortOption>(
            value: option,
            child: Row(
              children: [
                Icon(option.icon, size: 16),
                const SizedBox(width: 8),
                Text(option.label),
                if (option == selected) ...[
                  const Spacer(),
                  Icon(
                    LucideIcons.check,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          LucideIcons.arrowUpDown,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 搜索按钮
class _SearchButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SearchButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          LucideIcons.search,
          size: 20,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        tooltip: '搜索记录',
      ),
    );
  }
}

/// 清除筛选按钮
class _ClearFiltersButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ClearFiltersButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          LucideIcons.x,
          size: 20,
          color: theme.colorScheme.onErrorContainer,
        ),
        tooltip: '清除筛选',
      ),
    );
  }
}

/// 股票选择器底部弹窗
class _StockSelectorBottomSheet extends StatefulWidget {
  final List<String> stockNames;
  final List<String> selectedStocks;
  final ValueChanged<List<String>> onChanged;

  const _StockSelectorBottomSheet({
    required this.stockNames,
    required this.selectedStocks,
    required this.onChanged,
  });

  @override
  State<_StockSelectorBottomSheet> createState() => _StockSelectorBottomSheetState();
}

class _StockSelectorBottomSheetState extends State<_StockSelectorBottomSheet> {
  late List<String> _selectedStocks;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStocks = List.from(widget.selectedStocks);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredStocks = widget.stockNames
        .where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '筛选股票',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        widget.onChanged(_selectedStocks);
                        Navigator.of(context).pop();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索股票名称',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Stock list
          Expanded(
            child: ListView.builder(
              itemCount: filteredStocks.length,
              itemBuilder: (context, index) {
                final stockName = filteredStocks[index];
                final isSelected = _selectedStocks.contains(stockName);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedStocks.add(stockName);
                      } else {
                        _selectedStocks.remove(stockName);
                      }
                    });
                  },
                  title: Text(stockName),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}