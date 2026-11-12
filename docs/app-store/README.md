# App Store 上架资料

日常发布请使用 [双商店 Fastlane 自动化](../STORE_AUTOMATION.md)。自动同步文案以 `fastlane/metadata/*.json` 和 `fastlane/release_notes/<版本号>.json` 为准；本文的 `listing/` 是此前的手动填写资料。

## 审核补充信息

针对要求提供真机录屏及六项应用说明的审核通知，见 [审核补充材料与录屏脚本](review/README-zh-CN.md) 和 [英文审核回复 / Notes 正文](review/review-information-en.txt)。提交时须附上实际送审构建的真机录屏。

## 建议的基础设置

- 主要语言：简体中文（当前代码和现有商店资料均以简体中文为默认语言）
- Bundle ID：`com.annuo.pictools`
- 应用名称：各语言版本见 `listing/` 目录
- 主类别：照片与视频（Photo & Video）
- 副类别：工具（Utilities，可选）
- 年龄分级：4+（仍需按 App Store Connect 问卷实际提交）
- 隐私政策网址：<https://privacy.pictureslighting.com>
- 支持网址：保留 App Store Connect 后台现值
- 营销网址：可留空
- 版权：保留 App Store Connect 后台现值

## 本地化版本

每个语言目录中的 `listing.txt` 都包含：应用名称、副标题、宣传文本、描述、关键词和“新功能”。

- `zh-CN`：简体中文，建议作为主要语言
- `zh-TW`：繁体中文
- `en-US`：English (U.S.)
- `es-ES`：西班牙语
- `fr-FR`：法语
- `de-DE`：德语

## 当前设计的商店截图

使用 [2026-11-11 多语言商店素材](../store-assets/2026-11-11/README.md)，包含卖点标题、品牌构图和对应语言的真实应用界面。

- iPhone Dynamic Island 中等屏幕（`1179 × 2556`）：每种语言 8 张。
- iPad 13 英寸横屏（`2752 × 2064`）：每种语言 4 张。
- 覆盖简体、繁体、英语、西班牙语、法语、德语，目录为 `docs/store-assets/2026-11-11/upload/语言/app-store/`。
- [按语言浏览成品](../store-assets/2026-11-11/index.html)；原 `screenshots/zh-CN/` 仅保留为旧版设计资料。

## 提交前注意事项

- App Store Connect 的主要语言是商店元数据的默认语言，不会限制 App 内语言。App 内目前支持简体中文、繁体中文、英语、西班牙语、法语和德语。
- 不要直接复制 Google Play 文案中的 Android 专属内容，例如“Android 版不申请网络权限”。iOS 文案已按设备本地处理和系统文件选择器重新整理。
- 使用新素材目录中对应语言的 `app-store/` 内容。Google Play 素材来自独立 Android 采集，不混用于 iOS。
- “新功能”内容适用于当前 `pubspec.yaml` 的 `1.0.1+2` 首发资料；正式上传新版本时请按实际改写。
