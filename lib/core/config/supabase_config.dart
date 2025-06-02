import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // 从环境变量中获取配置
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    // 验证配置
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase 配置不完整，请检查 .env 文件');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: dotenv.env['DEBUG_MODE'] == 'true', // 从环境变量读取调试模式
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // 使用 PKCE 流程，更安全
      ),
    );
  }
  
  // 检查是否已初始化
  static bool get isInitialized => Supabase.instance.client.auth.currentUser != null;
  
  // 获取当前用户
  static User? get currentUser => Supabase.instance.client.auth.currentUser;
  
  // 检查是否已登录
  static bool get isLoggedIn => currentUser != null;
}
