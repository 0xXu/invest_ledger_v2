import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

/// 下载状态
enum DownloadStatus {
  idle,       // 空闲
  downloading, // 下载中
  completed,   // 完成
  failed,      // 失败
  cancelled,   // 取消
}

/// 下载进度信息
class DownloadProgress {
  final int downloaded;
  final int total;
  final double progress;
  final DownloadStatus status;
  final String? error;

  const DownloadProgress({
    required this.downloaded,
    required this.total,
    required this.progress,
    required this.status,
    this.error,
  });

  DownloadProgress copyWith({
    int? downloaded,
    int? total,
    double? progress,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadProgress(
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

/// 下载服务
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  http.Client? _client;
  bool _isCancelled = false;

  /// 下载APK文件
  Future<String> downloadApk({
    required String url,
    required String fileName,
    required Function(DownloadProgress) onProgress,
  }) async {
    try {
      // 检查存储权限
      if (Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          throw Exception('需要存储权限才能下载文件');
        }
      }

      // 获取下载目录
      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      // 检查文件是否已存在
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 初始化HTTP客户端
      _client = http.Client();
      _isCancelled = false;

      // 发送请求
      final request = http.Request('GET', Uri.parse(url));
      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];
      int downloaded = 0;

      // 监听下载进度
      await for (final chunk in response.stream) {
        if (_isCancelled) {
          throw Exception('下载已取消');
        }

        bytes.addAll(chunk);
        downloaded += chunk.length;

        final progress = contentLength > 0 ? downloaded / contentLength : 0.0;
        onProgress(DownloadProgress(
          downloaded: downloaded,
          total: contentLength,
          progress: progress,
          status: DownloadStatus.downloading,
        ));
      }

      // 写入文件
      await file.writeAsBytes(bytes);

      // 下载完成
      onProgress(DownloadProgress(
        downloaded: downloaded,
        total: contentLength,
        progress: 1.0,
        status: DownloadStatus.completed,
      ));

      return filePath;
    } catch (e) {
      onProgress(DownloadProgress(
        downloaded: 0,
        total: 0,
        progress: 0.0,
        status: DownloadStatus.failed,
        error: e.toString(),
      ));
      rethrow;
    } finally {
      _client?.close();
      _client = null;
    }
  }

  /// 取消下载
  void cancelDownload() {
    _isCancelled = true;
    _client?.close();
    _client = null;
  }

  /// 安装APK文件
  Future<void> installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // 检查安装权限
        final permission = await Permission.requestInstallPackages.request();
        if (!permission.isGranted) {
          throw Exception('需要安装权限才能安装应用');
        }

        // 使用open_file插件打开APK文件
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception('无法打开安装文件: ${result.message}');
        }
      } else {
        throw Exception('当前平台不支持APK安装');
      }
    } catch (e) {
      debugPrint('安装APK失败: $e');
      rethrow;
    }
  }

  /// 获取下载目录
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Android使用外部存储的Downloads目录
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
      
      // 如果Downloads目录不存在，使用应用外部存储目录
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
    }

    // 其他平台或Android外部存储不可用时，使用应用文档目录
    return await getApplicationDocumentsDirectory();
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 格式化下载速度
  static String formatDownloadSpeed(int bytesPerSecond) {
    return '${formatFileSize(bytesPerSecond)}/s';
  }
}
