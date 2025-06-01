import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/loading_utils.dart';

/// 通用刷新按钮组件
///
/// 提供统一的刷新功能，包含刷新动画和全局加载状态管理
class RefreshButton extends ConsumerStatefulWidget {
  /// 刷新回调函数
  final Future<void> Function() onRefresh;

  /// 加载时显示的消息
  final String? loadingMessage;

  /// 按钮图标
  final IconData icon;

  /// 按钮大小
  final double? iconSize;

  /// 按钮颜色
  final Color? color;

  /// 工具提示
  final String? tooltip;

  /// 是否为图标按钮样式（默认）还是文本按钮样式
  final RefreshButtonStyle style;

  /// 文本按钮的标签（仅在style为text时使用）
  final String? label;

  /// 是否禁用按钮
  final bool enabled;

  const RefreshButton({
    super.key,
    required this.onRefresh,
    this.loadingMessage,
    this.icon = LucideIcons.refreshCw,
    this.iconSize,
    this.color,
    this.tooltip,
    this.style = RefreshButtonStyle.icon,
    this.label,
    this.enabled = true,
  });

  /// 创建图标样式的刷新按钮
  const RefreshButton.icon({
    super.key,
    required this.onRefresh,
    this.loadingMessage,
    this.icon = LucideIcons.refreshCw,
    this.iconSize,
    this.color,
    this.tooltip = '刷新数据',
    this.enabled = true,
  }) : style = RefreshButtonStyle.icon,
       label = null;

  /// 创建文本样式的刷新按钮
  const RefreshButton.text({
    super.key,
    required this.onRefresh,
    this.loadingMessage,
    this.icon = LucideIcons.refreshCw,
    this.iconSize,
    this.color,
    this.label = '刷新',
    this.enabled = true,
  }) : style = RefreshButtonStyle.text,
       tooltip = null;

  /// 创建填充样式的刷新按钮
  const RefreshButton.filled({
    super.key,
    required this.onRefresh,
    this.loadingMessage,
    this.icon = LucideIcons.refreshCw,
    this.iconSize,
    this.color,
    this.label = '刷新',
    this.enabled = true,
  }) : style = RefreshButtonStyle.filled,
       tooltip = null;

  @override
  ConsumerState<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing || !widget.enabled) return;

    setState(() {
      _isRefreshing = true;
    });

    // 开始旋转动画
    _animationController.repeat();

    try {
      await ref.withLoading(
        widget.onRefresh,
        widget.loadingMessage ?? '正在刷新数据...',
      );
    } finally {
      // 停止动画并重置
      _animationController.stop();
      _animationController.reset();

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.onSurface;

    Widget iconWidget = AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.enabled ? effectiveColor : effectiveColor.withValues(alpha: 0.5),
          ),
        );
      },
    );

    switch (widget.style) {
      case RefreshButtonStyle.icon:
        return IconButton(
          onPressed: widget.enabled ? _handleRefresh : null,
          icon: iconWidget,
          tooltip: widget.tooltip,
        );

      case RefreshButtonStyle.text:
        return TextButton.icon(
          onPressed: widget.enabled ? _handleRefresh : null,
          icon: iconWidget,
          label: Text(widget.label ?? '刷新'),
        );

      case RefreshButtonStyle.filled:
        return FilledButton.icon(
          onPressed: widget.enabled ? _handleRefresh : null,
          icon: iconWidget,
          label: Text(widget.label ?? '刷新'),
        );
    }
  }
}

/// 刷新按钮样式枚举
enum RefreshButtonStyle {
  /// 图标按钮样式
  icon,
  /// 文本按钮样式
  text,
  /// 填充按钮样式
  filled,
}
