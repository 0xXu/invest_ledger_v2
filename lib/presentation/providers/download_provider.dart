import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/services/download_service.dart';
import '../../data/models/version_info.dart';

/// 下载状态管理
class DownloadState {
  final DownloadProgress? progress;
  final String? filePath;
  final bool isVisible;

  const DownloadState({
    this.progress,
    this.filePath,
    this.isVisible = false,
  });

  DownloadState copyWith({
    DownloadProgress? progress,
    String? filePath,
    bool? isVisible,
  }) {
    return DownloadState(
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// 下载管理器
class DownloadNotifier extends StateNotifier<DownloadState> {
  final DownloadService _downloadService;

  DownloadNotifier(this._downloadService) : super(const DownloadState());

  /// 开始下载APK
  Future<void> downloadApk(VersionInfo versionInfo) async {
    try {
      // 显示下载对话框
      state = state.copyWith(isVisible: true);

      // 生成文件名
      final fileName = 'InvestLedger_${versionInfo.tagName}.apk';

      // 开始下载
      final filePath = await _downloadService.downloadApk(
        url: versionInfo.downloadUrl,
        fileName: fileName,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      // 下载完成
      state = state.copyWith(filePath: filePath);
    } catch (e) {
      debugPrint('下载失败: $e');
      // 错误状态已在onProgress中设置
    }
  }

  /// 取消下载
  void cancelDownload() {
    _downloadService.cancelDownload();
    state = state.copyWith(
      progress: DownloadProgress(
        downloaded: 0,
        total: 0,
        progress: 0.0,
        status: DownloadStatus.cancelled,
      ),
    );
  }

  /// 安装APK
  Future<void> installApk() async {
    if (state.filePath != null) {
      try {
        await _downloadService.installApk(state.filePath!);
      } catch (e) {
        debugPrint('安装失败: $e');
        rethrow;
      }
    }
  }

  /// 隐藏下载对话框
  void hideDialog() {
    state = state.copyWith(isVisible: false);
  }

  /// 显示下载对话框
  void showDialog() {
    state = state.copyWith(isVisible: true);
  }

  /// 重置状态
  void reset() {
    state = const DownloadState();
  }
}

/// 下载服务提供者
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});

/// 下载状态提供者
final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  final downloadService = ref.watch(downloadServiceProvider);
  return DownloadNotifier(downloadService);
});
