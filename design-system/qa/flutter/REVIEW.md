# Pictools Studio — Flutter 实现记录

日期：2026-11-10。设计基线为 [Mobile 2.0](https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=13-606)、仓库内 MASTER 与 foldable 交付稿。本轮 Figma 读取遇到 Starter 配额限制，因此使用此前从同一文件导出的设计图、原型记录与正式图标资产完成实现。

## 已实现

- 首页四工具、相册/文件导入来源、当前会话入口、设置与隐私页面；暖白/深色/跟随系统主题，六种语言。
- 裁剪与尺寸共用画布：八种比例、归一化裁剪、精确移动/尺寸辅助操作、锁定比例、像素上限校验。
- 对比支持滑块、并排、叠加、缩放与重置；滑块另有可读数值、系统辅助功能和按钮操作。不同尺寸保持原比例，不宣称自动配准。
- 增强调用实际处理引擎，有处理中、失败重试、结果比较和导出；替换图片时旧任务不能覆盖新会话。
- 统一导出提供 PNG/JPEG/WebP/BMP/ICO/TIFF、JPEG/WebP 质量、WebP 无损、JPEG 背景填充、ICO 缩小副本确认、文件名校验、保存与系统分享。取消保存保留结果，不显示已保存。
- 批量队列由应用级 Provider 持有，顺序处理、逐项失败/重试、保留已完成项、停止剩余任务、逐项保存与移除。处理中离开页面不会丢失队列。完成项保留处理时的格式设置。
- iOS/Android/macOS 应用图标更新；Android 包含自适应图标与单色层。生产包只包含品牌图标，示例照片仅用于测试。
- 桌面端窗口分离、应用内图片复制/粘贴入口保留；原桌面主体抠图功能保持独立深色主题。

会话保存在运行中的 Provider，未实现持久化草稿库。退出编辑时可保留本次会话或丢弃。文件选择与导出均经系统界面；原始文件不会由处理流程覆盖。

导入按内容验证，单文件最多 80 MB、16384 px 单边与 48 MP。TIFF/ICO 先转换成可预览的 PNG 数据；多帧图片需确认使用首帧。批量源文件最多 50 张/200 MB，内存中的结果最多 128 MB，超限可先保存并移除完成项。HEIC、AVIF、RAW 等不宣称普遍支持；系统相册可提供兼容表示，仍无法解码时显示重新选择提示。

## 手机与折叠屏

`lib/layout/` 按当前 Flutter view 的可用范围、安全区、键盘和活动折叠区域计算布局，没有设备型号判断，也没有产品内的姿态切换器。窄屏上下布局；可读宽度足够时采用画布+检查器；短横屏与较宽窗口使用侧边动作。原生侧边安全区内不绘制应用按钮、时间、摄像头或 Home 指示条。

书本姿态在两侧排布画布/参数；桌面半折叠使用上下区域，内容不跨折叠保留区。键盘占据下半区时把操作面板放入仍可用的上半区；极小预览不保留拖拽手柄。输入控制器、焦点、裁剪坐标、比较位置、画布状态与导出弹层在重新排布时保留。

Android 使用 Flutter `MediaQuery.displayFeatures`。iOS 增加 `pictools/window_geometry` 桥接，使用当前引擎视图的 bounds、安全区及前台几何更新。`PICTOOLS_DUO_SDK` 在 **27.1 SDK** 构建条件下启用 `reservedRegions(kind: .division/.occlusion)` 分支；使用其他后续 SDK 时需重新核对 API 后配置相应构建条件。

**本机是 Xcode 26.6 / iOS 26.5 模拟器。** 已验证当前 SDK 的桥接与回退、Dart 侧折叠区域布局及状态迁移；27.1 分支未在本机编译，也没有 iPhone Duo 真机折叠验证。示例 466×678、951×669、72 px 安全区、32/48 px 折叠区都是测试夹具，不是设备参数常量。发布 Duo 完整屏幕版本仍需用 27.1 SDK 编译并在设备上验证原生保留区、旋转、系统选择器与分享面板。

参考：[Apple 适配说明](https://developer.apple.com/videos/play/tech-talks/111461/)、[Apple 姿态与保留区](https://developer.apple.com/videos/play/tech-talks/111463/)、[Flutter displayFeatures](https://api.flutter.dev/flutter/widgets/MediaQueryData/displayFeatures.html)。

## 验证

| 检查 | 结果 |
|---|---|
| `flutter analyze` / `git diff --check` | 通过 |
| `flutter test` | 46 个测试通过 |
| 布局矩阵 | 21 组几何 × 6 个页面，另含 5 种语言的 320 px / 2 倍字体 |
| 编辑状态迁移 | 展开/旋转保留裁剪、尺寸、焦点、比较缩放/位置及导出文件名 |
| 数据与状态 | 内容检测、TIFF 预览、JPEG 透明合成、ICO 预检、裁剪/尺寸、批量取消/重试、保存取消、旧增强任务隔离 |
| iOS 模拟器集成测试 | 六种格式真实编码、JPEG 质量差异、WebP 无损、亮度增强、编辑→导出、原生窗口几何均通过 |
| iOS debug 模拟器构建 | 通过，已安装启动核对首页 |
| Android XML/图标资源 | `aapt2 compile` 通过 |
| Android APK | 未完成：Gradle 8.14.3 分发下载出现 TLS 错误；尝试官方直链仍超时。使用本机缓存 Gradle 8.14 离线验证又遇到缺少依赖，未改项目版本绕过。 |

普通尺寸包含 320×568、360×740、390×844、430×932、740×360、844×390、852×393、932×430、768×1024、1366×768、1400×900；另覆盖 Duo 外屏、横/竖内屏、左右安全区、分屏、书本/桌面姿态与键盘。

`phone-*`、`duo-*`、`book-*`、`tabletop-*` 为 Flutter widget 实际渲染，使用测试图像和注入几何。截图测试只在审阅渲染中加载本机字体，避免测试默认 Ahem 方块字；普通回归测试不替换字体。`ios-native-home.png` 是实际 iOS 模拟器截图。短横屏以 2× 像素密度导出，逻辑尺寸仍为 852×393。

视觉启发式检查 `smoke-report.json`：0 fail。非标准视口警告对应 iOS 原生像素截图、短横屏 2× 截图及预览拼版；低中间色比例警告对应有意保留的暖白页面、深色画布和键盘缩略预览，已人工核对文字、边界和操作可见性。该检查不能替代 Duo 真机验证。

## 复现

```sh
flutter analyze
flutter test
flutter test integration_test/studio_native_test.dart -d <iOS-simulator-id>
flutter build ios --simulator --debug --no-codesign
flutter build apk --debug
```

截图：设置 `STUDIO_QA_FONT` 为本机可用 CJK 字体，执行 `flutter test test/studio/studio_layout_test.dart --dart-define=STUDIO_CAPTURE=true`。截图测试从应用资产包加载 Material Icons，不需要修改 Flutter 安装路径。截图与源设计位于同一 `design-system/qa/` 树中，便于逐屏复核。
