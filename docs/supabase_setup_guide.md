# Supabase 多设备同步配置指南

本指南将帮助您配置 Supabase 以实现投资记账本的多设备数据同步功能。

## 第一步：创建 Supabase 项目

1. 访问 [Supabase](https://supabase.com) 并注册账户
2. 点击 "New Project" 创建新项目
3. 选择组织，输入项目名称（如：invest-ledger）
4. 设置数据库密码（请妥善保存）
5. 选择地区（建议选择离您最近的地区）
6. 点击 "Create new project"

## 第二步：获取项目配置信息

1. 项目创建完成后，进入项目仪表板
2. 点击左侧菜单的 "Settings" → "API"
3. 复制以下信息：
   - **Project URL**（项目 URL）
   - **anon public** key（匿名公钥）

## 第三步：配置应用

应用已配置为使用环境变量管理敏感信息。您需要在项目根目录的 `.env` 文件中填写您的配置：

1. 打开项目根目录的 `.env` 文件
2. 将您的 Supabase 信息填入：

```env
# 将下面的值替换为您的实际配置
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

**⚠️ 重要提示**：
- 确保复制的是 `anon public` key，不是 `service_role` key
- `.env` 文件已被 `.gitignore` 忽略，不会被提交到代码仓库

## 第四步：创建数据库表

1. 在 Supabase 仪表板中，点击左侧菜单的 "SQL Editor"
2. 点击 "New query"
3. 复制 `docs/supabase_schema.sql` 文件中的所有内容
4. 粘贴到 SQL 编辑器中
5. 点击 "Run" 执行脚本

## 第五步：配置认证

1. 在 Supabase 仪表板中，点击左侧菜单的 "Authentication"
2. 点击 "Settings" 标签
3. 在 "Auth Providers" 部分，确保 "Email" 已启用
4. 根据需要配置其他设置：
   - **Site URL**: 您的应用域名（开发时可以是 localhost）
   - **Redirect URLs**: 认证后的重定向地址

## 第六步：安装依赖并运行

1. 在项目根目录运行以下命令安装新依赖：
```bash
flutter pub get
```

2. 生成必要的代码文件：
```bash
flutter packages pub run build_runner build
```

3. 运行应用：
```bash
flutter run
```

## 功能说明

### 离线优先策略
- 应用优先使用本地数据，确保离线时正常工作
- 有网络时自动同步数据到云端
- 支持冲突检测和解决

### 数据同步
- **自动同步**: 网络恢复时自动同步
- **手动同步**: 用户可以手动触发同步
- **增量同步**: 只同步修改过的数据，提高效率

### 用户认证
- 支持邮箱密码注册/登录
- 支持跳过登录（仅本地模式）
- 自动处理认证状态变化

### 数据安全
- 使用 Row Level Security (RLS) 确保用户只能访问自己的数据
- 所有敏感操作都需要认证
- 支持数据加密传输

## 故障排除

### 常见问题

1. **Supabase 初始化失败**
   - 检查网络连接
   - 确认 URL 和 API Key 配置正确
   - 查看控制台错误信息

2. **同步失败**
   - 检查用户是否已登录
   - 确认网络连接正常
   - 查看同步状态提示

3. **认证问题**
   - 确认邮箱格式正确
   - 检查密码长度（至少6位）
   - 查看 Supabase 认证设置

### 调试技巧

1. 启用调试模式：
```dart
// 在 supabase_config.dart 中
static Future<void> initialize() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true, // 设为 true 启用调试
  );
}
```

2. 查看网络请求：
   - 在 Supabase 仪表板的 "Logs" 中查看 API 调用
   - 使用浏览器开发者工具查看网络请求

## 下一步

配置完成后，您可以：

1. 注册新账户或登录现有账户
2. 创建一些测试数据
3. 在不同设备上登录同一账户验证同步功能
4. 测试离线模式和网络恢复后的自动同步

## 安全建议

1. **不要将 API Key 提交到公共代码仓库**
2. **定期更换数据库密码**
3. **监控 Supabase 使用量，避免超出免费额度**
4. **在生产环境中配置适当的 RLS 策略**

如果遇到问题，请查看 [Supabase 官方文档](https://supabase.com/docs) 或在项目中创建 issue。
