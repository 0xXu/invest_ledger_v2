import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/device_users_manager.dart';

part 'device_users_provider.g.dart';

/// 设备用户列表提供者
@riverpod
class DeviceUsersNotifier extends _$DeviceUsersNotifier {
  @override
  Future<List<DeviceUser>> build() async {
    return await DeviceUsersManager.instance.getDeviceUsers();
  }

  /// 添加设备用户
  Future<void> addUser(DeviceUser user) async {
    state = const AsyncValue.loading();
    try {
      await DeviceUsersManager.instance.addDeviceUserDirect(user);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 移除设备用户
  Future<void> removeUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await DeviceUsersManager.instance.removeDeviceUser(userId);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 更新用户显示名称
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await DeviceUsersManager.instance.updateDisplayName(userId, displayName);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 刷新用户列表
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}


