import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/datasources/local/user_dao.dart';

part 'user_provider.g.dart';

// Repository providers
@riverpod
UserDao userDao(UserDaoRef ref) {
  return UserDao();
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(ref.watch(userDaoProvider));
}

// Current user provider
@Riverpod(keepAlive: true)
class UserNotifier extends _$UserNotifier {
  static const String _userIdKey = 'current_user_id';

  @override
  User? build() {
    return null;
  }

  Future<void> autoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);

      if (userId != null) {
        final userRepository = ref.read(userRepositoryProvider);
        final user = await userRepository.getUserById(userId);
        if (user != null) {
          state = user;
        } else {
          // 用户不存在，清除保存的ID
          await prefs.remove(_userIdKey);
        }
      }
    } catch (e) {
      print('自动登录失败: $e');
    }
  }

  Future<bool> login(String email) async {
    try {
      print('开始登录用户: $email');
      final userRepository = ref.read(userRepositoryProvider);
      final user = await userRepository.loginUser(email);

      if (user != null) {
        print('登录成功，用户: ${user.name}');
        // 保存用户ID到本地存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, user.id);
        print('用户ID已保存到本地存储: ${user.id}');

        // 更新状态
        state = user;
        print('用户状态已更新，当前状态: ${state?.name}');

        // 验证状态是否正确设置
        if (state != null) {
          print('状态验证成功: ${state!.id}');
        } else {
          print('警告：状态设置后仍为null');
        }
        return true;
      }
      print('登录失败：用户不存在');
      return false;
    } catch (e) {
      print('登录失败: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // 清除本地存储的用户ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);

      // 清除状态
      state = null;
    } catch (e) {
      print('登出失败: $e');
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
  }) async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final userId = await userRepository.createUser(name: name, email: email);

      // 创建成功后自动登录
      return await login(email);
    } catch (e) {
      print('创建用户失败: $e');
      return false;
    }
  }

  Future<void> updateSettings(UserSettings settings) async {
    if (state == null) return;

    final userRepository = ref.read(userRepositoryProvider);
    final updatedUser = state!.copyWith(settings: settings);
    await userRepository.updateUser(updatedUser);
    state = updatedUser;
  }

  Future<void> updateProfile({
    String? name,
    String? email,
  }) async {
    if (state == null) return;

    final userRepository = ref.read(userRepositoryProvider);
    final updatedUser = state!.copyWith(
      name: name ?? state!.name,
      email: email ?? state!.email,
    );
    await userRepository.updateUser(updatedUser);
    state = updatedUser;
  }
}

// All users provider (for admin purposes)
@riverpod
Future<List<User>> allUsers(AllUsersRef ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getAllUsers();
}

// Convenience provider for current user
final userProvider = userNotifierProvider;
