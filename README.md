# Pictools

<p align="center">
  <img src="docs/icon.png" alt="Pictools Logo" width="128" height="128">
</p>

<p align="center">
  <strong>一款强大的图片工具集合桌面应用</strong>
</p>

<p align="center">
  <a href="#功能特性">功能特性</a> •
  <a href="#安装">安装</a> •
  <a href="#使用">使用</a> •
  <a href="#开发">开发</a> •
  <a href="#路线图">路线图</a>
</p>

---

## 功能特性

Pictools 是一个图片工具集合平台，提供多种实用的图片处理功能。

### 🔍 图片对比

快速对比两张图片的差异，支持三种对比模式：

- **滑块模式** - 拖动分割线左右对比
- **并排模式** - 两张图片左右并排显示  
- **叠加模式** - 可调节透明度查看叠加效果

### ✂️ 图片调整 (v1.1.0 新增)

强大的图片尺寸调整和裁剪工具：

- **尺寸调整** - 自定义宽高，支持锁定比例
- **比例裁剪** - 支持自由裁剪和预设比例（1:1, 4:3, 16:9 等）
- **多格式导出** - 支持 PNG、JPG、**WebP** 格式
- **高性能编码** - 使用 Rust 原生库进行图片编码，性能优异

<details>
<summary>📸 截图预览</summary>

<!-- 待添加截图 -->

</details>

## 安装

### macOS

1. 从 [Releases](https://github.com/haoqiangyu/pictools/releases) 下载最新版本的 `Pictools.zip`
2. 解压后将 `pictools.app` 拖入应用程序文件夹
3. 首次打开时，右键点击 → 选择"打开" → 确认打开

> ⚠️ 由于未进行 Apple 公证，首次打开可能需要在"系统设置 → 隐私与安全性"中允许运行

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/haoqiangyu/pictools.git
cd pictools

# 使用 fvm 安装 Flutter 版本
fvm use

# 获取依赖
fvm flutter pub get

# 运行开发版
fvm flutter run -d macos

# 构建发布版
fvm flutter build macos --release
```

> 💡 从源码构建需要安装 [Rust](https://rustup.rs/) 工具链

## 使用

1. **启动应用** - 打开 Pictools，进入工具集合首页
2. **选择工具** - 点击需要的工具卡片进入功能页面
3. **使用功能** - 按照各工具的指引完成操作
4. **返回首页** - 点击左上角返回按钮回到工具集合

### 图片对比使用

1. 上传两张待对比的图片（拖拽或点击上传）
2. 在底部选择对比模式（滑块/并排/叠加）
3. 在对比区域查看差异
4. 悬停图片可复制文件完整路径

### 图片调整使用

1. 上传待调整的图片
2. 选择调整模式（尺寸调整/比例裁剪）
3. 设置目标尺寸或裁剪区域
4. 选择导出格式（PNG/JPG/WebP）
5. 点击"导出图片"保存

## 开发

### 技术栈

- **框架**: Flutter 3.38.3
- **平台**: macOS
- **状态管理**: Provider
- **图片编码**: Rust (通过 flutter_rust_bridge)
- **依赖库**:
  - `file_picker` - 文件选择
  - `desktop_drop` - 拖拽上传
  - `image` - 图片解码处理
  - `flutter_rust_bridge` - Rust FFI 绑定

### 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
├── providers/                # 状态管理
├── screens/
│   ├── home_screen.dart      # 工具集合首页
│   ├── image_compare_screen.dart  # 图片对比
│   └── image_adjust_screen.dart   # 图片调整
├── src/rust/                 # Rust FFI 生成代码
├── theme/                    # 主题配置
└── widgets/                  # UI 组件

rust/
└── src/api/
    └── image_codec.rs        # Rust 图片编码模块
```

### 添加新工具

1. 在 `lib/models/tool_item.dart` 的 `Tools.all` 列表中添加新 `ToolItem`
2. 创建对应的功能页面（如 `lib/screens/xxx_screen.dart`）
3. 在 `lib/main.dart` 中添加路由配置

## 路线图

- [x] 🏠 工具集合入口首页
- [x] 🔍 图片对比功能
- [x] ✂️ 图片裁剪/缩放
- [x] 🖼️ 图片格式转换 (PNG/JPG/WebP)
- [ ] 🗜️ 图片压缩
- [ ] 🎨 批量处理
- [ ] 🪟 Windows 支持
- [ ] 🐧 Linux 支持

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

[MIT License](LICENSE)

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/haoqiangyu">haoqiangyu</a>
</p>
