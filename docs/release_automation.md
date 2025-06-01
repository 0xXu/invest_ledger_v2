# 自动发布脚本使用指南

## 📋 概述

这些脚本可以自动化Flutter APK的构建和发布流程，包括：
- 自动构建Release APK
- 更新版本号
- 创建Git标签
- 创建GitHub Release
- 上传APK文件

## 🛠️ 准备工作

### 1. 安装必要工具

#### Windows
- [Flutter SDK](https://flutter.dev/docs/get-started/install/windows)
- [Git](https://git-scm.com/download/win)
- [GitHub CLI](https://cli.github.com/)

#### macOS/Linux
```bash
# 安装Flutter (使用官方安装指南)
# 安装Git (通常已预装)
# 安装GitHub CLI
brew install gh  # macOS
# 或
sudo apt install gh  # Ubuntu/Debian
```

### 2. 配置GitHub Token

#### 创建Personal Access Token
1. 访问 [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. 点击 "Generate new token (classic)"
3. 选择以下权限：
   - `repo` (完整仓库访问权限)
   - `write:packages` (如果需要发布包)
4. 复制生成的Token

#### 设置环境变量
```bash
# Windows (PowerShell)
$env:GITHUB_TOKEN = "your_token_here"

# macOS/Linux
export GITHUB_TOKEN="your_token_here"

# 或者添加到 ~/.bashrc 或 ~/.zshrc
echo 'export GITHUB_TOKEN="your_token_here"' >> ~/.bashrc
```

### 3. 配置Git
确保Git已配置用户信息：
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## 🚀 使用方法

### Windows PowerShell
```powershell
# 基本用法
.\scripts\release.ps1 -Version "1.0.0"

# 带发布说明
.\scripts\release.ps1 -Version "1.0.0" -ReleaseNotes "首次发布版本"

# 创建预发布版本
.\scripts\release.ps1 -Version "1.1.0-beta.1" -Prerelease -ReleaseNotes "Beta测试版本"

# 创建草稿版本
.\scripts\release.ps1 -Version "2.0.0" -Draft -ReleaseNotes "重大更新"

# 指定GitHub Token
.\scripts\release.ps1 -Version "1.0.0" -GithubToken "your_token"
```

### Windows 批处理
```cmd
REM 简化用法
scripts\release.bat 1.0.0 "首次发布"
```

### macOS/Linux
```bash
# 基本用法
./scripts/release.sh -v 1.0.0

# 带发布说明
./scripts/release.sh -v 1.0.0 -n "首次发布版本"

# 创建预发布版本
./scripts/release.sh -v 1.1.0-beta.1 -p -n "Beta测试版本"

# 创建草稿版本
./scripts/release.sh -v 2.0.0 -d -n "重大更新"

# 指定GitHub Token
./scripts/release.sh -v 1.0.0 -t "your_token" -n "发布说明"
```

## 📝 参数说明

### PowerShell 脚本参数
- `-Version` (必需): 版本号，支持 `1.0.0` 或 `v1.0.0` 格式
- `-ReleaseNotes` (可选): 发布说明文本
- `-Prerelease` (开关): 标记为预发布版本
- `-Draft` (开关): 创建草稿版本
- `-GithubToken` (可选): GitHub Token，优先级高于环境变量

### Bash 脚本参数
- `-v, --version` (必需): 版本号
- `-n, --notes` (可选): 发布说明
- `-p, --prerelease` (开关): 预发布版本
- `-d, --draft` (开关): 草稿版本
- `-t, --token` (可选): GitHub Token
- `-h, --help`: 显示帮助信息

## 🔄 发布流程

脚本执行以下步骤：

1. **环境检查**
   - 验证Flutter、Git、GitHub CLI是否安装
   - 检查GitHub Token是否设置
   - 验证版本号格式

2. **项目信息获取**
   - 从pubspec.yaml读取项目名称
   - 从Git remote获取仓库信息

3. **版本更新**
   - 更新pubspec.yaml中的版本号
   - 提交版本更新到Git

4. **构建准备**
   - 清理之前的构建
   - 获取依赖包
   - 运行代码生成（如果需要）

5. **APK构建**
   - 构建Release APK
   - 支持多架构分包

6. **Git操作**
   - 提交版本更新
   - 创建版本标签
   - 推送到远程仓库

7. **GitHub Release**
   - 创建GitHub Release
   - 上传APK文件
   - 设置发布说明

## 📁 输出文件

构建完成后，APK文件位于：
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk
├── app-armeabi-v7a-release.apk
└── app-x86_64-release.apk
```

## ⚠️ 注意事项

### 1. 版本号规范
- 使用语义化版本号：`major.minor.patch`
- 支持预发布标识：`1.0.0-beta.1`
- 脚本会自动添加 `v` 前缀

### 2. 权限要求
- GitHub Token需要 `repo` 权限
- 确保对目标仓库有写入权限

### 3. 网络要求
- 需要稳定的网络连接
- 可能需要VPN（在某些地区）

### 4. 构建要求
- 确保Flutter项目可以正常构建
- 解决所有编译错误和警告

### 5. Git状态
- 确保工作目录干净（无未提交更改）
- 确保在正确的分支上

## 🐛 故障排除

### 常见错误及解决方案

#### 1. "Flutter未安装或不在PATH中"
```bash
# 检查Flutter安装
flutter --version

# 添加到PATH（Windows）
# 在系统环境变量中添加Flutter bin目录

# 添加到PATH（macOS/Linux）
export PATH="$PATH:/path/to/flutter/bin"
```

#### 2. "GitHub CLI未安装"
```bash
# Windows
winget install GitHub.cli

# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh
```

#### 3. "GitHub Token未设置"
```bash
# 设置环境变量
export GITHUB_TOKEN="your_token_here"

# 或使用GitHub CLI登录
gh auth login
```

#### 4. "APK构建失败"
```bash
# 清理并重新构建
flutter clean
flutter pub get
flutter build apk --release
```

#### 5. "Git推送失败"
```bash
# 检查远程仓库配置
git remote -v

# 检查认证
git config --list | grep user
```

## 🔧 自定义配置

### 修改构建类型
如果需要构建不同类型的APK，可以修改脚本中的构建命令：

```bash
# 单个APK文件
flutter build apk --release

# 分架构APK（默认）
flutter build apk --release --split-per-abi

# App Bundle
flutter build appbundle --release
```

### 添加签名配置
在 `android/app/build.gradle` 中配置签名：

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## 📚 相关文档

- [Flutter构建和发布](https://flutter.dev/docs/deployment)
- [GitHub CLI文档](https://cli.github.com/manual/)
- [GitHub Releases API](https://docs.github.com/en/rest/releases)
- [语义化版本规范](https://semver.org/)
