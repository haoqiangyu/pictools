# Google Play 图片素材

| 素材 | 文件 | 尺寸 | 用途 |
| --- | --- | --- | --- |
| 商店图标 | `assets/store-icon.png` | 512 × 512 | Google Play 应用图标 |
| 功能图片 | `assets/feature-graphic.png` | 1024 × 500 | 商店功能图片 |
| 手机截图 1 | `assets/screenshots/zh-CN/01-toolbox.png` | 1080 × 1920 | 首页与工具集合 |
| 手机截图 2 | `assets/screenshots/zh-CN/02-rust-enhance.png` | 1080 × 1920 | 亮度增强前后对比 |
| 手机截图 3 | `assets/screenshots/zh-CN/03-resize-crop.png` | 1080 × 1920 | 图片调整 |
| 手机截图 4 | `assets/screenshots/zh-CN/04-format-convert.png` | 1080 × 1920 | 格式转换 |
| 手机截图 5 | `assets/screenshots/zh-CN/05-local-privacy.png` | 1080 × 1920 | 本地处理与隐私政策 |
| 手机截图 6 | `assets/screenshots/zh-CN/06-languages.png` | 1080 × 1920 | 语言和设置 |

截图来自 Android 14 实体设备上的正式签名 release 构建。商店版截图移除了系统状态栏和导航栏，并在不修改应用界面的前提下增加标题区与统一边框。

运行 `python3 docs/google-play/generate_assets.py` 可从 `assets/raw/` 重新生成全部图片素材。
