# Flutter 双商店发布自动化

从仓库根目录运行 Fastlane。已接入六种语言的商店文案、App Store / TestFlight 更新说明、Google Play 更新说明，以及 Flutter 签名打包和上传。

现有后台的版权、支持网址、隐私政策网址、营销网址、开发者联系信息默认保留，不设置 GitHub 支持链接。截图已接入自动上传；视频文件和审核问卷仍在后台处理。

## 日常更新速查：上传后手动提审

普通版本更新使用两端的 `stage_binary`。它们只处理新安装包、版本号和六语言更新说明，不同步本地商店名称、描述、副标题、关键词、截图、宣传图、独立商店图标或联系网址。iOS 新版本沿用 Apple 从当前版本继承的资料，Google 沿用应用级资料。iOS 安装包内的 App 图标仍随新包更新。

先修改 `pubspec.yaml`，例如下一版使用 `version: 1.2.1+4`（仅示例，编号必须未上传过）。再创建并编辑 `fastlane/release_notes/1.2.1.json`，填写该版本真实的六语言更新说明。描述、名称、截图没有变化时不用编辑或上传它们。

在仓库根目录依次运行：

```bash
# 1. 本地校验版本和六语言文案
bundle exec fastlane check

# 2. iOS：创建目标版本、更新 What's New、混淆打包上传、等待处理并关联构建
bundle exec fastlane ios stage_binary

# 3. Google Play：混淆打包上传 AAB 和更新说明，建立正式渠道草稿
bundle exec fastlane android stage_binary
```

两条上传命令各自默认执行 `flutter analyze` 和 `flutter test`；都不提交审核。完成后分别到 App Store Connect 的目标版本、Play Console 的正式版草稿中检查并手动提审。iOS 关联构建时设置审核通过后手动发布；Google 审核通过后的发布时间由后台 Managed publishing 设置决定。API 密钥仍自动读取本机 `fastlane/.env`。

可先离线预演（不打包、不登录后台）：

```bash
bundle exec fastlane ios stage_binary dry_run:true
bundle exec fastlane android stage_binary dry_run:true
```

如果本次代码已完整通过检查，可给实际上传命令加 `skip_checks:true`，避免重复跑检查。两端构建均使用 `--obfuscate` / `--split-debug-info`，需要保留符号文件。

| 本次改动 | 额外操作 |
| --- | --- |
| 仅功能、修复和版本说明 | 只执行上面的日常流程 |
| iOS 名称、描述等文案 | 编辑 `fastlane/metadata/*.json` 后执行 `bundle exec fastlane ios metadata`；该命令同步整套本地文案，不是单字段差异上传 |
| iOS 截图 | 在目标版本创建后执行 `bundle exec fastlane ios screenshots`；可加 `locales:zh-CN,en-US` |
| Google 名称、描述等文案 | 编辑 `fastlane/metadata/*.json` 后执行 `bundle exec fastlane android metadata` |
| Google 截图、宣传图或商店图标 | 执行 `bundle exec fastlane android screenshots`；需要宣传图/图标时加 `include_graphics:true`，只改图标则用 `android icon` |
| 联系网址、版权等后台配置 | 无变化时保留后台现值；普通发布无需修改 |

上传后若仅 iOS 版本关联失败，或已通过其他方式上传同一构建，不要重传，执行：

```bash
# 只创建/准备目标版本并更新六语言 What's New，不同步其他文案或截图
bundle exec fastlane ios prepare_update

# 等待 Apple 将准确构建处理为 VALID 后关联该构建
bundle exec fastlane ios select_build
```

`prepare_update` 仅 PATCH 有变化的 What's New，相同说明跳过。新版本缺少六语言资料时会明确停止，需显式执行 `ios metadata` 初始化；不会用本地整套文案自动覆盖后台。已有其他待发布版本或目标版本不可编辑时也会停止。Google 已有包含构建的正式草稿时，`stage_binary` 不覆盖它，应在 Console 继续处理。上传途中失败先检查构建是否已被接收，避免重传相同编号。

日常只更新包时使用 `stage_binary`，无需运行包含文案同步的 `release` 或实际版本提审的 `submit`。Google 文案、截图和图标有变化时，额外执行对应 API 命令即可；资料同步默认使用 Google 正常 commit 流程，可能自动触发资料审核，与安装包仍为 draft 是两个不同状态。

