import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 自定义页面切换动画
class PageTransitions {
  /// 快速淡入淡出动画（用于主页面切换）
  static CustomTransitionPage<T> fadeTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  /// 滑动动画（用于详情页面）
  static CustomTransitionPage<T> slideTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection direction = SlideDirection.fromRight,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.fromRight:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.fromLeft:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.fromTop:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.fromBottom:
            begin = const Offset(0.0, 1.0);
            break;
        }

        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// 缩放动画（用于弹窗页面）
  static CustomTransitionPage<T> scaleTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutBack;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// 无动画（用于需要瞬间切换的场景）
  static CustomTransitionPage<T> noTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  /// 智能动画选择器
  static CustomTransitionPage<T> smartTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    bool isMainNavigation = false,
    bool isModal = false,
  }) {
    if (isModal) {
      return scaleTransition(child, state);
    } else if (isMainNavigation) {
      return fadeTransition(child, state, duration: const Duration(milliseconds: 150));
    } else {
      return slideTransition(child, state);
    }
  }
}

/// 滑动方向枚举
enum SlideDirection {
  fromRight,
  fromLeft,
  fromTop,
  fromBottom,
}

/// 页面切换性能优化器
class PageTransitionOptimizer {
  static const Duration _fastDuration = Duration(milliseconds: 150);
  static const Duration _normalDuration = Duration(milliseconds: 250);
  static const Duration _slowDuration = Duration(milliseconds: 350);

  /// 根据设备性能选择合适的动画时长
  static Duration getOptimalDuration(BuildContext context) {
    // 可以根据设备性能或用户设置来调整
    // 这里简化为固定值，实际可以检测设备性能
    return _fastDuration;
  }

  /// 检查是否应该禁用动画（低性能设备或用户设置）
  static bool shouldDisableAnimations(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}

/// 预构建的常用动画
class CommonTransitions {
  /// 主导航页面切换（快速淡入淡出）
  static CustomTransitionPage<T> mainNavigation<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return PageTransitions.fadeTransition(
      child,
      state,
      duration: const Duration(milliseconds: 150),
    );
  }

  /// 详情页面切换（滑动）
  static CustomTransitionPage<T> detailPage<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return PageTransitions.slideTransition(
      child,
      state,
      duration: const Duration(milliseconds: 250),
    );
  }

  /// 模态页面切换（缩放）
  static CustomTransitionPage<T> modalPage<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return PageTransitions.scaleTransition(
      child,
      state,
      duration: const Duration(milliseconds: 200),
    );
  }
}
