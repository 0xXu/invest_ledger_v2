import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'routes.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/widgets/global_loading_overlay.dart';
import '../presentation/widgets/version_check_wrapper.dart';

class InvestLedgerApp extends ConsumerWidget {
  const InvestLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

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
