import 'package:freezed_annotation/freezed_annotation.dart';

part 'version_info.freezed.dart';
part 'version_info.g.dart';

@freezed
class VersionInfo with _$VersionInfo {
  const factory VersionInfo({
    required String tagName,
    required String name,
    required String body,
    required String htmlUrl,
    required String downloadUrl,
    required DateTime publishedAt,
    required bool prerelease,
    required bool draft,
  }) = _VersionInfo;

  factory VersionInfo.fromJson(Map<String, dynamic> json) =>
      _$VersionInfoFromJson(json);
}

@freezed
class UpdateCheckResult with _$UpdateCheckResult {
  const factory UpdateCheckResult({
    required bool hasUpdate,
    required String currentVersion,
    VersionInfo? latestVersion,
    String? errorMessage,
  }) = _UpdateCheckResult;

  factory UpdateCheckResult.fromJson(Map<String, dynamic> json) =>
      _$UpdateCheckResultFromJson(json);
}

/// 版本比较工具类
class VersionComparator {
  /// 比较两个版本号
  /// 返回值：
  /// - 正数：version1 > version2
  /// - 0：version1 == version2  
  /// - 负数：version1 < version2
  static int compare(String version1, String version2) {
    // 移除 'v' 前缀
    final v1 = version1.replaceFirst(RegExp(r'^v'), '');
    final v2 = version2.replaceFirst(RegExp(r'^v'), '');
    
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    
    // 补齐版本号长度
    while (parts1.length < parts2.length) {
      parts1.add(0);
    }
    while (parts2.length < parts1.length) {
      parts2.add(0);
    }
    
    for (int i = 0; i < parts1.length; i++) {
      if (parts1[i] != parts2[i]) {
        return parts1[i] - parts2[i];
      }
    }
    
    return 0;
  }
  
  /// 检查是否有新版本
  static bool hasNewVersion(String currentVersion, String latestVersion) {
    return compare(currentVersion, latestVersion) < 0;
  }
  
  /// 格式化版本号显示
  static String formatVersion(String version) {
    if (version.startsWith('v')) {
      return version;
    }
    return 'v$version';
  }
}
