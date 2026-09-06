# App Store 上架资料

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
- 支持网址：<https://github.com/haoqiangyu/pictools/issues>
- 营销网址：可留空
- 版权：填写开发者或公司法定名称，例如 `© 2026 开发者名称`

## 本地化版本

每个语言目录中的 `listing.txt` 都包含：应用名称、副标题、宣传文本、描述、关键词和“新功能”。

- `zh-CN`：简体中文，建议作为主要语言
- `zh-TW`：繁体中文
- `en-US`：English (U.S.)
- `es-ES`：西班牙语
- `fr-FR`：法语
- `de-DE`：德语

## 已生成截图

- iPhone 6.9-inch（`1320 × 2868`）：`screenshots/zh-CN/iphone-6.9/`
- iPad 13-inch（`2064 × 2752`）：`screenshots/zh-CN/ipad-13/`

当前截图为简体中文界面，展示工具箱、图片对比、图片调整、亮度增强、格式转换、设置和语言选择。

## 提交前注意事项

- App Store Connect 的主要语言是商店元数据的默认语言，不会限制 App 内语言。App 内目前支持简体中文、繁体中文、英语、西班牙语、法语和德语。
- 不要直接复制 Google Play 文案中的 Android 专属内容，例如“Android 版不申请网络权限”。iOS 文案已按设备本地处理和系统文件选择器重新整理。
- iOS 截图已经生成在 `screenshots/zh-CN/`；现有 `docs/google-play/assets/screenshots/` 仍是 Android 资料，不能直接当作 iOS 截图提交。
- “新功能”内容适用于当前 `pubspec.yaml` 的 `1.0.1+2` 首发资料；正式上传新版本时请按实际改写。
