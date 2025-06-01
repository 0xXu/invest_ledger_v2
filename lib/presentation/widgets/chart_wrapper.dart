import 'package:flutter/material.dart';

/// 图表包装器 - 确保图表能够正确渲染
class ChartWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final bool enableAnimation;

  const ChartWrapper({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.enableAnimation = true,
  });

  @override
  State<ChartWrapper> createState() => _ChartWrapperState();
}

class _ChartWrapperState extends State<ChartWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 延迟显示图表，确保布局完成
    _scheduleAnimation();
  }

  void _scheduleAnimation() {
    if (widget.enableAnimation) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            _isVisible = true;
          });
          _controller.forward();
        }
      });
    } else {
      setState(() {
        _isVisible = true;
      });
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimation) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: _isVisible ? widget.child : const SizedBox.shrink(),
        );
      },
    );
  }
}

/// 图表容器 - 为图表提供稳定的渲染环境
class ChartContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ChartContainer({
    super.key,
    required this.child,
    this.height,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      margin: margin,
      child: RepaintBoundary(
        child: child,
      ),
    );
  }
}

/// 延迟渲染组件 - 确保图表在布局稳定后再渲染
class DelayedRenderer extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Widget? placeholder;

  const DelayedRenderer({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
    this.placeholder,
  });

  @override
  State<DelayedRenderer> createState() => _DelayedRendererState();
}

class _DelayedRendererState extends State<DelayedRenderer> {
  bool _shouldRender = false;

  @override
  void initState() {
    super.initState();
    // 延迟渲染，确保父组件布局完成
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _shouldRender = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldRender) {
      return widget.child;
    }

    return widget.placeholder ??
        const SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
  }
}
