import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_service.dart';
import 'auth_state.dart';

/// 认证守卫组件
/// 用于保护需要登录的页面
class AuthGuard extends ConsumerWidget {
  final Widget child;
  
  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.checking:
        return const _LoadingScreen();
      case AuthStatus.authenticated:
        return child;
      case AuthStatus.unauthenticated:
        return const _RedirectToLogin();
      case AuthStatus.emailNotVerified:
        return const _EmailVerificationScreen();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('检查登录状态...'),
          ],
        ),
      ),
    );
  }
}

class _RedirectToLogin extends StatefulWidget {
  const _RedirectToLogin();

  @override
  State<_RedirectToLogin> createState() => _RedirectToLoginState();
}

class _RedirectToLoginState extends State<_RedirectToLogin> {
  @override
  void initState() {
    super.initState();
    // 延迟跳转，避免在 build 过程中导航
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/auth/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmailVerificationScreen extends ConsumerStatefulWidget {
  const _EmailVerificationScreen();

  @override
  ConsumerState<_EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<_EmailVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('邮箱验证'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              '验证您的邮箱',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '我们已向 ${authState.user?.email ?? ''} 发送了验证邮件\n请检查您的邮箱并点击验证链接完成注册',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final authService = ref.read(authServiceProvider.notifier);
                    await authService.resendVerificationEmail();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('验证邮件已重新发送'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('发送失败: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重新发送验证邮件'),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                final authService = ref.read(authServiceProvider.notifier);
                authService.signOut();
                context.go('/auth/login');
              },
              child: const Text('返回登录'),
            ),
          ],
        ),
      ),
    );
  }
}
