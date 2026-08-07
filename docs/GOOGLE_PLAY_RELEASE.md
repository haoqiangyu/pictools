# Google Play 发布检查清单

## 功能范围

Android 版提供图片对比、图片调整、Rust 亮度增强和格式转换。
主体抠图与多窗口仅在桌面端提供。Android 不下载 RMBG-2.0 模型；亮度增强和图片编解码通过应用内置的 Rust 动态库在设备本地执行。

## 权限与数据

- 正式版不声明 `INTERNET`、照片、媒体或全盘存储权限。
- 图片通过 Android 系统文件选择器读取和保存，不申请照片、媒体或全盘存储权限。
- 图片处理均在设备本地完成，应用没有自有服务器，不收集、上传、出售或共享图片及个人数据。
- 仅使用 `SharedPreferences` 在设备本地保存用户选择的界面语言。
- 应用不集成广告、分析或追踪 SDK。

应用内隐私政策位于“设置 → 隐私政策”。公开隐私政策地址为：

https://privacy.pictureslighting.com

在 Google Play Console 的 Data safety 表单中按“不收集数据”如实填写。

## 上传签名

1. 上传密钥库已生成在项目外部，请妥善离线备份密钥库和恢复信息。
2. `android/key.properties` 已配置实际密钥路径和密码，仅保存在本机。
3. 不要提交 `key.properties`、`.jks` 或 `.keystore` 文件；它们已被 Git 忽略。
4. 执行 `flutter build appbundle --release`。
5. 上传 `build/app/outputs/bundle/release/app-release.aab`，并启用 Play App Signing。

## 上架前人工项

- 确认 `applicationId` `com.annuo.pictools` 在 Play Console 中可用且为最终标识。
- 当前版本名为 `1.0.1`，build number 为 `2`。
- 每次发布递增 `pubspec.yaml` 的 build number。
- 隐私政策 URL、商店截图、512 × 512 应用图标和 1024 × 500 功能图片已就绪，位于 `docs/google-play/`。
- 六种语言的商店标题、简短说明和完整说明已就绪；内容分级问卷仍需由账号持有人在 Play Console 中确认提交。
- 已使用真实上传签名构建 AAB；仍需在 Play Console 内部测试轨道完成安装测试。
- 在至少一台低内存 Android 设备和一台近期 Android 设备上验证大图处理。
