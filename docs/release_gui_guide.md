# 🎨 Flutter APK Release GUI 工具使用指南

## 📋 概述

这是一个带有图形界面的Flutter APK发布工具，可以自动化完成从构建到发布的整个流程。

## ✨ 功能特性

- 🎨 **友好的图形界面** - 无需命令行操作
- 🔧 **环境自动检查** - 自动检测Flutter、Git等工具
- 📱 **自动构建APK** - 支持多架构分包构建
- 🏷️ **版本管理** - 自动更新版本号和创建Git标签
- 🚀 **GitHub集成** - 自动创建Release并上传APK
- 💾 **配置保存** - 保存常用配置，下次使用更便捷
- 📊 **实时日志** - 详细的操作日志和进度显示

## 🛠️ 安装要求

### 必需软件
- **Python 3.6+** - [下载地址](https://www.python.org/downloads/)
- **Flutter SDK** - [安装指南](https://flutter.dev/docs/get-started/install)
- **Git** - [下载地址](https://git-scm.com/downloads)

### Python依赖
工具会自动安装所需的Python库：
- `tkinter` (通常随Python安装)
- `requests` (自动安装)

## 🚀 快速开始

### 1. 启动工具

#### Windows
```cmd
# 双击运行
scripts\run_release_gui.bat

# 或者直接运行Python脚本
python scripts\release_gui.py
```

#### macOS/Linux
```bash
# 运行启动脚本
./scripts/run_release_gui.sh

# 或者直接运行Python脚本
python3 scripts/release_gui.py
```

### 2. 配置信息

#### 项目路径
- 选择Flutter项目的根目录（包含pubspec.yaml的目录）
- 默认为当前目录

#### GitHub Token
1. 点击"获取"按钮打开GitHub Token页面
2. 创建Personal Access Token
3. 选择`repo`权限
4. 复制Token并粘贴到输入框

#### 版本号
- 输入新版本号，如：`1.0.0`、`1.2.3-beta.1`
- 支持语义化版本号格式

#### 发布说明
- 输入本次发布的更新内容
- 支持Markdown格式
- 如果为空，将使用"自动发布"

#### 发布选项
- **预发布版本**：标记为Pre-release
- **草稿版本**：创建草稿Release（不会立即发布）

### 3. 执行发布

1. 点击"检查环境"确保所有工具已安装
2. 点击"保存配置"保存当前设置
3. 点击"开始发布"启动发布流程
4. 在确认对话框中点击"是"
5. 等待发布完成

## 📊 发布流程

工具将按以下步骤执行：

1. **环境检查** ✅
   - 验证Flutter、Git是否安装
   - 检查项目结构

2. **输入验证** ✅
   - 验证GitHub Token
   - 验证版本号格式

3. **版本更新** 📝
   - 更新pubspec.yaml中的版本号

4. **构建准备** 🧹
   - 执行`flutter clean`
   - 执行`flutter pub get`
   - 运行代码生成（如果需要）

5. **APK构建** 🔨
   - 执行`flutter build apk --release --split-per-abi`
   - 生成多架构APK文件

6. **Git操作** 📤
   - 提交版本更新
   - 创建版本标签
   - 推送到远程仓库

7. **GitHub Release** 🚀
   - 创建GitHub Release
   - 上传APK文件
   - 设置发布说明

## 🎯 界面说明

### 主要区域

1. **配置区域**（顶部）
   - 项目路径选择
   - GitHub Token输入
   - 版本号设置
   - 发布说明编辑

2. **选项区域**（中部）
   - 预发布版本选项
   - 草稿版本选项

3. **操作区域**（中部）
   - 检查环境按钮
   - 保存配置按钮
   - 开始发布按钮
   - 清空日志按钮

4. **状态区域**（中下部）
   - 进度条显示
   - 当前状态文本

5. **日志区域**（底部）
   - 详细的操作日志
   - 彩色状态标识
   - 可滚动查看

### 状态指示

- ✅ **绿色** - 成功操作
- ❌ **红色** - 错误信息
- ⚠️ **橙色** - 警告信息
- ℹ️ **蓝色** - 一般信息

## 💾 配置管理

### 自动保存
工具会自动保存以下配置到`scripts/config.json`：
- GitHub Token
- 项目路径
- 版本号
- 发布说明
- 发布选项

### 手动保存
点击"保存配置"按钮可以手动保存当前设置。

### 配置文件位置
```
scripts/
└── config.json  # 配置文件（已添加到.gitignore）
```

## 🔧 故障排除

### 常见问题

#### 1. "Python未安装"
**解决方案**：
- 下载并安装Python 3.6+
- 确保Python已添加到系统PATH

#### 2. "Flutter未安装或不在PATH中"
**解决方案**：
- 安装Flutter SDK
- 将Flutter bin目录添加到PATH
- 重启终端/命令提示符

#### 3. "Git未安装或不在PATH中"
**解决方案**：
- 安装Git
- 确保Git已添加到系统PATH

#### 4. "GitHub Token无效"
**解决方案**：
- 检查Token是否正确复制
- 确保Token具有`repo`权限
- 检查Token是否已过期

#### 5. "APK构建失败"
**解决方案**：
- 检查Flutter项目是否可以正常构建
- 运行`flutter doctor`检查环境
- 解决所有编译错误

#### 6. "Git推送失败"
**解决方案**：
- 检查Git仓库配置
- 确保有推送权限
- 检查网络连接

### 调试技巧

1. **查看详细日志**
   - 日志区域显示所有操作的详细信息
   - 错误信息会以红色显示

2. **分步执行**
   - 先点击"检查环境"确保基础环境正常
   - 逐步解决发现的问题

3. **手动验证**
   - 可以手动执行Flutter命令验证环境
   - 检查Git仓库状态

## 🔒 安全注意事项

1. **GitHub Token安全**
   - 不要分享您的GitHub Token
   - 定期更新Token
   - 只授予必要的权限

2. **配置文件**
   - `config.json`包含敏感信息
   - 已自动添加到`.gitignore`
   - 不要提交到版本控制

3. **网络安全**
   - 确保网络连接安全
   - 使用HTTPS连接GitHub

## 📚 相关资源

- [Flutter官方文档](https://flutter.dev/docs)
- [GitHub API文档](https://docs.github.com/en/rest)
- [Git官方文档](https://git-scm.com/doc)
- [Python官方文档](https://docs.python.org/3/)

## 🆘 获取帮助

如果遇到问题：

1. 查看日志区域的错误信息
2. 参考本文档的故障排除部分
3. 检查相关工具的官方文档
4. 确保所有依赖工具都已正确安装

## 🎉 使用技巧

1. **首次使用**
   - 先点击"检查环境"确保一切正常
   - 保存配置以便下次使用

2. **批量发布**
   - 可以快速修改版本号进行多次发布
   - 使用草稿模式先创建Release再发布

3. **测试发布**
   - 使用预发布选项进行测试
   - 先在测试仓库中验证流程

4. **版本管理**
   - 遵循语义化版本号规范
   - 为重要版本添加详细的发布说明
