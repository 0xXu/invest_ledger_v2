/// 应用配置类
/// 包含GitHub仓库信息、API配置等
class AppConfig {
  // GitHub仓库配置
  static const String githubOwner = '0xXu'; // 替换为你的GitHub用户名
  static const String githubRepo = 'invest_ledger-flutter'; // 替换为你的仓库名
  static const String githubApiUrl = 'https://api.github.com/repos';
  
  // 应用信息
  static const String appName = 'InvestLedger';
  static const String appDescription = '轻量级个人投资记账应用';
  
  // 版本检查配置
  static const Duration versionCheckInterval = Duration(hours: 24); // 24小时检查一次
  static const bool enableAutoVersionCheck = true; // 默认启用自动检查
  
  // 网络配置
  static const Duration networkTimeout = Duration(seconds: 10);
  static const String userAgent = 'InvestLedger-App';
  
  // 获取完整的GitHub Release API URL
  static String get githubReleaseApiUrl => '$githubApiUrl/$githubOwner/$githubRepo/releases/latest';
  
  // 获取GitHub仓库URL
  static String get githubRepoUrl => 'https://github.com/$githubOwner/$githubRepo';
  
  // 获取GitHub Release页面URL
  static String get githubReleasesUrl => '$githubRepoUrl/releases';
  
  // 开发模式配置
  static const bool isDevelopment = false; // 发布时改为false
  
  // 测试用的GitHub仓库（用于开发测试）
  static const String testGithubOwner = 'flutter';
  static const String testGithubRepo = 'flutter';
  
  // 获取测试用的GitHub Release API URL
  static String get testGithubReleaseApiUrl => '$githubApiUrl/$testGithubOwner/$testGithubRepo/releases/latest';
  
  /// 获取当前使用的GitHub配置
  static Map<String, String> getCurrentGithubConfig() {
    if (isDevelopment) {
      return {
        'owner': testGithubOwner,
        'repo': testGithubRepo,
        'apiUrl': testGithubReleaseApiUrl,
        'repoUrl': 'https://github.com/$testGithubOwner/$testGithubRepo',
      };
    } else {
      return {
        'owner': githubOwner,
        'repo': githubRepo,
        'apiUrl': githubReleaseApiUrl,
        'repoUrl': githubRepoUrl,
      };
    }
  }
  
  /// 验证GitHub配置是否有效
  static bool isGithubConfigValid() {
    final config = getCurrentGithubConfig();
    return config['owner']?.isNotEmpty == true &&
           config['repo']?.isNotEmpty == true;
  }
}
