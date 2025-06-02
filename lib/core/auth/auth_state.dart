import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.freezed.dart';

@freezed
class AppAuthState with _$AppAuthState {
  const factory AppAuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    User? user,
    String? errorMessage,
    @Default(false) bool isLoading,
  }) = _AppAuthState;
}

enum AuthStatus {
  initial,        // 初始状态
  checking,       // 检查登录状态中
  authenticated,  // 已认证
  unauthenticated,// 未认证
  emailNotVerified, // 邮箱未验证
}

extension AuthStateX on AppAuthState {
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isEmailNotVerified => status == AuthStatus.emailNotVerified;
  bool get isChecking => status == AuthStatus.checking;
  bool get isInitial => status == AuthStatus.initial;

  String? get userEmail => user?.email;
  String? get userId => user?.id;
  bool get isEmailConfirmed => user?.emailConfirmedAt != null;
}
