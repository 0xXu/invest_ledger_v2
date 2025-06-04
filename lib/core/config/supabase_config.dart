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

    // 调试信息
    print('🔧 Supabase 配置:');
    print('  URL: $supabaseUrl');
    print('  Key: ${supabaseAnonKey.substring(0, 20)}...');
    print('  Debug: ${dotenv.env['DEBUG_MODE'] == 'true'}');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // 强制启用调试模式
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // 使用 PKCE 流程，更安全
      ),
    );

    print('✅ Supabase 初始化完成');
  }
  
  // 检查是否已初始化
  static bool get isInitialized => Supabase.instance.client.auth.currentUser != null;
  
  // 获取当前用户
  static User? get currentUser => Supabase.instance.client.auth.currentUser;
  
  // 检查是否已登录
  static bool get isLoggedIn => currentUser != null;
}
