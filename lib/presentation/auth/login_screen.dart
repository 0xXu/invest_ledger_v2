import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }



  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = ref.read(authServiceProvider.notifier);
    debugPrint('🔄 开始认证流程，模式: ${_isSignUp ? "注册" : "登录"}');

    try {
      if (_isSignUp) {
        // 注册流程：发送邮件链接验证
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          final authState = ref.read(authServiceProvider);
          if (authState.status == AuthStatus.authenticated) {
            // 用户已自动验证并登录
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('注册成功！'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/dashboard');
          } else {
            // 需要邮件验证
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('注册成功！请检查您的邮箱并点击验证链接完成注册。'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 8),
              ),
            );
          }
        }
      } else {
        // 登录流程
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        final authState = ref.read(authServiceProvider);
        final errorMessage = authState.errorMessage ?? e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(errorMessage)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? '注册账户' : '登录账户'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 添加顶部间距
                const SizedBox(height: 40),
                Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
              const SizedBox(height: 32),
              Text(
                '投资记账本',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '管理您的投资数据',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邮箱';
                  }
                  if (!value.contains('@')) {
                    return '请输入有效的邮箱地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  helperText: _isSignUp ? '密码至少6位，建议包含字母和数字' : null,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码至少需要6位';
                  }
                  if (_isSignUp) {
                    // 注册时的密码强度检查
                    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                      return '密码应包含字母和数字';
                    }
                  }
                  return null;
                },
              ),

              // 确认密码字段（仅在注册时显示）
              if (_isSignUp) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: '确认密码',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (!_isSignUp) return null;
                    if (value == null || value.isEmpty) {
                      return '请确认密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleAuth,
                  child: authState.isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isSignUp ? '注册' : '登录'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _confirmPasswordController.clear();
                  });
                },
                child: Text(_isSignUp ? '已有账户？点击登录' : '没有账户？点击注册'),
              ),
              if (!_isSignUp) ...[
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text('忘记密码？'),
                ),
              ],
              // 添加底部间距
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
    );
  }



  // 显示忘记密码对话框
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入您的邮箱地址，我们将发送重置密码的链接。'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '邮箱',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的邮箱地址')),
                );
                return;
              }

              try {
                final authService = ref.read(authServiceProvider.notifier);
                await authService.sendPasswordResetOTP(email);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('密码重置邮件已发送，请检查您的邮箱'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('发送失败: ${_getErrorMessage(e.toString())}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  // 获取友好的错误信息
  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return '邮箱或密码错误';
    } else if (error.contains('Email not confirmed')) {
      return '邮箱未验证';
    } else if (error.contains('User already registered')) {
      return '该邮箱已被注册';
    } else if (error.contains('Password should be at least 6 characters')) {
      return '密码至少需要6位字符';
    } else if (error.contains('Unable to validate email address')) {
      return '邮箱格式不正确';
    } else if (error.contains('Network request failed')) {
      return '网络连接失败，请检查网络设置';
    } else {
      return '操作失败，请稍后重试';
    }
  }
}
