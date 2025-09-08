import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/widgets/responsive_layout.dart';
import '../../app/routes.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayout(
      mobile: _MobileLayout(child: child),
      desktop: _DesktopLayout(child: child),
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  final Widget child;

  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    // 根据当前路由更新导航状态
    _updateNavigationIndex(context, ref);

    return Scaffold(
      body: Row(
        children: [
          // 侧边导航栏
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              ref.read(navigationProvider.notifier).setIndex(index);
              _navigateToPage(context, index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(LucideIcons.layoutDashboard),
                selectedIcon: Icon(LucideIcons.layoutDashboard),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.receipt),
                selectedIcon: Icon(LucideIcons.receipt),
                label: Text('记录'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.barChart3),
                selectedIcon: Icon(LucideIcons.barChart3),
                label: Text('分析'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主内容区
          Expanded(child: child),
        ],
      ),
    );
  }

  void _updateNavigationIndex(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    int newIndex = 0;

    if (location.startsWith('/dashboard')) {
      newIndex = 0;
    } else if (location.startsWith('/transactions')) {
      newIndex = 1;
    } else if (location.startsWith('/analytics')) {
      newIndex = 2;
    } else if (location.startsWith('/settings') || 
               location.startsWith('/import-export')) {
      // 这些页面通过设置菜单或其他方式访问，暂时映射到首页
      newIndex = 0;
    }

    // 只有当索引不同时才更新，避免无限循环和不必要的重建
    final currentIndex = ref.read(navigationProvider);
    if (currentIndex != newIndex) {
      // 使用微任务延迟更新，避免在build过程中修改状态
      Future.microtask(() {
        if (context.mounted) {
          ref.read(navigationProvider.notifier).setIndex(newIndex);
        }
      });
    }
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/analytics');
        break;
    }
  }
}

class _MobileLayout extends ConsumerWidget {
  final Widget child;

  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    // 根据当前路由更新导航状态
    _updateNavigationIndex(context, ref);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
          _navigateToPage(context, index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.layoutDashboard),
            selectedIcon: Icon(LucideIcons.layoutDashboard),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.receipt),
            selectedIcon: Icon(LucideIcons.receipt),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.barChart3),
            selectedIcon: Icon(LucideIcons.barChart3),
            label: '分析',
          ),
        ],
      ),
    );
  }

  void _updateNavigationIndex(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    int newIndex = 0;

    if (location.startsWith('/dashboard')) {
      newIndex = 0;
    } else if (location.startsWith('/transactions')) {
      newIndex = 1;
    } else if (location.startsWith('/analytics')) {
      newIndex = 2;
    } else if (location.startsWith('/settings') || 
               location.startsWith('/import-export')) {
      // 这些页面通过设置菜单或其他方式访问，暂时映射到首页
      newIndex = 0;
    }

    // 只有当索引不同时才更新，避免无限循环和不必要的重建
    final currentIndex = ref.read(navigationProvider);
    if (currentIndex != newIndex) {
      // 使用微任务延迟更新，避免在build过程中修改状态
      Future.microtask(() {
        if (context.mounted) {
          ref.read(navigationProvider.notifier).setIndex(newIndex);
        }
      });
    }
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/analytics');
        break;
    }
  }
}