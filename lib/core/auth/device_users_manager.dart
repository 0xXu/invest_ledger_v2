import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 设备用户信息
class DeviceUser {
  final String id;
  final String email;
  final String? displayName;
  final DateTime addedAt;
  final DateTime? lastLoginAt;

  const DeviceUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.addedAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'addedAt': addedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory DeviceUser.fromJson(Map<String, dynamic> json) {
    return DeviceUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  DeviceUser copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? addedAt,
    DateTime? lastLoginAt,
  }) {
    return DeviceUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      addedAt: addedAt ?? this.addedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 设备用户管理器
class DeviceUsersManager {
  static const String _storageKey = 'device_users';
  static DeviceUsersManager? _instance;
  
  DeviceUsersManager._();
  
  static DeviceUsersManager get instance {
    _instance ??= DeviceUsersManager._();
    return _instance!;
  }

  /// 获取所有设备用户
  Future<List<DeviceUser>> getDeviceUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_storageKey);
      
      if (usersJson == null) return [];
      
      final usersList = jsonDecode(usersJson) as List;
      return usersList
          .map((json) => DeviceUser.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('获取设备用户失败: $e');
      return [];
    }
  }

  /// 添加用户到设备（从 Supabase User）
  Future<void> addDeviceUser(User user) async {
    try {
      final users = await getDeviceUsers();

      // 检查用户是否已存在
      final existingIndex = users.indexWhere((u) => u.id == user.id);

      final deviceUser = DeviceUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] as String?,
        addedAt: existingIndex == -1 ? DateTime.now() : users[existingIndex].addedAt,
        lastLoginAt: DateTime.now(),
      );

      if (existingIndex != -1) {
        // 更新现有用户的最后登录时间
        users[existingIndex] = deviceUser;
      } else {
        // 添加新用户
        users.add(deviceUser);
      }

      await _saveUsers(users);
    } catch (e) {
      print('添加设备用户失败: $e');
    }
  }

  /// 添加设备用户（直接添加 DeviceUser）
  Future<void> addDeviceUserDirect(DeviceUser deviceUser) async {
    try {
      final users = await getDeviceUsers();

      // 检查用户是否已存在
      final existingIndex = users.indexWhere((u) => u.id == deviceUser.id);

      if (existingIndex != -1) {
        // 更新现有用户
        users[existingIndex] = deviceUser;
      } else {
        // 添加新用户
        users.add(deviceUser);
      }

      await _saveUsers(users);
    } catch (e) {
      print('添加设备用户失败: $e');
    }
  }

  /// 移除设备用户
  Future<void> removeDeviceUser(String userId) async {
    try {
      final users = await getDeviceUsers();
      users.removeWhere((user) => user.id == userId);
      await _saveUsers(users);
    } catch (e) {
      print('移除设备用户失败: $e');
    }
  }

  /// 更新用户显示名称
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      final users = await getDeviceUsers();
      final index = users.indexWhere((u) => u.id == userId);
      
      if (index != -1) {
        users[index] = users[index].copyWith(displayName: displayName);
        await _saveUsers(users);
      }
    } catch (e) {
      print('更新用户显示名称失败: $e');
    }
  }

  /// 获取用户显示名称
  Future<String> getUserDisplayName(String userId) async {
    try {
      final users = await getDeviceUsers();
      final user = users.firstWhere((u) => u.id == userId);
      return user.displayName ?? user.email;
    } catch (e) {
      return 'Unknown User';
    }
  }

  /// 清除所有设备用户
  Future<void> clearAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('清除设备用户失败: $e');
    }
  }

  /// 保存用户列表
  Future<void> _saveUsers(List<DeviceUser> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_storageKey, usersJson);
    } catch (e) {
      print('保存设备用户失败: $e');
    }
  }
}
