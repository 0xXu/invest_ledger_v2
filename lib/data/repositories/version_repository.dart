import 'package:package_info_plus/package_info_plus.dart';

import '../models/version_info.dart';
import '../services/version_service.dart';

class VersionRepository {
  final VersionService _versionService;
  
  VersionRepository(this._versionService);
  
  /// 获取当前应用版本
  Future<String> getCurrentVersion() async {
    return await _versionService.getCurrentVersion();
  }
  
  /// 获取应用构建号
  Future<String> getBuildNumber() async {
    return await _versionService.getBuildNumber();
  }
  
  /// 获取完整的应用信息
  Future<PackageInfo> getPackageInfo() async {
    return await _versionService.getPackageInfo();
  }
  
  /// 检查更新
  Future<UpdateCheckResult> checkForUpdates() async {
    return await _versionService.checkForUpdates();
  }

  /// 获取最新版本信息
  Future<VersionInfo> getLatestVersion() async {
    return await _versionService.getLatestVersion();
  }
  
  /// 获取最后检查时间
  Future<DateTime?> getLastCheckTime() async {
    return await _versionService.getLastCheckTime();
  }
  
  /// 获取自动检查设置
  Future<bool> isAutoCheckEnabled() async {
    return await _versionService.isAutoCheckEnabled();
  }
  
  /// 设置自动检查
  Future<void> setAutoCheckEnabled(bool enabled) async {
    await _versionService.setAutoCheckEnabled(enabled);
  }
  
  /// 获取GitHub配置
  Map<String, String> getGithubConfig() {
    return _versionService.getGithubConfig();
  }

  /// 检查是否需要自动检查更新
  Future<bool> shouldAutoCheck() async {
    return await _versionService.shouldAutoCheck();
  }

  /// 手动触发版本检查
  Future<UpdateCheckResult> manualCheckForUpdates() async {
    return await checkForUpdates();
  }
}
