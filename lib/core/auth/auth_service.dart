import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/app_logger.dart';
import '../sync/sync_manager.dart';
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



  // 邮箱密码注册（使用邮件链接验证）
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      AppLogger.debug('开始注册流程: $email');
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://cosmic-pixie-347a3c.netlify.app/callback',
        data: displayName != null ? {'display_name': displayName, 'name': displayName} : null,
      );

      // 检查Supabase的响应
      if (response.user != null) {
        AppLogger.success('注册响应成功，用户ID: ${response.user!.id}');

        // 检查用户是否已经验证（开发环境可能自动验证）
        if (response.user!.emailConfirmedAt != null) {
          // 邮箱已验证，直接登录
          AppLogger.success('用户注册成功并已验证，直接登录');
          state = AppAuthState(
            status: AuthStatus.authenticated,
            user: response.user,
            isLoading: false,
          );
        } else {
          // 邮箱未验证，确保发送确认邮件
          AppLogger.info('用户注册成功，邮箱未验证，尝试发送确认邮件到: $email');
          try {
            await _client.auth.resend(
              type: OtpType.signup,
              email: email,
            );
            AppLogger.success('确认邮件发送成功');
          } catch (resendError) {
            // 如果重发失败，可能是因为邮件已经发送过了，继续执行
            AppLogger.warning('重发邮件失败（可能已发送）: $resendError');
          }

          state = AppAuthState(
            status: AuthStatus.emailNotVerified,
            user: response.user,
            isLoading: false,
          );
        }
      } else {
        // 没有返回用户对象，可能是用户已存在
        AppLogger.warning('注册响应中没有用户对象，可能用户已存在');
        state = state.copyWith(
          isLoading: false,
          errorMessage: '该邮箱已被注册，请直接登录或使用忘记密码功能',
        );
        throw Exception('USER_ALREADY_EXISTS');
      }
    } catch (e) {
      final errorMessage = e.toString();
      AppLogger.error('注册过程中发生错误: $errorMessage');

      // 检查是否是用户已存在的错误
      if (errorMessage.contains('User already registered') ||
          errorMessage.contains('USER_ALREADY_EXISTS') ||
          errorMessage.contains('email_address_not_authorized') ||
          errorMessage.contains('signup_disabled') ||
          errorMessage.contains('Email rate limit exceeded')) {
        AppLogger.info('检测到用户已存在相关错误');
        state = state.copyWith(
          isLoading: false,
          errorMessage: '该邮箱已被注册，请直接登录或使用忘记密码功能',
        );
        throw Exception('USER_ALREADY_EXISTS');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(errorMessage),
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
    AppLogger.debug('开始登录流程，邮箱: $email');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      AppLogger.debug('调用 Supabase signInWithPassword');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      AppLogger.debug('登录响应: user=${user?.id}, emailConfirmed=${user?.emailConfirmedAt}');

      if (user != null) {
        if (user.emailConfirmedAt == null) {
          AppLogger.info('用户邮箱未验证，设置状态为 emailNotVerified');
          state = AppAuthState(
            status: AuthStatus.emailNotVerified,
            user: user,
            isLoading: false,
          );
        } else {
          AppLogger.success('用户登录成功，设置状态为 authenticated');

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
              AppLogger.success('✅ 用户凭据已保存');
            }
          }

          state = AppAuthState(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
          );
        }
      } else {
        AppLogger.warning('登录响应中没有用户信息');
      }
    } catch (e) {
      AppLogger.error('登录失败: $e');
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
