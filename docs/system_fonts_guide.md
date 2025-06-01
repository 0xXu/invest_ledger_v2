# 系统默认字体使用指南

## 概述

本应用已配置为使用操作系统默认字体，而不是 Google Fonts。这样做有以下优势：

- 🚀 **更快的启动速度**：无需下载字体文件
- 💾 **更小的应用体积**：减少字体文件的打包
- 🎨 **原生体验**：与操作系统界面保持一致
- 🌐 **离线友好**：无需网络连接即可正常显示
- 🔧 **维护简单**：无需管理字体版本和更新

## 各平台默认字体

Flutter 会根据运行平台自动选择最佳的系统字体：

### iOS / iPadOS
- **主字体**: San Francisco (SF Pro)
- **特点**: Apple 设计的现代无衬线字体
- **优势**: 在各种尺寸下都有出色的可读性

### Android
- **主字体**: Roboto
- **特点**: Google 设计的 Material Design 字体
- **优势**: 专为数字屏幕优化

### Windows
- **主字体**: Segoe UI
- **特点**: Microsoft 的系统界面字体
- **优势**: 在 Windows 环境下提供最佳体验

### macOS
- **主字体**: San Francisco (SF Pro)
- **特点**: 与 iOS 相同的字体系列
- **优势**: 跨 Apple 设备的一致体验

### Linux
- **主字体**: Ubuntu / Cantarell (取决于发行版)
- **特点**: 开源字体，针对屏幕显示优化
- **优势**: 符合各 Linux 发行版的设计语言

## 技术实现

### 主题配置

```dart
class AppTheme {
  // 使用 null 让 Flutter 自动选择系统字体
  static const String? _systemFontFamily = null;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: _systemFontFamily, // 系统默认字体
    // 其他配置...
  );
}
```

### 文本样式

所有文本样式都使用标准的 `TextStyle`，不指定特定字体：

```dart
// ✅ 推荐：使用系统默认字体
const TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
)

// ❌ 避免：指定特定字体
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  fontFamily: 'SpecificFont', // 不推荐
)
```

## Material Design 3 字体规范

应用遵循 Material Design 3 的字体层次结构：

### Display 层次
- **Display Large**: 57sp, Regular
- **Display Medium**: 45sp, Regular  
- **Display Small**: 36sp, Regular

### Headline 层次
- **Headline Large**: 32sp, Regular
- **Headline Medium**: 28sp, Regular
- **Headline Small**: 24sp, Regular

### Title 层次
- **Title Large**: 22sp, Regular
- **Title Medium**: 16sp, Medium
- **Title Small**: 14sp, Medium

### Body 层次
- **Body Large**: 16sp, Regular
- **Body Medium**: 14sp, Regular
- **Body Small**: 12sp, Regular

### Label 层次
- **Label Large**: 14sp, Medium
- **Label Medium**: 12sp, Medium
- **Label Small**: 11sp, Medium

## 字体权重使用指南

### 常用权重
- **FontWeight.w400 (Regular)**: 正文内容
- **FontWeight.w500 (Medium)**: 标签、按钮
- **FontWeight.w600 (SemiBold)**: 小标题
- **FontWeight.w700 (Bold)**: 重要标题

### 应用中的使用
```dart
// 页面标题
TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
)

// 卡片标题
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
)

// 正文内容
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
)

// 辅助信息
TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: Colors.grey[600],
)
```

## 响应式字体大小

### 基础尺寸
- **小屏幕** (< 600dp): 标准尺寸
- **中等屏幕** (600-840dp): 增加 10%
- **大屏幕** (> 840dp): 增加 20%

### 实现示例
```dart
double getResponsiveFontSize(BuildContext context, double baseSize) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (screenWidth > 840) {
    return baseSize * 1.2; // 大屏幕
  } else if (screenWidth > 600) {
    return baseSize * 1.1; // 中等屏幕
  }
  return baseSize; // 小屏幕
}
```

## 可访问性考虑

### 字体大小
- 支持系统字体缩放设置
- 最小字体大小不低于 12sp
- 重要信息使用较大字体

### 对比度
- 确保文字与背景有足够对比度
- 浅色主题：深色文字 + 浅色背景
- 深色主题：浅色文字 + 深色背景

### 字体权重
- 重要信息使用较粗字体
- 避免过细字体影响可读性

## 最佳实践

### 1. 保持一致性
- 在整个应用中使用统一的字体层次
- 相同功能的元素使用相同的文本样式

### 2. 语义化使用
- 根据内容重要性选择合适的字体层次
- 标题使用 Headline，正文使用 Body

### 3. 性能优化
- 避免频繁创建 TextStyle 对象
- 使用主题中预定义的样式

### 4. 测试验证
- 在不同平台上测试字体显示效果
- 验证各种字体大小设置下的可读性

## 迁移说明

从 Google Fonts 迁移到系统字体的步骤：

1. ✅ 移除 `google_fonts` 依赖
2. ✅ 更新主题配置使用系统字体
3. ✅ 替换所有 `GoogleFonts.xxx()` 调用
4. ✅ 验证各平台显示效果
5. ✅ 更新文档和注释

## 故障排除

### 字体显示异常
- 检查是否正确移除了 Google Fonts 引用
- 确认 `fontFamily` 设置为 `null`
- 重启应用以应用新的字体设置

### 样式不一致
- 检查是否所有 TextStyle 都移除了特定字体
- 确认主题配置正确应用
- 验证不同组件的字体继承关系

通过使用系统默认字体，应用将在各个平台上提供更加原生和一致的用户体验。
