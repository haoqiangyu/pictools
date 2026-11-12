# Pictools 商店视觉素材 · 2026-11-11

已根据当前 Studio 设计和 Flutter 实现制作多语言商店展示图。真实应用界面配合品牌配色、卖点标题、画面构图和裁剪标记；没有伪造界面、评价、排名、AI 功能或处理效果。

## 交付内容

每种语言各有 24 张截图和 1 张 Google Play 宣传图。覆盖简体中文 `zh-CN`、繁体中文 `zh-TW`、英语 `en-US`、西班牙语 `es-ES`、法语 `fr-FR`、德语 `de-DE`。

| 上传位置 | 每种语言数量 | 像素尺寸 | 文件位置（ZIP 内） |
|---|---:|---|---|
| App Store · iPhone Dynamic Island 中等屏幕 | 8 | 1179 × 2556 | 语言/app-store/iphone-dynamic-island-medium/ |
| App Store · iPad 13 英寸 | 4 | 2752 × 2064 | 语言/app-store/ipad-13/ |
| Google Play · 手机 | 8 | 1080 × 1920 | 语言/google-play/phone/ |
| Google Play · 平板 | 4 | 1920 × 1080 | 语言/google-play/tablet/ |
| Google Play · Feature graphic | 1 | 1024 × 500 | 语言/google-play/feature/ |

合计 **144 张截图 + 6 张宣传图**，另附当前品牌的 App Store 1024 × 1024 和 Google Play 512 × 512 图标。截图与宣传图为无透明通道 RGB PNG；Play 图标为 32-bit RGBA PNG。

## 怎么使用

- 打开本目录 `index.html`，切换语言与平台浏览，点击图片查看完整尺寸。
- 直接上传 `upload/` 中相应语言、平台、设备目录的 PNG，按文件名前的数字排序。不要把 QA 联系表或原始截图当作上传素材。
- `Pictools-app-store-6-languages.zip` 和 `Pictools-google-play-6-languages.zip` 分别供两端使用；`Pictools-all-6-languages.zip` 包含全部成品。
- `captions-and-alt-text.csv` 提供每张图的标题、副文案、排序和对应语言的 Google Play 替代文本。
- 商店的地区语言名称可能不同：App Store 繁体中文选择 Traditional Chinese；Google Play 选择对应的 zh-TW 本地化。素材语言不代表已经配置商店分发地区。

## 卖点与顺序

1. **裁剪到位，尺寸刚好**：用实际裁剪工作台展示选定比例、生成副本。
2. **差别，一眼看清**：滑块、并排、叠加三种对比方式。
3. **批量转换，少些重复操作**：展示三张已完成转换的图片、六种输出格式与质量控件。
4. **让暗处，亮起来**：展示应用真实亮度增强算法的结果。
5. **想要的尺寸，精确到像素**：宽高与锁定比例。
6. **相册、文件，都能轻松导入**：展示两种真实导入入口。
7. **保存去哪，由你决定**：明确 PNG/JPG 可到相册、全部格式可到文件，生成副本并保留原图。
8. **白天与夜晚，都看得舒服**：展示真实深色编辑界面。

App Store 的顺序为裁剪、对比、批量、提亮、尺寸、导入、保存、深色；Google Play 则为批量、裁剪、对比、尺寸、提亮、导入、保存、深色，突出批量转换用途。iPad 展示裁剪、对比、批量与导出的大屏布局；Google Play 平板从批量处理开始，按大屏素材规范只保留实际应用界面，未添加宣传标题或设备框。Apple 的英文文案使用 Photos / Files，Android 使用系统照片选择器、gallery / files，避免混淆平台应用名称。

## 本次 ASO 假设与后续观察

假设：清楚展示一项具体任务及真实控件，比泛化的“一站式图片工具”更容易让首次访问者理解用途。本次 App Store 首帧强调裁剪结果，Google Play 首帧强调批量转换；元数据同步说明质量设置、六种输出格式、相册保存的格式范围，以及设备内处理。未宣传移动端不可用的背景移除、永久历史、AI 修复或未经验证的画质/压缩率收益。

这次是版本资料更新，同时调整了文案和截图，并非严格 A/B 实验，不能据此声称转化提升。发布后按平台、语言和流量来源观察商品页访问到安装的转化率，并参考留存、卸载和评价；项目不接入追踪 SDK，不为实验增加用户追踪。下一次可在 App Store Product Page Optimization / Google Play Store Listing Experiments 中只测试首帧“批量转换”与“裁剪”的差异，保持其他图片和文案不变。当前未获取历史转化数据，也未自动创建线上实验。

六种语言不仅翻译标题，也重新启动对应语言的应用界面进行原生采集。法语、德语等较长文案分别调整换行、字号；文件名使用相应语言的示例名称。

## 规格来源

2026-11-11 核对以下官方文档：

- [Apple Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)：当前要求 iPhone Dynamic Island 中等屏幕截图；支持 iPad 的应用需提供 13 英寸截图。所选分辨率均在其允许列表中。
- [Google Play Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151)：手机采用 9:16、1080p，数量为 8；大屏采用 16:9，提供 4 张；宣传图 1024 × 500。手机标题区域控制在约 20% 以内，提供各语言替代文本。

## 真实界面来源与质量检查

- iPhone / iPad：iOS 26.5 Simulator，生产 `PictoolsApp`、真实系统字体、原生图片处理。
- Android：API 35 emulator，分别使用手机和 1280 × 720 逻辑尺寸的大屏布局。
- `integration_test/store_capture_test.dart` 只负责导入本地样例、执行真实转换和增强、切换界面与语言，不修改产品 UI。
- 对比图 B 来自同一海岸样例的真实增强结果；批量图片通过真实编码器转换。海岸和静物为项目已有示例资产，用于展示编辑功能。
- 原始截图保留在 `raw/`，`manifest.raw.json` 记录 216 张来源、时间、尺寸、语言和哈希。加工仅裁去无内容系统栏边距、等比缩放、添加外部卖点标题与品牌背景；没有重画应用内控件。
- 每个上传目录有 `manifest.store.json`；`qa/validation-summary.json` 汇总全部集合的规格核验。
- 对所有成品检查精确尺寸、格式、透明通道、数量、标题及替代文本；HTML 渲染检查文案边界与图片加载，并人工检查手机、大屏及多语言联系表。

## 可编辑源文件与再生成

仓库根目录中：

- `scripts/store/copy.json`：6 种语言的卖点标题、副文案、替代文本。
- `scripts/store/compose.py`：手机和 iPad 的品牌构图，调用 UI Design Crafter 导出器。
- `scripts/store/feature_graphics.py`：宣传图与图标导出。
- `scripts/store/render.mjs`：HTML 导出 PNG，测量多语言文案。
- `scripts/store/package.py`：规格检查、联系表、预览页与 ZIP 打包。
- `scripts/store/capture_ios.py` / `capture_android.py`：原生采集流程。
- `source/语言/设备/*.html`：单张可编辑设计源文件及关联截图。

再生成需要项目 Flutter/Xcode/Android 环境、Python Pillow、Node Playwright 与 Chrome，以及 UI Design Crafter 技能脚本。`PLAYWRIGHT_MODULE` 可指定已安装 Playwright 模块路径。先采集，再运行 compose、feature_graphics、render 和 package。不要直接用旧版 `docs/app-store/screenshots/` 或 `docs/google-play/assets/` 中的历史素材替代此套设计。

素材已接入 `fastlane/screenshots.json`；正式版本、上传和手动/自动提审命令见 [双商店自动化说明](../../STORE_AUTOMATION.md)。上传状态以后台版本及发布验证报告为准。
