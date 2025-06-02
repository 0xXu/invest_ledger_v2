import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// 安全凭据存储管理器
/// 用于安全存储用户登录凭据，支持一键快速登录
class SecureCredentialsManager {
  static const String _credentialsKey = 'secure_credentials';
  static const String _lastLoginUserKey = 'last_login_user';
  static const String _autoLoginEnabledKey = 'auto_login_enabled';
  static const String _quickLoginEnabledKey = 'quick_login_enabled';
  
  static SecureCredentialsManager? _instance;
  
  SecureCredentialsManager._();
  
  static SecureCredentialsManager get instance {
    _instance ??= SecureCredentialsManager._();
    return _instance!;
  }

  /// 保存用户凭据（加密存储）
  Future<void> saveCredentials({
    required String userId,
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 简单的加密（实际项目中应使用更强的加密）
      final encryptedPassword = _encryptPassword(password);
      
      final credentials = {
        'userId': userId,
        'email': email,
        'password': encryptedPassword,
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      // 获取现有凭据
      final existingCredentials = await getAllCredentials();
      
      // 更新或添加凭据
      existingCredentials[userId] = credentials;
      
      await prefs.setString(_credentialsKey, jsonEncode(existingCredentials));
      debugPrint('✅ 凭据已保存: $email');
    } catch (e) {
      debugPrint('❌ 保存凭据失败: $e');
    }
  }

  /// 获取用户凭据
  Future<Map<String, String>?> getCredentials(String userId) async {
    try {
      final allCredentials = await getAllCredentials();
      final userCredentials = allCredentials[userId];
      
      if (userCredentials != null) {
        return {
          'email': userCredentials['email'] as String,
          'password': _decryptPassword(userCredentials['password'] as String),
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ 获取凭据失败: $e');
      return null;
    }
  }

  /// 获取所有保存的凭据
  Future<Map<String, Map<String, dynamic>>> getAllCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final credentialsJson = prefs.getString(_credentialsKey);
      
      if (credentialsJson == null) return {};
      
      final decoded = jsonDecode(credentialsJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as Map<String, dynamic>));
    } catch (e) {
      debugPrint('❌ 获取所有凭据失败: $e');
      return {};
    }
  }

  /// 删除用户凭据
  Future<void> removeCredentials(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allCredentials = await getAllCredentials();
      
      allCredentials.remove(userId);
      
      await prefs.setString(_credentialsKey, jsonEncode(allCredentials));
      debugPrint('✅ 凭据已删除: $userId');
    } catch (e) {
      debugPrint('❌ 删除凭据失败: $e');
    }
  }

  /// 检查用户是否有保存的凭据
  Future<bool> hasCredentials(String userId) async {
    final credentials = await getCredentials(userId);
    return credentials != null;
  }

  /// 设置最后登录的用户
  Future<void> setLastLoginUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLoginUserKey, userId);
      debugPrint('✅ 最后登录用户已设置: $userId');
    } catch (e) {
      debugPrint('❌ 设置最后登录用户失败: $e');
    }
  }

  /// 获取最后登录的用户
  Future<String?> getLastLoginUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLoginUserKey);
    } catch (e) {
      debugPrint('❌ 获取最后登录用户失败: $e');
      return null;
    }
  }

  /// 设置自动登录开关
  Future<void> setAutoLoginEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoLoginEnabledKey, enabled);
      debugPrint('✅ 自动登录设置: $enabled');
    } catch (e) {
      debugPrint('❌ 设置自动登录失败: $e');
    }
  }

  /// 获取自动登录开关状态
  Future<bool> isAutoLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoLoginEnabledKey) ?? false;
    } catch (e) {
      debugPrint('❌ 获取自动登录状态失败: $e');
      return false;
    }
  }

  /// 设置快速登录开关
  Future<void> setQuickLoginEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_quickLoginEnabledKey, enabled);
      debugPrint('✅ 快速登录设置: $enabled');
    } catch (e) {
      debugPrint('❌ 设置快速登录失败: $e');
    }
  }

  /// 获取快速登录开关状态
  Future<bool> isQuickLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_quickLoginEnabledKey) ?? true; // 默认启用
    } catch (e) {
      debugPrint('❌ 获取快速登录状态失败: $e');
      return true;
    }
  }

  /// 清除所有凭据
  Future<void> clearAllCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_credentialsKey);
      await prefs.remove(_lastLoginUserKey);
      debugPrint('✅ 所有凭据已清除');
    } catch (e) {
      debugPrint('❌ 清除凭据失败: $e');
    }
  }

  /// 简单的密码加密（实际项目中应使用更强的加密）
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password + 'invest_ledger_salt');
    final digest = sha256.convert(bytes);
    return base64.encode(utf8.encode(password)).split('').reversed.join();
  }

  /// 简单的密码解密
  String _decryptPassword(String encryptedPassword) {
    try {
      final reversed = encryptedPassword.split('').reversed.join();
      return utf8.decode(base64.decode(reversed));
    } catch (e) {
      debugPrint('❌ 密码解密失败: $e');
      return '';
    }
  }
}
