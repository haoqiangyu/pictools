# App Store 发布检查清单

## 当前 iOS 配置

- Bundle ID：`com.annuo.pictools`
- 最低系统版本：iOS 13.0
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

## App Store Connect

- 填写名称、副标题、描述、关键词、分类、年龄分级、支持网址、隐私政策网址和版权信息。
- 上传符合当前界面的 iPhone 截图；保留 iPad 支持时也要上传并验证 iPad 截图。
- 按最终发布包的实际行为填写 App Privacy。当前版本不含广告、分析或追踪 SDK，不收集或上传用户图片及个人数据。
- 完成加密出口合规问卷。应用只使用系统及网络库的标准加密能力，不包含自研加密算法。
