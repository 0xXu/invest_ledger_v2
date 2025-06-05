import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'auth_state.dart';
import 'device_users_manager.dart';
import 'secure_credentials_manager.dart';

class AuthService extends StateNotifier<AppAuthState> {
  AuthService() : super(const AppAuthState()) {
    _init();
  }

  final SupabaseClient _client = SupabaseConfig.client;
  StreamSubscription<AppAuthState>? _authSubscription;



  void _init() {
    // 监听认证状态变化
    _authSubscription = _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;

      if (user == null) {
        return const AppAuthState(status: AuthStatus.unauthenticated);
      }

      if (user.emailConfirmedAt == null) {
        return AppAuthState(
          status: AuthStatus.emailNotVerified,
          user: user,
        );
      }

      return AppAuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    }).listen((authState) {
      // 如果用户已认证，添加到设备用户列表
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        DeviceUsersManager.instance.addDeviceUser(authState.user!);
      }
      state = authState;
    });

    // 初始检查
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    state = state.copyWith(status: AuthStatus.checking);
    
    try {
      final session = _client.auth.currentSession;
      final user = session?.user;
      
      if (user == null) {
        state = const AppAuthState(status: AuthStatus.unauthenticated);
        return;
      }

      if (user.emailConfirmedAt == null) {
        state = AppAuthState(
          status: AuthStatus.emailNotVerified,
          user: user,
        );
        return;
      }

      state = AppAuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  // 检查用户是否已存在
  Future<bool> checkUserExists(String email) async {
    try {
      // 尝试使用错误的密码登录来检查用户是否存在
      // 这是一个巧妙的方法，因为Supabase会返回不同的错误信息
      await _client.auth.signInWithPassword(
        email: email,
        password: 'invalid_password_for_check_only',
      );
      // 如果没有抛出异常，说明密码正确（不太可能）
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint('检查用户存在性错误: $errorMessage');

      // 如果错误信息包含"Invalid login credentials"，说明用户存在但密码错误
      if (errorMessage.contains('Invalid login credentials')) {
        return true;
      }

      // 如果错误信息包含"Email not confirmed"，说明用户存在但未验证
      if (errorMessage.contains('Email not confirmed')) {
        return true;
      }

      // 其他错误（如用户不存在）返回false
      return false;
    }
  }

  // 邮箱密码注册（使用邮件链接验证）
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 首先检查用户是否已存在
      debugPrint('检查用户是否已存在: $email');
      final userExists = await checkUserExists(email);

      if (userExists) {
        debugPrint('用户已存在，不发送注册邮件');
        state = state.copyWith(
          isLoading: false,
          errorMessage: '该邮箱已被注册，请直接登录或使用忘记密码功能',
        );
        // 抛出自定义异常，让UI层处理
        throw Exception('USER_ALREADY_EXISTS');
      }

      debugPrint('用户不存在，继续注册流程');
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://cosmic-pixie-347a3c.netlify.app/callback',
        data: displayName != null ? {'display_name': displayName, 'name': displayName} : null,
      );

      if (response.user != null) {
        // 检查用户是否已经验证（开发环境可能自动验证）
        if (response.user!.emailConfirmedAt != null) {
          // 邮箱已验证，直接登录
          state = AppAuthState(
            status: AuthStatus.authenticated,
            user: response.user,
            isLoading: false,
          );
        } else {
          // 邮箱未验证，确保发送确认邮件
          debugPrint('用户注册成功，邮箱未验证，尝试发送确认邮件到: $email');
          try {
            await _client.auth.resend(
              type: OtpType.signup,
              email: email,
            );
            debugPrint('确认邮件发送成功');
          } catch (resendError) {
            // 如果重发失败，可能是因为邮件已经发送过了，继续执行
            debugPrint('重发邮件失败（可能已发送）: $resendError');
          }

          state = AppAuthState(
            status: AuthStatus.emailNotVerified,
            user: response.user,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      // 如果是用户已存在的异常，不需要重新设置错误信息
      if (e.toString().contains('USER_ALREADY_EXISTS')) {
        rethrow;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e.toString()),
      );
      rethrow;
    }
  }

  // 邮箱密码登录
  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool saveCredentials = true,
  }) async {
    debugPrint('开始登录流程，邮箱: $email');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      debugPrint('调用 Supabase signInWithPassword');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      debugPrint('登录响应: user=${user?.id}, emailConfirmed=${user?.emailConfirmedAt}');

      if (user != null) {
        if (user.emailConfirmedAt == null) {
          debugPrint('用户邮箱未验证，设置状态为 emailNotVerified');
          state = AppAuthState(
            status: AuthStatus.emailNotVerified,
            user: user,
            isLoading: false,
          );
        } else {
          debugPrint('用户登录成功，设置状态为 authenticated');

          // 保存凭据（如果启用）
          if (saveCredentials) {
            final credentialsManager = SecureCredentialsManager.instance;
            final isQuickLoginEnabled = await credentialsManager.isQuickLoginEnabled();

            if (isQuickLoginEnabled) {
              await credentialsManager.saveCredentials(
                userId: user.id,
                email: email,
                password: password,
              );
              await credentialsManager.setLastLoginUser(user.id);
              debugPrint('✅ 用户凭据已保存');
            }
          }

          state = AppAuthState(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
          );
        }
      } else {
        debugPrint('登录响应中没有用户信息');
      }
    } catch (e) {
      debugPrint('登录失败: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e.toString()),
      );
      rethrow;
    }
  }

  // 退出登录
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _client.auth.signOut();
      state = const AppAuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // 发送注册验证码
  Future<void> sendSignUpOTP(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 重新发送注册验证码
  Future<void> resendSignUpOTP(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 重新发送验证邮件
  Future<void> resendVerificationEmail() async {
    if (state.user?.email == null) return;

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: state.user!.email!,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 发送密码重置验证码
  Future<void> sendPasswordResetOTP(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://cosmic-pixie-347a3c.netlify.app/callback',
      );
    } catch (e) {
      rethrow;
    }
  }

  // 使用验证码重置密码
  Future<void> resetPasswordWithOTP({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: token,
      );

      // 验证成功后更新密码
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }



  // 重置密码（兼容旧版本）
  Future<void> resetPassword(String email) async {
    try {
      await sendPasswordResetOTP(email);
    } catch (e) {
      rethrow;
    }
  }

  // 更新密码
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  // 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return '邮箱或密码错误';
    } else if (error.contains('Email not confirmed')) {
      return '邮箱未验证';
    } else if (error.contains('User already registered')) {
      return '该邮箱已被注册，请直接登录或使用忘记密码功能';
    } else if (error.contains('USER_ALREADY_EXISTS')) {
      return '该邮箱已被注册，请直接登录或使用忘记密码功能';
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Riverpod provider
final authServiceProvider = StateNotifierProvider<AuthService, AppAuthState>((ref) {
  return AuthService();
});
