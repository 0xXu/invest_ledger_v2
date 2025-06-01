# Git 提交指南

## 📋 应该提交到Git的文件

### ✅ 源代码文件
- `lib/` - 所有Dart源代码文件
- `test/` - 测试文件
- `integration_test/` - 集成测试文件

### ✅ 配置文件
- `pubspec.yaml` - 项目依赖配置
- `analysis_options.yaml` - 代码分析配置
- `build.yaml` - 构建配置（如果有）

### ✅ 平台配置文件
- `android/app/build.gradle.kts` - Android构建配置
- `android/app/src/main/AndroidManifest.xml` - Android清单文件
- `android/app/src/main/kotlin/` - Android Kotlin代码
- `android/app/src/main/res/` - Android资源文件（除了敏感信息）
- `ios/Runner/Info.plist` - iOS配置文件
- `ios/Runner.xcodeproj/` - iOS项目配置
- `windows/runner/` - Windows平台代码
- `linux/` - Linux平台代码
- `macos/` - macOS平台代码

### ✅ 资源文件
- `assets/` - 应用资源（图片、字体等）
- `fonts/` - 字体文件

### ✅ 文档文件
- `README.md` - 项目说明
- `docs/` - 项目文档
- `CHANGELOG.md` - 更新日志（如果有）

### ✅ 其他重要文件
- `.gitignore` - Git忽略规则
- `LICENSE` - 许可证文件

## ❌ 不应该提交到Git的文件

### ❌ 构建产物
- `build/` - 构建输出目录
- `*.apk`, `*.aab` - Android安装包
- `*.ipa` - iOS安装包
- `*.exe`, `*.app` - 桌面应用程序

### ❌ 依赖和缓存
- `.dart_tool/` - Dart工具缓存
- `.pub-cache/` - Pub包缓存
- `pubspec.lock` - 依赖锁定文件（可选择性提交）
- `node_modules/` - Node.js依赖
- `__pycache__/` - Python缓存

### ❌ 生成的代码
- `*.g.dart` - 代码生成文件
- `*.freezed.dart` - Freezed生成文件
- `*.gr.dart` - 路由生成文件
- `*.config.dart` - 配置生成文件

### ❌ 平台特定的构建文件
- `android/build/` - Android构建缓存
- `android/.gradle/` - Gradle缓存
- `android/local.properties` - 本地Android配置
- `ios/Pods/` - iOS CocoaPods依赖
- `ios/.symlinks/` - iOS符号链接

### ❌ 敏感信息
- `.env` - 环境变量文件
- `android/key.properties` - Android签名密钥
- `android/app/google-services.json` - Firebase配置
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase配置
- API密钥和密码文件

### ❌ 临时文件
- `*.tmp`, `*.temp` - 临时文件
- `*.log` - 日志文件
- `*.bak` - 备份文件
- `.DS_Store` - macOS系统文件
- `Thumbs.db` - Windows缩略图缓存

### ❌ IDE和编辑器文件
- `.idea/` - IntelliJ IDEA配置
- `.vscode/` - VS Code配置（可选择性提交）
- `*.iml` - IntelliJ模块文件

## 🔍 关于XML文件的说明

### ✅ 应该提交的XML文件
- `android/app/src/main/AndroidManifest.xml` - Android应用清单
- `android/app/src/main/res/values/strings.xml` - 字符串资源
- `android/app/src/main/res/values/colors.xml` - 颜色资源
- `android/app/src/main/res/values/styles.xml` - 样式资源
- `android/app/src/main/res/layout/*.xml` - 布局文件
- `android/app/src/main/res/drawable/*.xml` - 矢量图形
- `ios/Runner/Info.plist` - iOS配置（虽然是plist格式）

### ❌ 不应该提交的XML文件
- `android/app/src/main/res/values/strings_secrets.xml` - 包含敏感信息的字符串
- 任何包含API密钥、密码或其他敏感信息的XML文件
- 构建过程中生成的临时XML文件

## 📝 最佳实践

### 1. 检查敏感信息
在提交前，确保没有包含：
- API密钥
- 数据库密码
- 私钥文件
- 个人配置信息

### 2. 使用环境变量
对于敏感配置，使用环境变量或配置文件：
```dart
// 好的做法
const apiKey = String.fromEnvironment('API_KEY');

// 避免的做法
const apiKey = 'your-secret-api-key';
```

### 3. 定期清理
定期检查并清理不需要的文件：
```bash
flutter clean
git status
```

### 4. 提交前检查
使用以下命令检查将要提交的文件：
```bash
git add .
git status
git diff --cached
```

## 🚨 注意事项

1. **pubspec.lock**: 这个文件可以选择性提交
   - 提交：确保团队使用相同版本的依赖
   - 不提交：允许使用最新兼容版本

2. **生成的代码**: 虽然被忽略，但确保能够重新生成
   ```bash
   flutter packages pub run build_runner build
   ```

3. **平台特定配置**: 只提交必要的配置文件，避免本地特定的设置

4. **大文件**: 避免提交大型媒体文件，考虑使用Git LFS

通过遵循这些指南，您的Git仓库将保持干净、安全且易于维护。
