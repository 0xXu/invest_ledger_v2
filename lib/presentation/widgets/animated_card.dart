import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 带有进入/退出视图动画的卡片组件
class AnimatedCard extends StatefulWidget {
  /// 卡片内容
  final Widget child;

  /// 动画持续时间
  final Duration duration;

  /// 动画延迟时间
  final Duration delay;

  /// 动画曲线
  final Curve curve;

  /// 是否启用动画
  final bool enableAnimation;

  /// 动画类型
  final CardAnimationType animationType;

  /// 滑动方向（仅在slideIn类型时使用）
  final SlideDirection slideDirection;

  /// 缩放起始值（仅在scaleIn类型时使用）
  final double scaleStart;

  /// 是否启用滚动可见性检测
  final bool enableScrollVisibility;

  /// 可见性阈值（0.0-1.0）
  final double visibilityThreshold;

  const AnimatedCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.enableAnimation = true,
    this.animationType = CardAnimationType.fadeIn,
    this.slideDirection = SlideDirection.fromBottom,
    this.scaleStart = 0.8,
    this.enableScrollVisibility = true,
    this.visibilityThreshold = 0.1,
  });

  /// 创建淡入动画卡片
  const AnimatedCard.fadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.enableAnimation = true,
    this.enableScrollVisibility = true,
    this.visibilityThreshold = 0.1,
  }) : animationType = CardAnimationType.fadeIn,
       slideDirection = SlideDirection.fromBottom,
       scaleStart = 0.8;

  /// 创建滑入动画卡片
  const AnimatedCard.slideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.enableAnimation = true,
    this.slideDirection = SlideDirection.fromBottom,
    this.enableScrollVisibility = true,
    this.visibilityThreshold = 0.1,
  }) : animationType = CardAnimationType.slideIn,
       scaleStart = 0.8;

  /// 创建缩放动画卡片
  const AnimatedCard.scaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutBack,
    this.enableAnimation = true,
    this.scaleStart = 0.8,
    this.enableScrollVisibility = true,
    this.visibilityThreshold = 0.1,
  }) : animationType = CardAnimationType.scaleIn,
       slideDirection = SlideDirection.fromBottom;

  /// 创建组合动画卡片（淡入+滑入）
  const AnimatedCard.fadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.enableAnimation = true,
    this.slideDirection = SlideDirection.fromBottom,
    this.enableScrollVisibility = true,
    this.visibilityThreshold = 0.1,
  }) : animationType = CardAnimationType.fadeSlideIn,
       scaleStart = 0.8;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // 滚动可见性检测
  bool _isVisible = false;
  double _visibilityRatio = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // 创建动画
    _createAnimations();

    // 启动动画
    if (widget.enableAnimation) {
      if (widget.enableScrollVisibility) {
        // 如果启用滚动可见性检测，初始状态为隐藏，但需要延迟检查可见性
        _controller.value = 0.0;
        // 延迟检查初始可见性
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkInitialVisibility();
          }
        });
      } else {
        // 否则播放初始动画
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    } else {
      _controller.value = 1.0;
    }
  }

  void _createAnimations() {
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // 淡入动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // 滑入动画
    Offset slideBegin;
    switch (widget.slideDirection) {
      case SlideDirection.fromTop:
        slideBegin = const Offset(0.0, -0.3);
        break;
      case SlideDirection.fromBottom:
        slideBegin = const Offset(0.0, 0.3);
        break;
      case SlideDirection.fromLeft:
        slideBegin = const Offset(-0.3, 0.0);
        break;
      case SlideDirection.fromRight:
        slideBegin = const Offset(0.3, 0.0);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(curvedAnimation);

    // 缩放动画
    _scaleAnimation = Tween<double>(
      begin: widget.scaleStart,
      end: 1.0,
    ).animate(curvedAnimation);
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

    Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget animatedChild = widget.child;

        switch (widget.animationType) {
          case CardAnimationType.fadeIn:
            animatedChild = FadeTransition(
              opacity: _fadeAnimation,
              child: animatedChild,
            );
            break;

          case CardAnimationType.slideIn:
            animatedChild = SlideTransition(
              position: _slideAnimation,
              child: animatedChild,
            );
            break;

          case CardAnimationType.scaleIn:
            animatedChild = ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: animatedChild,
              ),
            );
            break;

          case CardAnimationType.fadeSlideIn:
            animatedChild = FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: animatedChild,
              ),
            );
            break;
        }

        return animatedChild;
      },
    );

    // 如果启用滚动可见性检测，包装在可见性检测器中
    if (widget.enableScrollVisibility) {
      return ScrollVisibilityDetector(
        onVisibilityChanged: _handleVisibilityChanged,
        visibilityThreshold: widget.visibilityThreshold,
        child: content,
      );
    }

    return content;
  }

  void _checkInitialVisibility() {
    // 对于初始加载的卡片，如果在视口内，直接显示
    // 这里简化处理：如果启用了滚动可见性但是延迟时间不为0，说明是初始动画
    if (widget.delay != Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      // 立即显示
      _controller.forward();
    }
  }

  void _handleVisibilityChanged(bool isVisible, double visibilityRatio) {
    if (_isVisible != isVisible) {
      setState(() {
        _isVisible = isVisible;
        _visibilityRatio = visibilityRatio;
      });

      if (isVisible && visibilityRatio >= widget.visibilityThreshold) {
        // 进入视图，播放淡入动画
        _controller.forward();
      } else if (!isVisible || visibilityRatio < widget.visibilityThreshold) {
        // 离开视图，播放淡出动画
        _controller.reverse();
      }
    }
  }
}

