import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/models/version_info.dart';
import '../../data/repositories/version_repository.dart';
import '../../data/services/version_service.dart';

// 服务提供者
final versionServiceProvider = Provider<VersionService>((ref) {
  return VersionService();
});

// 仓库提供者
final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  final versionService = ref.watch(versionServiceProvider);
  return VersionRepository(versionService);
});

// 当前应用信息提供者
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  final repository = ref.watch(versionRepositoryProvider);
  return await repository.getPackageInfo();
});

// 当前版本提供者
final currentVersionProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(versionRepositoryProvider);
  return await repository.getCurrentVersion();
});

// 自动检查设置提供者
final autoCheckEnabledProvider = StateNotifierProvider<AutoCheckNotifier, bool>((ref) {
  final repository = ref.watch(versionRepositoryProvider);
  return AutoCheckNotifier(repository);
});

class AutoCheckNotifier extends StateNotifier<bool> {
  final VersionRepository _repository;
  
  AutoCheckNotifier(this._repository) : super(true) {
    _loadAutoCheckSetting();
  }
  
  Future<void> _loadAutoCheckSetting() async {
    state = await _repository.isAutoCheckEnabled();
  }
  
  Future<void> setAutoCheckEnabled(bool enabled) async {
    await _repository.setAutoCheckEnabled(enabled);
    state = enabled;
  }
}

// GitHub配置提供者
final githubConfigProvider = StateNotifierProvider<GithubConfigNotifier, Map<String, String>>((ref) {
  final repository = ref.watch(versionRepositoryProvider);
  return GithubConfigNotifier(repository);
});

class GithubConfigNotifier extends StateNotifier<Map<String, String>> {
  final VersionRepository _repository;
  
  GithubConfigNotifier(this._repository) : super({}) {
    _loadGithubConfig();
  }
  
  Future<void> _loadGithubConfig() async {
    state = _repository.getGithubConfig();
  }

  // GitHub配置现在通过配置文件管理，不再支持运行时修改
  Map<String, String> getCurrentConfig() {
    return _repository.getGithubConfig();
  }
}

// 版本检查结果提供者
final versionCheckProvider = StateNotifierProvider<VersionCheckNotifier, AsyncValue<UpdateCheckResult>>((ref) {
  final repository = ref.watch(versionRepositoryProvider);
  return VersionCheckNotifier(repository);
});

class VersionCheckNotifier extends StateNotifier<AsyncValue<UpdateCheckResult>> {
  final VersionRepository _repository;
  
  VersionCheckNotifier(this._repository) : super(const AsyncValue.loading());
  
  /// 手动检查更新
  Future<void> checkForUpdates() async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _repository.manualCheckForUpdates();
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// 自动检查更新（如果需要）
  Future<void> autoCheckForUpdates() async {
    if (await _repository.shouldAutoCheck()) {
      await checkForUpdates();
    }
  }
  
  /// 重置状态
  void reset() {
    state = const AsyncValue.loading();
  }
}

// 最后检查时间提供者
final lastCheckTimeProvider = FutureProvider<DateTime?>((ref) async {
  final repository = ref.watch(versionRepositoryProvider);
  return await repository.getLastCheckTime();
});

// 版本信息格式化提供者
final versionInfoProvider = Provider<VersionInfoFormatter>((ref) {
  return VersionInfoFormatter();
});

class VersionInfoFormatter {
  /// 格式化版本号
  String formatVersion(String version) {
    return VersionComparator.formatVersion(version);
  }
  
  /// 格式化发布时间
  String formatPublishTime(DateTime publishTime) {
    final now = DateTime.now();
    final difference = now.difference(publishTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// 格式化更新内容
  String formatReleaseNotes(String body) {
    if (body.isEmpty) return '暂无更新说明';
    
    // 简单的Markdown处理
    return body
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // 移除标题标记
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // 移除粗体标记
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1') // 移除斜体标记
        .trim();
  }
  
  /// 获取版本类型描述
  String getVersionTypeDescription(VersionInfo version) {
    if (version.prerelease) {
      return '预发布版本';
    } else if (version.draft) {
      return '草稿版本';
    } else {
      return '正式版本';
    }
  }
}
