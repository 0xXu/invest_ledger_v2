import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';

import 'theme.dart';
import 'routes.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/widgets/global_loading_overlay.dart';
import '../presentation/widgets/version_check_wrapper.dart';
import '../core/sync/sync_manager.dart';
import '../core/utils/app_logger.dart';

class InvestLedgerApp extends ConsumerStatefulWidget {
  const InvestLedgerApp({super.key});

  @override
  ConsumerState<InvestLedgerApp> createState() => _InvestLedgerAppState();
}

class _InvestLedgerAppState extends ConsumerState<InvestLedgerApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // 监听深度链接
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (err) {
        AppLogger.error('深度链接处理错误: $err');
      },
    );

    // 检查应用启动时的深度链接
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink);
      }
    } catch (e) {
      AppLogger.error('获取初始深度链接失败: $e');
    }
  }

  void _handleIncomingLink(Uri uri) {
    AppLogger.info('收到深度链接: $uri');
    
    if (uri.scheme == 'investledger') {
      switch (uri.host) {
        case 'auth':
          _handleAuthLink(uri);
          break;
        default:
          AppLogger.warning('未知的深度链接主机: ${uri.host}');
      }
    }
  }

  void _handleAuthLink(Uri uri) {
    final path = uri.path;
    final queryParams = uri.queryParameters;
    
    if (path == '/reset-password') {
      final email = queryParams['email'];
      final code = queryParams['code']; // Supabase 使用 code 参数
      final token = queryParams['token']; // 兼容旧的 token 参数
      
      final verificationCode = code ?? token;
      
      if (email != null && verificationCode != null) {
        AppLogger.info('处理密码重置深度链接: email=$email');
        
        // 使用路由跳转到重置密码页面
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final router = ref.read(routerProvider);
          router.go('/auth/reset-password', extra: {
            'email': email,
            'token': verificationCode, // 统一使用 token 字段名在应用内部
          });
        });
      } else {
        AppLogger.error('密码重置深度链接缺少必要参数: email=$email, code=$code, token=$token');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    // 确保SyncManager被初始化（这会启动认证状态监听）
    ref.watch(syncManagerProvider);

    return MaterialApp.router(
      title: 'InvestLedger',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // 在这里包装 GlobalLoadingOverlay 和 VersionCheckWrapper，确保它们在 MaterialApp 内部
        return VersionCheckWrapper(
          child: GlobalLoadingOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
