import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'data/database/database_helper.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('环境变量加载成功');
  } catch (e) {
    debugPrint('环境变量加载失败: $e');
  }

  // 初始化数据库
  await DatabaseHelper.database;

  // 初始化 Supabase
  try {
    await SupabaseConfig.initialize();
    debugPrint('Supabase 初始化成功');
  } catch (e) {
    // Supabase 初始化失败时继续运行，但功能会受限
    debugPrint('Supabase 初始化失败: $e');
  }

  runApp(
    const ProviderScope(
      child: InvestLedgerApp(),
    ),
  );
}