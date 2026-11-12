# 原生开屏 — Pictools 2.2

开屏是系统准备应用时的短暂过渡。延续首页的暖白 `#F7F6F2`、深墨 `#171B18` 与现有烧橙品牌，96pt/dp 图形居中。不增加引导、按钮、广告、倒计时或假进度；不人为延长启动。

## 平台落地

| 平台 | 实现 | 首帧交接 |
| --- | --- | --- |
| iOS | LaunchScreen.storyboard、96pt 图形、1×/2×/3× PNG、动态命名背景色 | Main.storyboard 使用同一背景，系统启动画面保留至 Flutter 首帧 |
| Android 11 及以前 | LaunchTheme + layer-list，96dp 矢量图形居中 | Flutter embedding 沿用已有 NormalTheme metadata，切换为同色纯背景 |
| Android 12+ | values-v31/LaunchTheme，windowSplashScreenBackground 与 windowSplashScreenAnimatedIcon | 使用系统进入／退出效果，不新增 Splash Activity 或 Flutter 开屏路由 |

Android 12+ 图标无额外背景板，容器 288dp，实际 96dp 标志完整位于直径 192dp 的系统安全圆内。图形使用 VectorDrawable，保持清晰。旧版与新版均使用 values-night 动态颜色，系统栏图标随系统外观切换。

本次采用直接维护原生资源的方案，不新增 flutter_native_splash 依赖。当前初始化已经在 runApp 前等待 Rust、设置与窗口初始化，原生启动窗口覆盖该阶段，因此无需额外 preserve/remove 或第二个 Flutter 启动页面。

## 自适应与主题边界

图形维持固定尺寸，按原生窗口约束居中；手机、小屏、横屏与展开窗口共享规则。系统启动页还未进入 Flutter，不能读取 Flutter 的折痕区域或应用主题设置。Android 12+ 的图标位置由系统决定；原生阶段不承诺绕开物理中缝。Flutter 首帧仍按已有窗口／折痕规则布局。

原生背景跟随系统外观。若用户在应用内选择与系统不同的主题，在首个 Flutter 页面生效，允许一次有意义的主题切换。启动不申请权限，也不需要网络。

## 设计与维护

[Figma 启动画板](https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=41-28434) 包含 10 个可编辑示例、Android 裁切安全区、交接说明和原型。版本：`Pictools 2.2 · 原生开屏与首帧交接`。图中的系统状态栏为说明，实际由 OS 绘制。

iOS 图形重建：`swift scripts/generate_launch_icon.swift`。Android 对应路径见 `res/drawable/launch_icon*.xml`。修改原生资源后应完整重建并冷启动；热重载无法验证系统缓存的启动快照。

验证记录和真实启动截图见 [QA 记录](../qa/launch/REVIEW.md)。

参考：[Flutter iOS launch screen](https://docs.flutter.dev/platform-integration/ios/launch-screen)、[Flutter Android splash screen](https://docs.flutter.dev/platform-integration/android/splash-screen)、[Android 系统开屏尺寸与生命周期](https://developer.android.com/develop/ui/views/launch/splash-screen)、[Apple 启动体验指南](https://developer.apple.com/design/human-interface-guidelines/launching)。
