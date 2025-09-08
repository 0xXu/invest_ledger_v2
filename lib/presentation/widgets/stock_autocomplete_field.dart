import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stock_history_service.dart';

class StockAutocompleteField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final bool isStockName; // true为股票名称，false为股票代码
  final TextEditingController? pairedController; // 配对的控制器
  final String? Function(String?)? validator;

  const StockAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.isStockName,
    this.prefixIcon,
    this.pairedController,
    this.validator,
  });

  @override
  ConsumerState<StockAutocompleteField> createState() => _StockAutocompleteFieldState();
}

class _StockAutocompleteFieldState extends ConsumerState<StockAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<StockHistoryItem> _suggestions = [];
  bool _isShowingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _hideSuggestions();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // 延迟隐藏建议，给用户点击的时间
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _hideSuggestions();
        }
      });
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      _hideSuggestions();
      return;
    }

    _searchSuggestions(query);
  }

  Future<void> _searchSuggestions(String query) async {
    final service = ref.read(stockHistoryServiceProvider);
    
    List<StockHistoryItem> results;
    if (widget.isStockName) {
      results = await service.searchByName(query);
    } else {
      results = await service.searchByCode(query);
    }

    if (mounted && _focusNode.hasFocus) {
      setState(() {
        _suggestions = results.take(5).toList(); // 最多显示5个建议
      });
      
      if (_suggestions.isNotEmpty) {
        _showSuggestions();
      } else {
        _hideSuggestions();
      }
    }
  }

  void _showSuggestions() {
    if (_isShowingSuggestions) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isShowingSuggestions = true;
  }

  void _hideSuggestions() {
    if (!_isShowingSuggestions) return;

    if (mounted) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowingSuggestions = false;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return InkWell(
                      onTap: () {
                        _selectSuggestion(suggestion);
                      },
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.history,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          widget.isStockName ? suggestion.stockName : suggestion.stockCode,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          widget.isStockName ? suggestion.stockCode : suggestion.stockName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectSuggestion(StockHistoryItem suggestion) {
    // 立即隐藏建议
    _hideSuggestions();
    
    // 填充当前输入框
    widget.controller.text = widget.isStockName ? suggestion.stockName : suggestion.stockCode;
    
    // 自动填充配对的输入框
    if (widget.pairedController != null) {
      widget.pairedController!.text = widget.isStockName ? suggestion.stockCode : suggestion.stockName;
    }
    
    // 延迟失焦，确保文本输入完成
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    widget.controller.clear();
                    _hideSuggestions();
                  },
                )
              : null,
        ),
        validator: widget.validator,
        onChanged: (value) {
          // 当用户手动输入时，如果配对控制器有内容且不匹配，则清空配对控制器
          if (widget.pairedController != null && widget.pairedController!.text.isNotEmpty) {
            _checkAndClearPairedField(value);
          }
        },
      ),
    );
  }

  /// 检查并清空不匹配的配对字段
  Future<void> _checkAndClearPairedField(String currentValue) async {
    if (currentValue.trim().isEmpty) {
      widget.pairedController?.clear();
      return;
    }

    final service = ref.read(stockHistoryServiceProvider);
    
    if (widget.isStockName) {
      // 当前是股票名称，检查配对的股票代码是否匹配
      final expectedCode = await service.findCodeByName(currentValue);
      if (expectedCode != null && widget.pairedController!.text != expectedCode) {
        // 如果找到匹配的代码但当前代码不匹配，清空代码字段
        if (widget.pairedController!.text.isNotEmpty) {
          widget.pairedController!.clear();
        }
      }
    } else {
      // 当前是股票代码，检查配对的股票名称是否匹配
      final expectedName = await service.findNameByCode(currentValue);
      if (expectedName != null && widget.pairedController!.text != expectedName) {
        // 如果找到匹配的名称但当前名称不匹配，清空名称字段
        if (widget.pairedController!.text.isNotEmpty) {
          widget.pairedController!.clear();
        }
      }
    }
  }
}
