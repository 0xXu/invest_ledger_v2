import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'data/database/database_helper.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.success('环境变量加载成功');
  } catch (e) {
    AppLogger.error('环境变量加载失败', e);
  }

  // 初始化数据库
  await DatabaseHelper.database;

  // 初始化缓存管理器
  CacheManager().initialize();
  AppLogger.success('缓存管理器初始化成功');

  // 初始化 Supabase
  try {
    await SupabaseConfig.initialize();
    AppLogger.success('Supabase 初始化成功');
  } catch (e) {
    // Supabase 初始化失败时继续运行，但功能会受限
    AppLogger.error('Supabase 初始化失败', e);
  }

  runApp(
    const ProviderScope(
      child: InvestLedgerApp(),
    ),
  );
}