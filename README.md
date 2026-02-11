# Personal Item Manager - 个人物品管理助手

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-green.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Dart-blue.svg" alt="Language">
  <img src="https://img.shields.io/badge/Framework-Flutter-blue.svg" alt="Framework">
  <img src="https://img.shields.io/github/license/Gan0819Han/Personal_Item_Manager" alt="License">
</p>

一款基于Flutter开发的智能个人物品管理应用，帮助您轻松记录、分类和管理日常物品。

## 🌟 核心功能

### 📸 智能拍照记录
- 一键拍照记录物品信息
- 自动图片压缩优化存储
- 支持本地相册选择

### 🏷️ 智能分类系统
- 预设多种物品分类
- **服饰类二级分类**（上衣、下装、内衣、配饰）
- 智能搜索建议匹配
- 自定义分类标签

### 💰 完善的信息管理
- 物品名称、价格记录
- 购入时间追踪
- 备注信息添加
- 新鲜度智能提醒

### 📊 数据可视化
- **近期好物**展示（最近5个物品）
- **热力图**统计（物品添加频率分析）
- 分类统计数据
- 时间维度分析

### 🔍 便捷搜索功能
- 全局模糊搜索
- 实时匹配结果
- 分类筛选查找

## 📱 应用截图

<div align="center">
  <img src="screenshots/home.png" width="200" alt="主页"/>  
  <img src="screenshots/add_item.png" width="200" alt="添加物品"/>
  <img src="screenshots/categories.png" width="200" alt="分类管理"/>
  <img src="screenshots/search.png" width="200" alt="搜索功能"/>
</div>

## 🚀 快速开始

### 📥 下载安装

1. 访问 [Releases](https://github.com/Gan0819Han/Personal_Item_Manager/releases) 页面
2. 下载最新版本的 APK 文件
3. 在Android设备上安装并授权必要权限

### 🎯 使用指南

#### 添加物品
1. 点击底部"+"按钮
2. 拍照或选择图片
3. 填写物品信息（名称、分类、价格等）
4. 点击"存入仓库"完成记录

#### 查看管理
- **侧边栏目录**：按分类浏览物品
- **全部物品**：查看所有记录
- **下拉刷新**：更新数据列表

#### 搜索查找
- 在"全部物品"页面使用搜索框
- 支持物品名称、分类模糊匹配

## 🛠 技术架构

### 开发技术栈
- **框架**：Flutter 3.x
- **语言**：Dart
- **状态管理**：原生 setState
- **数据存储**：SharedPreferences
- **图片处理**：image_picker + Base64编码

### 核心特性
- 📱 响应式UI设计
- 💾 本地数据持久化
- 🖼️ 图片压缩优化
- 🔒 数据隐私保护
- 🌓 Material Design风格

## 📁 项目结构

```
lib/
├── main.dart              # 主页面及路由
├── item_model.dart        # 数据模型定义
├── add_item_page.dart     # 添加物品页面
├── edit_item_page.dart    # 编辑物品页面
├── category_selector.dart # 分类选择组件
├── all_items_page.dart    # 全部物品页面
└── heatmap_page.dart      # 热力图统计页面
```

## 🔧 开发环境

### 环境要求
- Flutter SDK 3.0+
- Android Studio / VS Code
- Android SDK 21+

### 本地运行
```bash
# 克隆项目
git clone https://github.com/Gan0819Han/Personal_Item_Manager.git

# 获取依赖
flutter pub get

# 运行应用
flutter run
```

### 构建APK
```bash
# 构建发布版本
flutter build apk --release

# APK位置
build/app/outputs/flutter-apk/app-release.apk
```

## 🤝 贡献指南

欢迎提交Issue和Pull Request！

### 开发流程
1. Fork本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

### 代码规范
- 遵循Dart语言规范
- 使用有意义的变量命名
- 添加必要的代码注释
- 保持一致的代码风格

## 📄 开源协议

本项目采用 MIT License - 查看 [LICENSE](LICENSE) 文件了解更多详情

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 强大的跨平台开发框架
- [Material Design](https://material.io/) - 优秀的设计语言
- 所有贡献者和支持者

## 📞 联系方式

- **作者**：Gan0819Han
- **邮箱**：[您的邮箱]
- **GitHub**：[@Gan0819Han](https://github.com/Gan0819Han)

---

<p align="center">Made with ❤️ using Flutter</p>