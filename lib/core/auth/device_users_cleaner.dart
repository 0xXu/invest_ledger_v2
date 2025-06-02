import 'package:flutter/foundation.dart';
import 'device_users_manager.dart';

/// 设备用户清理工具
/// 用于清理重复的设备用户记录
class DeviceUsersCleaner {
  static DeviceUsersCleaner? _instance;
  
  DeviceUsersCleaner._();
  
  static DeviceUsersCleaner get instance {
    _instance ??= DeviceUsersCleaner._();
    return _instance!;
  }

  /// 清理重复的设备用户
  Future<void> cleanDuplicateUsers() async {
    try {
      final manager = DeviceUsersManager.instance;
      final users = await manager.getDeviceUsers();
      
      if (users.isEmpty) return;
      
      // 按用户ID分组，找出重复的用户
      final Map<String, List<DeviceUser>> userGroups = {};
      for (final user in users) {
        userGroups.putIfAbsent(user.id, () => []).add(user);
      }
      
      // 找出有重复的用户组
      final duplicateGroups = userGroups.entries
          .where((entry) => entry.value.length > 1)
          .toList();
      
      if (duplicateGroups.isEmpty) {
        debugPrint('✅ 没有发现重复的设备用户');
        return;
      }
      
      debugPrint('🔍 发现 ${duplicateGroups.length} 组重复用户，开始清理...');
      
      // 清理重复用户，保留最新的一个
      final List<DeviceUser> cleanedUsers = [];
      
      for (final entry in userGroups.entries) {
        final userList = entry.value;
        
        if (userList.length == 1) {
          // 没有重复，直接保留
          cleanedUsers.add(userList.first);
        } else {
          // 有重复，保留最新登录的那个
          userList.sort((a, b) {
            final aTime = a.lastLoginAt ?? a.addedAt;
            final bTime = b.lastLoginAt ?? b.addedAt;
            return bTime.compareTo(aTime); // 降序，最新的在前
          });
          
          // 合并用户信息，保留最完整的数据
          final bestUser = _mergeUserInfo(userList);
          cleanedUsers.add(bestUser);
          
          debugPrint('🧹 清理用户 ${entry.key}：${userList.length} 个重复记录 → 1 个记录');
        }
      }
      
      // 清除所有用户，然后重新添加清理后的用户
      await manager.clearAllUsers();

      for (final user in cleanedUsers) {
        await manager.addDeviceUserDirect(user);
      }
      
      debugPrint('✅ 设备用户清理完成：${users.length} → ${cleanedUsers.length}');
      
    } catch (e) {
      debugPrint('❌ 清理设备用户失败: $e');
    }
  }

  /// 合并用户信息，选择最完整的数据
  DeviceUser _mergeUserInfo(List<DeviceUser> users) {
    if (users.isEmpty) throw ArgumentError('用户列表不能为空');
    if (users.length == 1) return users.first;
    
    // 按最后登录时间排序，最新的在前
    users.sort((a, b) {
      final aTime = a.lastLoginAt ?? a.addedAt;
      final bTime = b.lastLoginAt ?? b.addedAt;
      return bTime.compareTo(aTime);
    });
    
    final latest = users.first;
    final earliest = users.last;
    
    // 合并信息：使用最新的登录时间，但保留最早的添加时间和最完整的显示名称
    return DeviceUser(
      id: latest.id,
      email: latest.email,
      displayName: _getBestDisplayName(users),
      addedAt: earliest.addedAt, // 使用最早的添加时间
      lastLoginAt: latest.lastLoginAt, // 使用最新的登录时间
    );
  }

  /// 获取最佳的显示名称
  String? _getBestDisplayName(List<DeviceUser> users) {
    // 优先选择非空且不是邮箱的显示名称
    for (final user in users) {
      final displayName = user.displayName;
      if (displayName != null && 
          displayName.isNotEmpty && 
          displayName != user.email &&
          !displayName.contains('@')) {
        return displayName;
      }
    }
    
    // 如果都没有好的显示名称，返回第一个非空的
    for (final user in users) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName;
      }
    }
    
    return null;
  }

  /// 检查是否有重复用户
  Future<bool> hasDuplicateUsers() async {
    try {
      final manager = DeviceUsersManager.instance;
      final users = await manager.getDeviceUsers();
      
      final userIds = users.map((u) => u.id).toSet();
      return userIds.length != users.length;
    } catch (e) {
      debugPrint('❌ 检查重复用户失败: $e');
      return false;
    }
  }

  /// 获取重复用户统计信息
  Future<Map<String, dynamic>> getDuplicateStats() async {
    try {
      final manager = DeviceUsersManager.instance;
      final users = await manager.getDeviceUsers();
      
      final Map<String, int> userCounts = {};
      for (final user in users) {
        userCounts[user.id] = (userCounts[user.id] ?? 0) + 1;
      }
      
      final duplicates = userCounts.entries
          .where((entry) => entry.value > 1)
          .toList();
      
      return {
        'totalUsers': users.length,
        'uniqueUsers': userCounts.length,
        'duplicateGroups': duplicates.length,
        'duplicateCount': duplicates.fold<int>(0, (sum, entry) => sum + entry.value - 1),
      };
    } catch (e) {
      debugPrint('❌ 获取重复用户统计失败: $e');
      return {
        'totalUsers': 0,
        'uniqueUsers': 0,
        'duplicateGroups': 0,
        'duplicateCount': 0,
      };
    }
  }
}
