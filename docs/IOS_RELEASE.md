# App Store 发布检查清单

## 当前 iOS 配置

- Bundle ID：`com.annuo.pictools`
- 最低系统版本：iOS 15.0
- 支持设备：iPhone 和 iPad
- 版本号由根目录 `pubspec.yaml` 的 `version` 字段提供。
- 图片编解码、裁剪缩放和亮度增强通过应用内置的 Rust 静态库执行。
- 主体抠图与多窗口仅在桌面端提供，iOS 不包含 ONNX Runtime 或抠图模型下载功能。
- 图片通过系统文件选择器读取和导出，不申请相册权限。

## 上传前检查

1. 在 `ios/Runner.xcworkspace` 中确认 Runner 的 Team 和签名证书属于用于发布的 Apple Developer 账号。
2. 在 Apple Developer 和 App Store Connect 中注册 `com.annuo.pictools`；如果该标识不可用，应同步修改 Xcode 中所有 Runner 配置。
3. 每次上传前递增 `pubspec.yaml` 中的 build number。
4. 执行 `flutter test`、`flutter analyze` 和 `flutter build ipa --release`。
5. 先上传 TestFlight，在真实 iPhone 和 iPad 上验证图片选择、处理、导出、取消导出及大图内存占用。
6. 确认公开隐私政策 `https://privacy.pictureslighting.com` 可从公网访问。

## 混淆构建

当前工作环境的 `flutter` 为 3.44.6，且 `pubspec.lock` 要求 Flutter ≥3.44.0；建议从仓库根目录直接执行 `flutter` 命令。先确认 `pubspec.yaml` 中的版本号和 App Store Connect 当前版本一致；如果这个版本号已经上传过，只递增 build number 即可，例如改为 `1.0.1+3`。

```bash
flutter doctor -v
flutter pub get
flutter test
flutter analyze

# 确保下面两个值与 pubspec.yaml / App Store Connect 一致，并且 build number 未使用过
IOS_VERSION=1.0.1
IOS_BUILD=2
SYMBOL_DIR="build/symbols/ios/${IOS_VERSION}+${IOS_BUILD}"
mkdir -p "$SYMBOL_DIR"

flutter build ipa \
  --release \
  --obfuscate \
  --split-debug-info="$SYMBOL_DIR" \
  --build-name="$IOS_VERSION" \
  --build-number="$IOS_BUILD"
```

成功后重点保留以下文件：

- IPA：`build/ios/ipa/Runner.ipa`
- Xcode 归档：`build/ios/archive/Runner.xcarchive`
- Dart 混淆符号：`build/symbols/ios/<版本+构建号>/`

`--obfuscate` 必须和 `--split-debug-info` 一起使用。混淆符号目录用于以后还原 Dart 崩溃堆栈，不能丢失，也不要提交到公开 Git 仓库。

## iOS 商店截图

现有 `docs/google-play/assets/screenshots/` 是 Android 截图，尺寸为 1080×1920，不能直接作为 iOS 截图。iOS 截图已使用当前开发机的 iPhone 17 Pro Max 和 iPad Pro 13-inch 模拟器生成，分别位于 `docs/app-store/screenshots/zh-CN/iphone-6.9/` 和 `docs/app-store/screenshots/zh-CN/ipad-13/`。

先构建模拟器包并安装：

```bash
flutter build ios --simulator --release

IPHONE_UDID="$(xcrun simctl list devices available | sed -nE '/iPhone 17 Pro Max/s/.*\(([A-F0-9-]{36})\).*/\1/p')"
xcrun simctl boot "$IPHONE_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$IPHONE_UDID" -b
open -a Simulator
xcrun simctl install "$IPHONE_UDID" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$IPHONE_UDID" com.annuo.pictools
mkdir -p docs/app-store/screenshots/zh-CN/iphone-6.9
```

在模拟器里进入目标页面后，逐张执行截图命令：

```bash
xcrun simctl io "$IPHONE_UDID" screenshot \
  docs/app-store/screenshots/zh-CN/iphone-6.9/01-toolbox.png
```

建议截图顺序：工具箱首页、图片对比、尺寸调整/裁剪、亮度增强、格式转换、设置、语言选择。iPad 截图可使用以下命令启动同一个模拟器包：

```bash
IPAD_UDID="$(xcrun simctl list devices available | sed -nE '/iPad Pro 13-inch/s/.*\(([A-F0-9-]{36})\).*/\1/p')"
xcrun simctl boot "$IPAD_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$IPAD_UDID" -b
open -a Simulator
xcrun simctl install "$IPAD_UDID" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$IPAD_UDID" com.annuo.pictools
mkdir -p docs/app-store/screenshots/zh-CN/ipad-13
xcrun simctl io "$IPAD_UDID" screenshot \
  docs/app-store/screenshots/zh-CN/ipad-13/01-toolbox.png
```

截图应使用真实界面，不要把 Android 状态栏或导航栏合成进去。其他语言最好在对应系统/应用语言下重新截取，至少保证截图中的文字和该商店语言一致。

## 上传与审核

1. 打开 `ios/Runner.xcworkspace`，确认 Runner 的 Team、Bundle ID `com.annuo.pictools` 和 Release 签名正确。
2. 用上面的 `flutter build ipa` 生成归档。
3. 打开 Xcode Organizer（`open build/ios/archive/Runner.xcarchive`），选择 **Distribute App → App Store Connect → Upload**；也可以用 Transporter 上传 `build/ios/ipa/Runner.ipa`。
4. 等待 App Store Connect 完成处理，把构建分配到 TestFlight，先在真实 iPhone 和 iPad 上验证导入、处理、导出和大图内存占用。
5. 在商店页面填写 [`docs/app-store/README.md`](app-store/README.md) 中的基础资料，并按语言目录上传名称、副标题、描述、关键词和更新说明。
6. 上传对应的 iPhone/iPad 截图，填写 App Privacy、年龄分级和出口合规问卷，确认隐私政策网址可公开访问后再提交审核。

如果自动签名失败，先在 Xcode 中修正 Team 和 provisioning profile，再回到仓库根目录重新执行构建；不要使用 `--no-codesign` 生成用于上传的 IPA。

## App Store Connect

- 可直接粘贴的多语言商店名称、副标题、描述、关键词和版本更新文案见 [`docs/app-store/README.md`](app-store/README.md)。
- 填写名称、副标题、描述、关键词、分类、年龄分级、支持网址、隐私政策网址和版权信息。
- 上传符合当前界面的 iPhone 截图；保留 iPad 支持时也要上传并验证 iPad 截图。
- 按最终发布包的实际行为填写 App Privacy。当前版本不含广告、分析或追踪 SDK，不收集或上传用户图片及个人数据。
- 完成加密出口合规问卷。应用只使用系统及网络库的标准加密能力，不包含自研加密算法。
