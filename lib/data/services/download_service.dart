import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
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
        // 检查文件是否存在
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('安装文件不存在: $filePath');
        }

        // 检查安装权限
        final permission = await Permission.requestInstallPackages.request();
        if (!permission.isGranted) {
          throw Exception('需要安装权限才能安装应用。请在设置中允许此应用安装未知来源的应用。');
        }

        debugPrint('准备安装APK: $filePath');

        // 使用open_file插件打开APK文件
        final result = await OpenFile.open(filePath);
        debugPrint('安装结果: ${result.type}, 消息: ${result.message}');

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
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Android 11 (API 30) 及以上版本，优先使用应用外部存储目录
        if (sdkInt >= 30) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // 在应用外部存储目录下创建Downloads子目录
            final downloadDir = Directory('${externalDir.path}/Downloads');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            return downloadDir;
          }
        } else {
          // Android 10 (API 29) 及以下版本，尝试使用公共Downloads目录
          final directory = Directory('/storage/emulated/0/Download');
          if (await directory.exists()) {
            return directory;
          }
        }

        // 备用方案：使用应用外部存储目录
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir;
        }
      } catch (e) {
        debugPrint('获取下载目录时出错: $e');
      }
    }

    // 其他平台或Android外部存储不可用时，使用应用文档目录
    return await getApplicationDocumentsDirectory();
  }

  /// 请求存储权限（适配不同Android版本）
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      debugPrint('Android SDK版本: $sdkInt');

      // Android 13 (API 33) 及以上版本
      if (sdkInt >= 33) {
        // 对于下载APK文件，我们主要需要能够写入到Downloads目录
        // 在Android 13+中，应用可以直接写入到自己的外部存储目录
        // 或者使用MediaStore API写入到公共目录
        return true; // 不需要特殊权限
      }
      // Android 11-12 (API 30-32)
      else if (sdkInt >= 30) {
        // Android 11引入了分区存储，但我们可以使用应用特定目录
        // 或者请求MANAGE_EXTERNAL_STORAGE权限（需要特殊审核）
        final status = await Permission.manageExternalStorage.status;
        if (status.isGranted) {
          return true;
        }

        // 如果没有管理外部存储权限，尝试使用应用特定目录
        return true; // 使用getExternalStorageDirectory()不需要权限
      }
      // Android 10 (API 29)
      else if (sdkInt >= 29) {
        // Android 10开始引入分区存储，但WRITE_EXTERNAL_STORAGE仍然有效
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      // Android 9 (API 28) 及以下
      else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('获取权限时出错: $e');
      // 如果出错，尝试请求基本的存储权限
      final status = await Permission.storage.request();
      return status.isGranted;
    }
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
