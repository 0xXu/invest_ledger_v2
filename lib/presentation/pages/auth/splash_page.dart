import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // 等待一个短暂的延迟来显示启动画面
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 尝试自动登录
    await ref.read(userProvider.notifier).autoLogin();
    
    // 检查用户状态
    final user = ref.read(userProvider);
    
    if (mounted) {
      if (user != null) {
        // 用户已登录，跳转到仪表盘
        context.go('/dashboard');
      } else {
        // 用户未登录，跳转到用户选择页面
        context.go('/user-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 应用图标
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.trending_up,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // 应用名称
            Text(
              'InvestLedger',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 副标题
            Text(
              '轻量级个人投资记账应用',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 48),
            
            // 加载指示器
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