### Google 商店资料：后续统一使用 API

Google 有 API：Fastlane Supply 支持 AAB、六语言标题/描述、更新说明、截图、图标和宣传图上传，代码已接入。它的上传先写入临时 edit，最后必须 `edits.commit` 才算保存。[Fastlane Supply 官方文档](https://docs.fastlane.tools/actions/supply/)

本应用在 2026-11-12 的实际请求中，包含应用级商店资料的 edit 在最终 commit 拒绝了 `changesNotSentForReview=true`，返回 `Changes are sent for review automatically. The query parameter changesNotSentForReview must not be set.`。这不是缺少上传 API，也不是私钥未配置，而是当时该应用的送审流程限制。Google 对此参数的官方描述涉及被拒后的待送审更改，并未承诺所有应用状态都能任意保存为未送审。[Google edits.commit](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit)

按用户最新要求，后续不再强制把应用级资料留在未送审状态，统一使用 API 保存，默认 `send_for_review:true`（对应 `changes_not_sent_for_review:false`），不再为这个限制转用 Computer Use。只改元数据也可能进入 Google 的正常审核流程，不能保证不会自动送审。`send_for_review` 在此控制 commit 参数，并不是调用独立的版本提审动作；`stage_binary` 仍固定将安装包放入正式渠道 draft。[Google Draft releases](https://developers.google.com/android-publisher/tracks#draft_releases)

iOS 的版本创建、版本资料修改和提交审核可分开调用，新版本会继承当前版本元数据，所以可以只更新 What's New 并关联新构建。[Apple 创建新版本说明](https://developer.apple.com/help/app-store-connect/update-your-app/create-a-new-version)

## 1. 安装与本地预览

使用独立安装的 Ruby（本次验证：Ruby 4.0.6、Fastlane 2.241.2），不要使用 macOS 自带 Ruby。依赖由 `Gemfile.lock` 锁定。

```bash
bundle config set --local path vendor/bundle
bundle install
bundle exec fastlane check
open build/store/preview.html
```

`check` 无需账号，验证六语言必填字段、长度、网址格式、版本号和更新说明，然后生成 Fastlane 原生目录。`build/store/preview.html` 只预览本地待同步文案，不是远端差异报告。生成目录可重新创建，不要直接修改。

## 2. 文案放在哪里

唯一的自动化文案来源：

| 文件 | 用途 |
| --- | --- |
| `fastlane/metadata/zh-CN.json` | 简体中文商店文案 |
| `fastlane/metadata/zh-TW.json` | 繁体中文商店文案 |
| `fastlane/metadata/en-US.json` | 美式英语 |
| `fastlane/metadata/es-ES.json` | 西班牙语 |
| `fastlane/metadata/fr-FR.json` | 法语 |
| `fastlane/metadata/de-DE.json` | 德语 |
| `fastlane/release_notes/<版本号>.json` | 三个发布渠道共用的六语言更新说明 |
| `fastlane/store.json` | Bundle ID、Android 包名和可选 iOS 全局字段 |
| `pubspec.yaml` | 版本号与默认 build number / versionCode |

原 `docs/app-store/listing/` 和 `docs/google-play/listing/` 是此前的手动填写资料，不再参与自动同步。已将文案迁入上述 JSON，并更新了相册导入/保存说明；当前 `1.2.0` 更新说明不再写“首次发布”。

各语言 JSON 中的字段：

iOS 的 `name` 和 Google Play 的 `title` 按用户指定统一使用 **Pictoos: 图片工具箱** 及对应语言的“图片工具箱”名称；品牌拼写为 `Pictoos`。功能卖点放在副标题、描述和关键词中，后续优化不要自行替换产品名称。六语言具体名称以 `fastlane/metadata/*.json` 为准，两个平台的名称保持一致。

| 平台 | 字段 | 上限 / 行为 |
| --- | --- | --- |
| iOS | `name` | 应用名称，30 字符 |
| iOS | `subtitle` | 副标题，30 字符 |
| iOS | `promotional_text` | 宣传文本，170 字符 |
| iOS | `description` | 完整描述，4000 字符 |
| iOS | `keywords` | 关键词，按 App Store Connect 的 100 UTF-8 字节限制校验 |
| iOS | `privacy_url`、`support_url`、`marketing_url` | 可选 HTTPS 网址；省略或 `null` 保留已有值 |
| Android | `title` | 应用名称，30 字符 |
| Android | `short_description` | 简短说明，80 字符 |
| Android | `full_description` | 完整说明，4000 字符 |
| Android | `video` | 可选宣传视频网址；省略或 `null` 保留已有值 |
| 两端 | `release_notes/<版本号>.json` | 每种语言最多 500 字符，兼容 Google Play |

App Store 自动映射 `zh-CN → zh-Hans`、`zh-TW → zh-Hant`，Google Play 保持 `zh-CN`、`zh-TW`。App Store 的“应用信息”和“版本信息”都会添加相应语言；后台其他已有语言不删除。

版权和类别也已预留支持：在 `fastlane/store.json` 的 `ios` 对象中设置 `copyright`、`primary_category`、`secondary_category` 即会同步。目前该对象为空，保留后台原值。不要用空字符串表示删除，当前流程不支持清空远端字段。

新增 iOS 语言尚无网址时，从后台主要语言读取并继承实际网址；已有语言的网址不覆盖。如果后台主要语言也没有必需的支持/隐私网址，命令会明确报错，需先在后台填写。不会猜测官网或生成 GitHub 支持链接。

Google Play 的开发者联系信息、隐私政策网址、分类、Data safety、年龄分级，以及两端开发者法定名称、定价、国家/地区等保持后台配置。这些不属于本流程的本地化 listing 文本。应用内语言、桌面图标名称、系统权限弹窗文案不由商店元数据修改。

## 3. Apple API 密钥

1. 打开 **App Store Connect → 用户和访问 → 集成 → App Store Connect API → 团队密钥**。
2. 若 API 尚未启用，由 Account Holder 申请访问；团队密钥由 Account Holder 或 Admin 创建。
3. 新建专门用于发布的密钥，访问角色选择 **App Manager（App 管理）**。
4. 下载 `.p8` 私钥，并记录 **Key ID** 和 **Issuer ID**。私钥只能下载一次。
5. 将 `.p8` 保存在项目外的私人目录，例如 `~/.config/pictools/AuthKey_ABC123.p8`。
6. 复制环境变量模板，填写绝对路径：

```bash
cp -n fastlane/.env.example fastlane/.env
```

```dotenv
ASC_KEY_ID=你的KeyID
ASC_ISSUER_ID=你的IssuerID
ASC_KEY_FILEPATH=/Users/你的用户名/.config/pictools/AuthKey_ABC123.p8
```

这些变量在 Fastlane 运行时自动从 `fastlane/.env` 读取，不需要 `source`，也不需要把 Apple ID 密码发给任何人。CI 可以直接注入同名环境变量，并把私钥存为临时文件。

**API 密钥用于后台访问和上传，不会代替代码签名证书。** 本机仍需在 `ios/Runner.xcworkspace` 的 Runner 中配置正确的 Team、Distribution 证书和 provisioning profile。当前流程沿用项目现有 Xcode 签名设置。需要手动签名导出配置时，在 `.env` 设置 `IOS_EXPORT_OPTIONS_PLIST=/绝对路径/ExportOptions.plist`。

## 4. Google Play 服务账号

1. 在 Google Cloud Console 创建或选用项目，启用 **Google Play Android Developer API**。
2. 在 **IAM 和管理 → 服务账号** 新建专用服务账号。
3. 在该服务账号的 **密钥 → 添加密钥 → 创建新密钥** 中下载 JSON 私钥。
4. 打开 **Google Play Console → 用户和权限 → 邀请新用户**，填入服务账号的邮箱（`…@…iam.gserviceaccount.com`）。
5. 只为 Pictools 授予所需的应用权限：查看应用信息、管理商店展示、向测试轨道发布；需要正式轨道时再授予正式版发布权限。仅在 Cloud IAM 授权还不够，必须在 Play Console 授权。
6. 将 JSON 放在项目外，例如 `~/.config/pictools/google-play-service-account.json`，在同一个 `fastlane/.env` 添加：

```dotenv
GOOGLE_PLAY_JSON_KEY=/Users/你的用户名/.config/pictools/google-play-service-account.json
```

Google 当前不再要求把开发者账号与 Cloud 项目绑定。此项目已在 Google Play 上架，可以直接管理现有应用。

**服务账号 JSON 与 Android 上传签名密钥是两回事。** AAB 必须继续使用 Play 中登记的原上传密钥；本项目从已忽略的 `android/key.properties` 读取 `storeFile`、`storePassword`、`keyAlias`、`keyPassword`。没有该文件时打包命令会停止，避免生成未签名上传包。

`.env`、`.p8`、`fastlane/secrets/`、`android/key.properties`、签名密钥库和依赖目录均已加入 Git 忽略规则。Google JSON 建议始终保存在项目外。

## 5. 日常命令

### 只同步商店文案

```bash
# 无需密钥，本地验证和预览
bundle exec fastlane check

# App Store 六语言名称、副标题、宣传文本、描述、关键词、版本更新说明
bundle exec fastlane ios metadata

# Google Play 六语言名称、简短说明、完整说明；保留已有版本的更新说明
bundle exec fastlane android metadata
```

App Store 以 `pubspec.yaml` 的版本号为目标：有同号可编辑版本就更新，没有则创建新版本。如果已有另一个待发布版本，或同号版本已经上线/正在审核，则停止，不重命名后台版本。

Google Play 的商店文案是应用级资料，**不会被隔离在测试轨道里**。`metadata` 默认通过 `production` 轨道查找现有发布记录，并按 Google 正常 API 流程提交资料更改，可能自动进入审核。若该轨道有多个发布记录，指定 `version_code`，或改用存在单个发布记录的轨道。

**历史实测与当前默认值（2026-11-12）：** 本应用曾在 commit 阶段拒绝 `changesNotSentForReview=true`。现按用户要求，元数据、截图、图标及组合发布命令默认使用 `send_for_review:true`，允许 Google 的正常 commit/审核行为，不再要求资料保持未送审，也不再因此改走 Console。仍保留显式 `send_for_review:false` 的兼容选项；若指定后 API 拒绝，会原样报错，不自动反转参数。`validate_only:true` 只校验临时 edit，不能保证最终 commit 成功，也不会保存资料。

Console 中“保存为草稿”只保存编辑中的资料；完成“下一步”中的资源检查，再点“保存”，才会出现在发布概览的“尚未提交送审的更改”中。这仍未提交审核。批量选择图片后，Console 可能按上传完成时间排列，须检查展示顺序，不能把文件数量正确当作顺序正确。不同语言可继承默认图标；含文字的置顶大图和截图应分别上传本地化文件。

本次截图使用真实应用界面，界面内展示的示例照片由 AI 生成，来源记录见 `design-system/MASTER.md`。已按 Google 的逐资源声明界面标记 72 张截图和 6 张置顶大图，应用图标未标记。后续更换资源时仍需在 Console 检查此声明；当前 Fastlane 流程没有自动设置该字段。参见 [Google 的 AI 资源声明说明](https://support.google.com/googleplay/android-developer/answer/17262077)。

更新已有 Play 版本的更新说明必须显式指定其 versionCode；确认当前 `release_notes/<版本号>.json` 正是该构建的说明：

```bash
# 4 是示例，必须替换为该轨道已有的 versionCode
bundle exec fastlane android metadata track:internal version_code:4
```

### 打包并上传

日常保留后台资料的更新优先使用文档开头的 `ios stage_binary` / `android stage_binary`。以下 `release` 是需要同步文案时的完整流程。

```bash
# iOS：签名打包并上传到 TestFlight，包含六语言测试说明
bundle exec fastlane ios beta

# iOS：先同步商店资料，再签名打包和上传 IPA 到 App Store Connect
bundle exec fastlane ios release

# Android：签名打包 AAB，同时上传六语言文案和更新说明到内部测试
bundle exec fastlane android release

# Android：正式轨道草稿；在后台检查后完成送审
bundle exec fastlane android release track:production

# 日常轻量更新：只打包上传 AAB 和六语言版本说明，保持正式轨道 draft
# 文案、截图、宣传图或图标有变化时，再运行对应 API 同步命令
bundle exec fastlane android stage_binary
```

`beta` / `release` / `stage_binary` 默认先执行 `flutter analyze` 和 `flutter test`。Flutter CLI 负责打包和 Flutter/Rust 构建集成，Fastlane 负责编排和上传。若已独立跑过检查，可显式使用 `skip_checks:true`。

iOS `release` 在 Apple 处理完成后写入各语言测试说明，自动将准确版本和构建号关联到 App Store 版本，并设置审核通过后手动发布。它不提交审核，也不对外分发 TestFlight。团队后台已配置的内部自动分发仍由 Apple 控制。

如果已用 `ios beta` 上传同一构建，执行 `ios prepare screenshots:true` 和 `ios select_build` 即可准备正式版本；不要用 `ios release` 重传相同构建号。

Google Play 默认 `track:internal release_status:completed send_for_review:true`，上传成功后按 Google 的流程提供给已配置的内部测试人员；其他轨道默认 `release_status:draft send_for_review:true`：安装包保留 draft，同一 edit 中的应用级资料按正常流程保存，可能触发资料审核。如需命令完成正式轨道提交，可显式使用：

```bash
bundle exec fastlane android release track:production release_status:completed send_for_review:true
```

这会提交正式发布，审核通过后的上线时间取决于 Play Console 的 Managed publishing 等设置。Google 如果拒绝送审标志，流程不会偷偷切换该标志重试，按错误信息明确指定 `send_for_review:true` 或 `false` 后重新操作；若 AAB 已被接受，先检查后台，避免重传同一 versionCode。

`android stage_binary` 是独立的构建草稿流程，固定 `production` 和 `draft`，强制跳过所有应用级商店资料，仅上传 AAB、R8 映射及该版本的更新说明。它使用 Google 官方 [Draft releases](https://developers.google.com/android-publisher/tracks#draft_releases) 流程提交 edit，不设置保留应用级更改的送审标志；构建状态仍为 draft，需在 Console 或后续 `android submit` 明确提审。可以填充 Console 创建的空草稿，但拒绝覆盖已有构建的草稿。

**内部测试通过后转正式轨道，应提升已有版本，不重新上传同一个 versionCode：**

```bash
# 4 替换为内部测试已上传的 versionCode；默认创建正式轨道草稿
bundle exec fastlane android promote version_code:4

# 明确提交正式发布，沿用原构建和原更新说明
bundle exec fastlane android promote version_code:4 release_status:completed send_for_review:true
```

`promote` 可用 `from:internal to:production` 指定来源和目标，不重新打包，也不改写商店文案或更新说明。

### 创建版本与后续提审

```bash
# iOS：不存在时创建 pubspec 对应的 App Store 版本，存在时更新资料
bundle exec fastlane ios prepare screenshots:true

# iOS：关联已经上传且处理完成的准确构建，不重新上传
bundle exec fastlane ios select_build

# Android：创建正式轨道草稿，上传包、六语言文案、截图和图标
bundle exec fastlane android release track:production screenshots:true include_graphics:true

# 以下是实际提审命令，手动确认资料后再运行；本次准备发布不执行它们
bundle exec fastlane ios submit
bundle exec fastlane android submit version_code:3
```

`ios prepare` / `metadata` / `release` 会在目标 App Store 版本不存在时创建版本；发现另一个可编辑版本则停止，避免重命名已有草稿。`ios submit` 同样会先创建缺失版本并写入文案，但不会补传缺失截图或安装包；请先完成 `prepare` / `release`。它仅选择准确版本号、构建号且状态为 VALID 的构建，运行 Fastlane precheck，再提交审核；审核通过后仍需手动发布。隐私、年龄分级、审核联系人、协议等未完成时，以 Apple 返回的要求为准，不自动编造问卷答案。

Google Play 的 `release track:production` 创建 draft，同时保留当前已发布的 release；发现另一个正式轨道草稿会停止。`android submit` 只处理指定 versionCode 的既有 production draft，不重新上传 AAB 或改写文案。提交可能连同后台其他待审核资料一起送审；审核通过后是否自动上线由 Play Console 的 Managed publishing 控制，API 无法在此命令里替用户启用该开关。Google 若要求从 Console 手动送审，命令保留错误，不切换送审参数重试。

```bash
# 完全离线的提审命令预演
bundle exec fastlane ios submit dry_run:true
bundle exec fastlane android submit version_code:3 dry_run:true

# Google：验证既有正式草稿转换为待审核发布的操作，随后删除临时 edit
bundle exec fastlane android submit version_code:3 validate_only:true
```

Apple 没有完整的无副作用提审校验接口；本地测试验证版本选择和调用参数，实际审核资格由 App Store Connect 在提审时校验。正式上传和服务端提交审核是两个独立步骤。

### 只打包、不上传

```bash
bundle exec fastlane ios build
bundle exec fastlane android build
```

两端均启用 Dart 混淆并保存符号，产物归档到：

- `build/releases/ios/<版本+构建号>/*.ipa`
- `build/releases/android/<版本+构建号>/app-release.aab`
- `build/symbols/<ios或android>/<版本+构建号>/`
- iOS Xcode 归档：`build/ios/archive/Runner.xcarchive`（包含原生 dSYM）
- Android R8 映射：`build/app/outputs/mapping/release/mapping.txt`（存在时随 AAB 上传）

请把发布产物、符号和 Xcode 归档另存到发布备份目录；`build/` 会被 `flutter clean` 清理。打包前会将旧输出包移到 `build/releases/previous/`，让增量构建重新生成输出。上传只接受本次命令新生成的产物；Flutter 导出失败但返回成功时，也不会使用旧 IPA。

### 每次更新版本

1. 修改 `pubspec.yaml` 的 `version: x.y.z+N`；N 必须是对应商店尚未上传过的新编号。
2. 在 `fastlane/release_notes/x.y.z.json` 写好六语言更新说明。
3. 需要改卖点时，修改 `fastlane/metadata/*.json`。
4. `bundle exec fastlane check`，查看 HTML，再运行对应发布命令。

同一营销版本重复构建只需增加 N。也可临时用 `build_number:4` 覆盖构建号，不修改 `pubspec.yaml`；该值会同步用于实际 Flutter 构建、产物目录和 Play changelog 文件名。版本号始终来自 `pubspec.yaml`。

## 6. 截图上传

默认使用当前六语言成品包 `docs/store-assets/2026-11-11/upload/`，不读取旧版截图、原始截图、联系表或 ZIP。路径和设备分组配置在 `fastlane/screenshots.json`。

| 平台 | 每种语言的素材 | 后台目标 |
| --- | --- | --- |
| iOS | 8 张 1179 × 2556 手机图 | Dynamic Island 中等屏幕，Fastlane `APP_IPHONE_61` |
| iOS | 4 张 2752 × 2064 平板图 | iPad 13 英寸 |
| Google Play | 8 张 1080 × 1920 手机图 | `phoneScreenshots` |
| Google Play | 4 张 1920 × 1080 平板图 | `tenInchScreenshots` |
| Google Play，可选 | 各语言宣传图 + 共享品牌图标 | `featureGraphic` / `icon` |

共 144 张截图。按文件名排序，上传前检查格式、尺寸、透明通道、重复图片、数量和缺失语言。iOS 单设备最多 10 张，Google Play 单设备最多 8 张。`build/store/ios-screenshots.json` 和 `android-screenshots.json` 列出实际上传文件、分组及 SHA-256；原成品预览仍在 `docs/store-assets/2026-11-11/index.html`。

```bash
# 离线校验全部截图和 Google 宣传图/图标
bundle exec fastlane check screenshots:true include_graphics:true

# 只上传截图；首次使用应先初始化六语言商店文案
bundle exec fastlane ios screenshots
bundle exec fastlane android screenshots

# 首次配置可一条命令同时同步文案和截图，不上传安装包
bundle exec fastlane ios metadata screenshots:true
bundle exec fastlane android metadata screenshots:true

# 只同步指定语言；使用项目语言码，Apple 中文代码会自动映射
bundle exec fastlane ios screenshots locales:zh-CN,en-US
bundle exec fastlane android screenshots locales:zh-CN,en-US

# Google Play 同时上传宣传图和商店图标
bundle exec fastlane android screenshots include_graphics:true

# 随构建上传一起同步截图
bundle exec fastlane ios release screenshots:true
bundle exec fastlane android release screenshots:true include_graphics:true
```

普通 `metadata` / `release` 命令仍默认跳过截图；需要附带截图时加 `screenshots:true`。`include_graphics:true` 在组合命令中必须同时使用 `screenshots:true`，且只适用于 Android。`locales` 只筛选截图；组合命令的文案仍按原流程同步六种语言。

独立 `screenshots` 命令不上传安装包、不修改文案和更新说明。App Store 必须已有同版本号的可编辑版本，以及对应语言的应用信息和版本信息；缺少时先运行 `ios metadata`。Google Play 新语言也先用 `android metadata` 初始化，或直接使用上面的文案+截图组合命令。

iOS 使用 Fastlane Spaceship 逐组同步：保留内容相同的图片，替换已选择语言/设备组中的旧图，并按本地顺序排列；其他设备组和语言不删除。Google Play 使用 Supply 的 `sync_image_upload` 校验值比较，同步有本地素材的设备组；未选择的语言和设备目录不会清空。截图同步是用所选本地集合替换对应后台集合，删除本地集合中的某张图会在下次同步时移除那张后台旧图。

```bash
# 离线预演；不会登录后台或上传图片
bundle exec fastlane ios screenshots dry_run:true
bundle exec fastlane android screenshots dry_run:true

# Google 真实图片上传校验，上传到临时 edit，校验后自动删除 edit
bundle exec fastlane android screenshots locales:zh-CN validate_only:true
```

Google Play 截图是应用级商店资料，跨测试轨道共用；`track` 用于 Supply 查找已有发布记录，不能隔离不同测试轨道的截图。默认按 Google 正常 API 流程保存，可能自动触发资料审核；不会因为保留未送审的要求改用 Computer Use。App Store 截图上传后仍需在后台完成版本审核。Apple 没有这里可用的截图临时校验模式，使用 `dry_run:true` 进行离线检查。

两端截图暂未包含自动填写替代文本；现有 `captions-and-alt-text.csv` 保留供后台填写。Apple 商店图标跟随安装包，不通过此截图命令上传。

### Google Play 商店图标

Google Play 的商店图标独立于安装包内的桌面图标，需要单独作为商店素材上传。[Google 官方规格](https://support.google.com/googleplay/android-developer/answer/9866151)要求 512 × 512、32 位 RGBA PNG、最大 1024 KB；上传前会校验这些条件。当前使用 `docs/store-assets/2026-11-11/upload/shared-icons/google-play-512.png`，六种语言共用此品牌图标。

```bash
# 只更新六语言商店图标；首次应先运行 android metadata 初始化语言
bundle exec fastlane android icon

# 只更新已有的简体中文商店图标
bundle exec fastlane android icon locales:zh-CN

# 离线预演，或真实上传到临时 edit 校验后删除
bundle exec fastlane android icon dry_run:true
bundle exec fastlane android icon locales:zh-CN validate_only:true
```

`android icon` 仅上传 `icon.png`，不依赖截图/宣传图文件，也不更新它们、安装包、文案或更新说明。内容相同的图标会按校验值跳过。默认按 Google 正常 API 流程保存，可能自动触发资料审核。实际效果以 Play Console 的审核和发布状态为准。

需要连同截图、宣传图一起上传时，仍用 `android screenshots include_graphics:true`；文案或打包流程中使用 `screenshots:true include_graphics:true` 已包含商店图标，无需再执行一次 `android icon`。

## 7. 验证与问题定位

```bash
# 自动化自身的回归测试（无需密钥）
bundle exec ruby -I fastlane/test -e 'Dir["fastlane/test/*_test.rb"].sort.each { |file| require_relative file }'

# 发布命令预演：只检查本地文案，不打包、不登录、不上传
bundle exec fastlane ios release dry_run:true
bundle exec fastlane android release dry_run:true

# Google 真实 API 校验：需要密钥，会创建并验证远端临时 edit，不提交
bundle exec fastlane android metadata validate_only:true

# Flutter 项目检查
bundle exec fastlane verify
```

`dry_run` 不验证远端权限、现有版本状态或证书。`validate_only` 是 Google 的服务端校验；用于 `android release` 时仍会构建并上传 AAB 到临时 edit，因此不能当作纯离线预演。

常见错误：

- **缺少环境变量**：填写 `fastlane/.env`；路径使用绝对路径。
- **Apple 403 / Google permission denied**：检查后台 API 角色和应用授权。
- **iOS 无法签名或未生成 IPA**：先在 Xcode 修复证书、Team 和 profile。
- **Play versionCode 已使用**：增大 build number，沿用原上传签名密钥。
- **Play 找不到轨道 / 多个 release**：指定有发布记录的 `track` 和目标 `version_code`。
- **新版本缺少更新说明**：创建对应版本号的六语言 JSON；流程不会悄悄复用上一版本说明。

官方资料：[Apple API 密钥](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/)、[Fastlane API 认证](https://docs.fastlane.tools/app-store-connect-api/)、[App Store 文案上传](https://docs.fastlane.tools/actions/deliver/)、[Google 服务账号设置](https://developers.google.com/android-publisher/getting_started)、[Google Play 上传](https://docs.fastlane.tools/actions/upload_to_play_store/)。
