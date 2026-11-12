# 商店素材最终复核

## 范围

- 6 种语言，iPhone 8 / iPad 4 / Android 手机 8 / Android 平板 4 张每语言。
- 144 张截图、6 张宣传图、2 个商店图标。
- 216 张原生来源截图；iOS 26.5 Simulator 和 Android API 35 emulator。

## 通过项

- 全部平台、设备、语言采集流程完成，真实图片转换、增强和导出入口断言通过。
- 25 个素材校验集合（24 个截图集合 + 6 张宣传图组成的 1 个集合）通过严格检查，0 fail / 0 warn。
- 126 张有外部排版的图完成 HTML 文案边界和图片加载检查；24 张 Google Play 平板图为合规界面图。
- 所有商店截图与宣传图为精确指定尺寸的 RGB PNG，无 alpha；Play 图标单独按 32-bit PNG 导出。
- 手机第一至第三张说明产品用途、图片对比和批量转换。宣传文字对应实际功能，无排名、价格、下载号召或 AI 效果宣称。
- 检查了六语言首图、中文完整序列、德语完整序列、法语长标题、iPad 大屏、Android 平板和宣传图。
- 初次采集发现导入弹窗存在过渡帧，已经重采全部 24 个平台/语言来源。采集器现在等待 ModalRoute 动画完成，并对弹窗背景进行原生像素不透明验证；iOS 16-bit 像素先归一化后断言。
- `import-retakes.jpg` 汇总最终 12 张手机弹窗来源，均无文字重影。对应成品重新渲染、重新打包。

## 文件

- `validation-summary.json`：精确尺寸、格式、透明度、数量、文案、alt text 检查汇总。
- `composition-metrics.json`：126 张排版图的图片加载、文案边界及字体尺寸。
- `ios-capture.log` / `ipad-capture.log`：六语言完整采集通过。
- `android-phone-full-capture.log` / `android-tablet-full-capture.log`：Android 六语言完整采集通过。
- `ios-imports.log` / `ipad-imports.log`：iOS 导入弹窗重采与像素验证通过。
- `android-imports.log`：Android 两种布局六语言重采完成。
- `package.log`：最终数量和 ZIP 打包结果。

## 本次元数据优化复核

- App Store 顺序调整为裁剪、对比、批量；Google Play 为批量、裁剪、对比。两端的导入/保存标题使用对应平台术语。
- 六语言首图、法语完整序列及英语手机、中文 Android、德语 iPad 成品人工复核通过；未重画真实应用内部界面。
- 文案规则扫描 0 fail、3 warn，均由英文 `new copies` 触发。这里描述导出生成副本，不是排名、促销或新品宣称，人工确认保留。
- 通用网页视觉扫描 0 fail、134 warn：132 条涉及商店导出像素尺寸与网页 viewport / CSS 度量不同，使用专用商店规格检查判定；2 条浅色批量页中间色占比提示，经人工检查文字与控件可辨。商店专用 25 组检查仍为 0 fail / 0 warn。

未将模拟器记录描述为实体设备测试。素材现已接入发布流程；上传、构建及送审状态见 `docs/STORE_RELEASE_2026-11-11.md`，本文件仅记录素材质量。