/// 卡片动画类型
enum CardAnimationType {
  /// 淡入
  fadeIn,
  /// 滑入
  slideIn,
  /// 缩放
  scaleIn,
  /// 淡入+滑入
  fadeSlideIn,
}

/// 滑动方向
enum SlideDirection {
  fromTop,
  fromBottom,
  fromLeft,
  fromRight,
}

/// 滚动视图可见性检测器
class ScrollVisibilityDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onVisible;
  final VoidCallback? onHidden;
  final Function(bool isVisible, double visibilityRatio)? onVisibilityChanged;
  final double visibilityThreshold;
  final Duration animationDuration;

  const ScrollVisibilityDetector({
    super.key,
    required this.child,
    this.onVisible,
    this.onHidden,
    this.onVisibilityChanged,
    this.visibilityThreshold = 0.1,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ScrollVisibilityDetector> createState() => _ScrollVisibilityDetectorState();
}

class _ScrollVisibilityDetectorState extends State<ScrollVisibilityDetector>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 初始检查可见性
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }

  void _checkVisibility() {
    if (!mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // 检查垂直可见性
    final topVisible = position.dy < screenSize.height;
    final bottomVisible = position.dy + size.height > 0;
    final isCurrentlyVisible = topVisible && bottomVisible;

    // 计算可见比例
    double visibilityRatio = 0.0;
    if (isCurrentlyVisible) {
      final visibleTop = math.max(0.0, -position.dy);
      final visibleBottom = math.min(size.height, screenSize.height - position.dy);
      final visibleHeight = math.max(0.0, visibleBottom - visibleTop);
      visibilityRatio = visibleHeight / size.height;
    }

    final shouldBeVisible = visibilityRatio >= widget.visibilityThreshold;

    if (shouldBeVisible != _isVisible) {
      setState(() {
        _isVisible = shouldBeVisible;
      });

      // 调用新的可见性变化回调
      widget.onVisibilityChanged?.call(shouldBeVisible, visibilityRatio);

      if (shouldBeVisible) {
        _controller.forward();
        widget.onVisible?.call();
      } else {
        _controller.reverse();
        widget.onHidden?.call();
      }
    }
  }
}

/// 智能卡片组件 - 结合初始动画和滚动可见性
class SmartAnimatedCard extends StatelessWidget {
  final Widget child;
  final Duration initialDelay;
  final CardAnimationType animationType;
  final SlideDirection slideDirection;
  final bool enableScrollAnimation;
  final bool enableInitialAnimation;
  final double visibilityThreshold;

  const SmartAnimatedCard({
    super.key,
    required this.child,
    this.initialDelay = Duration.zero,
    this.animationType = CardAnimationType.fadeSlideIn,
    this.slideDirection = SlideDirection.fromBottom,
    this.enableScrollAnimation = true,
    this.enableInitialAnimation = true,
    this.visibilityThreshold = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    Widget animatedChild = child;

    // 如果启用滚动动画，包装在滚动可见性检测器中
    if (enableScrollAnimation) {
      animatedChild = ScrollVisibilityDetector(
        visibilityThreshold: visibilityThreshold,
        child: animatedChild,
      );
    }

    // 如果启用初始动画，包装在初始动画卡片中
    if (enableInitialAnimation) {
      animatedChild = AnimatedCard(
        animationType: animationType,
        slideDirection: slideDirection,
        delay: initialDelay,
        enableAnimation: enableInitialAnimation,
        child: animatedChild,
      );
    }

    return animatedChild;
  }
}

/// 卡片列表动画器 - 重构版本，简化逻辑
class AnimatedCardList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final CardAnimationType animationType;
  final SlideDirection slideDirection;
  final bool enableAnimation;
  final bool enableScrollAnimation;

  const AnimatedCardList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationType = CardAnimationType.fadeSlideIn,
    this.slideDirection = SlideDirection.fromBottom,
    this.enableAnimation = true,
    this.enableScrollAnimation = false, // 默认关闭滚动动画，避免复杂性
  });

  @override
  Widget build(BuildContext context) {
    if (!enableAnimation) {
      // 如果不启用动画，直接返回简单的Column
      return Column(children: children);
    }

    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        // 简化：只使用基础的AnimatedCard，不使用SmartAnimatedCard
        return AnimatedCard(
          animationType: animationType,
          slideDirection: slideDirection,
          enableAnimation: enableAnimation,
          enableScrollVisibility: enableScrollAnimation,
          delay: Duration(milliseconds: index * staggerDelay.inMilliseconds),
          child: child,
        );
      }).toList(),
    );
  }
}

/// 滚动列表动画器 - 专门用于长列表
class ScrollAnimatedList extends StatelessWidget {
  final List<Widget> children;
  final bool enableScrollAnimation;
  final double visibilityThreshold;
  final Duration animationDuration;

  const ScrollAnimatedList({
    super.key,
    required this.children,
    this.enableScrollAnimation = true,
    this.visibilityThreshold = 0.1,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.map((child) {
        if (enableScrollAnimation) {
          return ScrollVisibilityDetector(
            visibilityThreshold: visibilityThreshold,
            animationDuration: animationDuration,
            child: child,
          );
        }
        return child;
      }).toList(),
    );
  }
}
