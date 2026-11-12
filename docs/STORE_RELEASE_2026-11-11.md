# Pictools 1.2.0（3）发布准备记录

## App Store：资料完成，最新后台状态为等待审核

- App Store 版本：1.2.0，构建号：3。
- 服务端构建状态 VALID；已选中到正式版本。自动化准备完成时为 PREPARE_FOR_SUBMISSION / MANUAL；2026-11-12 最后回读已变为 WAITING_FOR_REVIEW / AFTER_APPROVAL（等待审核、审核通过后自动发布）。本次未调用实际提审或更改该发布方式，保留后台最新状态。
- 六语言名称、副标题、宣传文本、描述、关键词、更新说明与本地 JSON 完全一致。
- 72 张截图全部 COMPLETE；每语言 iPhone 8 张、iPad 4 张，远端原图校验和及顺序均与本地一致。
- 支持网址沿用后台 https://pictureslighting.com/，其他既有联系与隐私配置保留；未设置 GitHub 支持页。
- 本次自动化未执行提交审核，没有对外分发 TestFlight；这不代表后台目前仍未提审，以最新回读状态为准。

### 2026-11-12 名称修正

按用户指定，将两端六语言名称统一为 `Pictoos` + 本地化“图片工具箱”，已逐项同步并回读验证。简体中文为 `Pictoos: 图片工具箱`。iOS 其他 App Information 字段保持不变；修改名称时 1.2.0（3）为准备提交、手动发布，最终状态变化见上文。核验记录：`release-validation/2026-11-12/apple-name-verification.json`。

| 语言 | App Store / Google Play 名称 |
| --- | --- |
| 简体中文 | Pictoos: 图片工具箱 |
| 繁体中文 | Pictoos: 圖片工具箱 |
| 英语 | Pictoos: Image Toolbox |
| 西班牙语 | Pictoos: Kit de imágenes |
| 法语 | Pictoos : boîte à outils photo |
| 德语 | Pictoos: Bild-Werkzeugkasten |

## Google Play：全部截图顺序已核验，已保存且未提审

- 2026-11-12 已在 Console 保存六语言完整商店资料，发布概览显示“尚未提交送审的更改”，共 13 项。未点击提交审核。
- API 回读六语言名称、简短说明、完整说明与本地 JSON 完全一致。
- 72 张截图（每语言手机 8 张、10 英寸平板 4 张）、6 张本地化置顶大图的 SHA-256 与本地文件逐项匹配。默认语言的独立 512px 图标匹配，其余五种语言继承该图标。旧 7 英寸截图已清空。
- 2026-11-12 已在 Console 完成其余五种语言的手机、平板截图排序并保存。13:42（北京时间）API 回读确认六种语言全部 12 组、72 张截图的 SHA-256 及展示顺序均与本地文件一致，`errors` 和 `order_warnings` 均为空。手机顺序为批量处理、裁剪、对比、缩放、增强、导入、导出、深色界面；平板顺序为批量处理、裁剪、对比、导出。
- 已为含 AI 示例照片的 72 张截图和 6 张置顶大图完成逐资源声明；应用图标未标记。实际应用界面为原生截图，示例照片来源见 `design-system/MASTER.md`。
- 独立 `stage_binary` 流程成功：正式轨道现有 1.2.0 / versionCode 3 / draft，六语言更新说明完全匹配本地；原 1.0.1 / versionCode 2 / completed 保留。
- `android submit version_code:3 validate_only:true` 通过 Google 服务端校验，随后删除临时 edit；再次读取确认 3 仍是 draft，未提交审核。
- Google API 仍拒绝整套应用级资料的 `changesNotSentForReview=true` commit；失败 edit 已删除，没有改用自动送审。Console 保存是本账号当前保留手动提审的补充路径。
- 后续实际提审会将指定 draft 转换为待发布版本；代码在临时 edit 内替换原 completed 条目并保留目标版本说明，创建草稿时仍保留线上 release。

## 本地成果与验证

- 六语言 JSON：fastlane/metadata/；版本说明：fastlane/release_notes/1.2.0.json。
- 144 张截图、6 张宣传图、Play 独立 512px 图标；素材浏览见 store-assets/2026-11-11/index.html。
- App Store 首帧裁剪、Google Play 首帧批量转换；描述与截图按平台区分照片/文件选择及保存位置。
- Flutter analyze 无问题；83 项 Flutter 测试通过；36 项发布自动化测试、173 条断言通过。
- 商店素材 25 组严格检查通过，0 fail / 0 warn；文案与通用视觉扫描的人工复核见素材 qa/REVIEW.md。
- 两端均以 --obfuscate 和 --split-debug-info 构建。产物位于 build/releases/{ios,android}/1.2.0+3/，Dart 符号位于 build/symbols/{ios,android}/1.2.0+3/；另保留 iOS archive/dSYM 和 Android mapping.txt。
- API 配置存于已忽略的 fastlane/.env，私钥位于项目外；没有将私钥内容写入文档。

## 自动化入口

```bash
# 本地预演：不联系商店
bundle exec fastlane check screenshots:true include_graphics:true
bundle exec fastlane ios submit dry_run:true
bundle exec fastlane android submit version_code:3 dry_run:true

# iOS 创建/配置目标版本并选择已上传的构建，不重新上传
bundle exec fastlane ios prepare screenshots:true
bundle exec fastlane ios select_build

# 后续新构建的 Google 正式草稿，仅上传包和版本说明
bundle exec fastlane android stage_binary
```

后续版本可使用 ios submit / android submit 提审；本次自动化没有执行实际提审。当前 iOS 已在等待审核，不要重复提交。Google 商店资料及全部截图顺序已保存并通过远端核验，1.2.0（3）保留正式渠道草稿，等待用户手动提审。不要重传已接受的相同构建号；下次新包先递增 pubspec.yaml 的 +N。详细流程与 API 限制见 STORE_AUTOMATION.md。

## 远端核验依据

- `release-validation/2026-11-11/apple-release-verification.json`：逐字段、逐截图校验和与顺序核对，errors 为空。
- `release-validation/2026-11-12/apple-name-verification.json`：六语言名称及其他 App Information 字段核验。
- `release-validation/2026-11-12/remote-status.json`：最终版本状态回读，Apple 1.2.0（3）WAITING_FOR_REVIEW / AFTER_APPROVAL、Google 1.2.0（3）正式轨道 draft。
- `release-validation/2026-11-12/google-listing-verification.json`：最终六语言文案、图片内容、展示顺序和轨道快照；12 组截图的 `ordered` 全部为 true，`errors` 和 `order_warnings` 为空，正式渠道 versionCode 3 仍为 draft。
- `release-validation/2026-11-12/google-screenshot-order-pending.png`：完成五种语言排序后保存的发布概览，仍显示“尚未提交送审的更改”，共 13 项。
