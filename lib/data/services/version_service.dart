import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/version_info.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/config/app_config.dart';

class VersionService {
  // SharedPreferences 键
  static const String _lastCheckTimeKey = 'last_version_check_time';
  static const String _autoCheckEnabledKey = 'auto_version_check_enabled';
  
  /// 获取当前应用版本
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  /// 获取应用构建号
  Future<String> getBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
  
  /// 获取应用信息
  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }
  
  /// 从GitHub Release获取最新版本信息
  Future<VersionInfo> getLatestVersion() async {
    try {
      final config = AppConfig.getCurrentGithubConfig();
      final url = config['apiUrl']!;

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': AppConfig.userAgent,
        },
      ).timeout(AppConfig.networkTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseVersionInfo(data);
      } else if (response.statusCode == 404) {
        throw AppException('未找到GitHub仓库或Release信息');
      } else {
        throw AppException('获取版本信息失败: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('网络请求失败: $e');
    }
  }
  
  /// 检查更新
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      final currentVersion = await getCurrentVersion();
      final latestVersion = await getLatestVersion();

      final hasUpdate = VersionComparator.hasNewVersion(
        currentVersion,
        latestVersion.tagName,
      );

      // 更新最后检查时间
      await _updateLastCheckTime();

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: hasUpdate ? latestVersion : null,
      );
    } catch (e) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: await getCurrentVersion(),
        errorMessage: e.toString(),
      );
    }
  }
  
  /// 解析GitHub Release响应
  VersionInfo _parseVersionInfo(Map<String, dynamic> data) {
    // 查找合适的下载链接
    String downloadUrl = data['html_url'] ?? '';
    final assets = data['assets'] as List?;
    
    if (assets != null && assets.isNotEmpty) {
      // 优先查找APK文件
      final apkAsset = assets.firstWhere(
        (asset) => asset['name']?.toString().toLowerCase().endsWith('.apk') == true,
        orElse: () => null,
      );
      
      if (apkAsset != null) {
        downloadUrl = apkAsset['browser_download_url'] ?? downloadUrl;
      }
    }
    
    return VersionInfo(
      tagName: data['tag_name'] ?? '',
      name: data['name'] ?? data['tag_name'] ?? '',
      body: data['body'] ?? '',
      htmlUrl: data['html_url'] ?? '',
      downloadUrl: downloadUrl,
      publishedAt: DateTime.parse(data['published_at'] ?? DateTime.now().toIso8601String()),
      prerelease: data['prerelease'] ?? false,
      draft: data['draft'] ?? false,
    );
  }
  
  /// 获取最后检查时间
  Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastCheckTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  /// 更新最后检查时间
  Future<void> _updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckTimeKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// 获取自动检查设置
  Future<bool> isAutoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCheckEnabledKey) ?? true;
  }
  
  /// 设置自动检查
  Future<void> setAutoCheckEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckEnabledKey, enabled);
  }
  
  /// 获取GitHub配置信息
  Map<String, String> getGithubConfig() {
    return AppConfig.getCurrentGithubConfig();
  }

  /// 检查是否需要自动检查更新（避免频繁检查）
  Future<bool> shouldAutoCheck() async {
    if (!await isAutoCheckEnabled()) return false;

    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) return true;

    // 使用配置文件中的检查间隔
    final now = DateTime.now();
    final difference = now.difference(lastCheck);
    return difference >= AppConfig.versionCheckInterval;
  }
}
