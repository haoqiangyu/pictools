# Pictools Studio — UI/UX v2

目标 Figma：https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=13-606

本稿是 2.0 设计基线。2026-11-10 已按该方案实现 Flutter 手机 UI 与折叠屏响应式布局；实现范围、验证结果和原生 SDK 限制见 [Flutter 实现记录](qa/flutter/REVIEW.md)。原设计稿中的系统栏、设备尺寸和姿态按钮仅作说明，不直接写入产品 UI。

## 产品方向

为需要快速处理照片、素材和截图的人提供本地图片工作台。保留无需账号、设备内处理的原则。首页四工具一屏可达；进入编辑后隐藏全局导航，统一「选图 → 编辑 → 导出」。无需首启教学或权限墙。

视觉使用暖白纸面、深墨文字、烧橙动作色，深色编辑画布保护图片边界。照片是内容，工具本身不使用背景插画。英文品牌保留 Pictools；中文功能用直接动词命名。卡片仅用于工具、文件和底部弹层；普通设置为分隔列表。

## 色彩与字体

Light：background #F7F6F2；surface #FFFFFF；subtle #EEEDE7；ink #202522；muted #626B65；border #DADDD5；primary #C84725；primary-soft #FAE8DF；canvas #202522；success #23744B；warning #8A5A1B；danger #B63232。

Dark：background #171B18；surface #232925；subtle #303831；ink #F5F5EF；muted #B1BAB2；border #465047；primary #FFAE8F；primary-content #432313；primary-soft #4B3027。

中文 Noto Sans SC Regular / Medium / Bold；西文和数字 Roboto Regular / Medium / Bold。与现有 Flutter 字体栈一致，并用原生字体回退覆盖其他语言。字号固定级别：12/13/14/16/18/22/28/36；正文行高 1.5。设置中跟随系统文字大小；大字模式重排，不缩字。

## 几何和组件

4px 基线；间距 4/8/12/16/20/24/32。手机左右边距20，画布按实际可用宽度伸缩。卡片圆角8，按钮12，手机弹层24，标签999。按钮高度48，图标按钮48，输入52；图标24。每个区域一个主要动作。按钮包括 default/hover/pressed/focus/disabled/loading；字段包括 default/focus/error/disabled；工具入口、图标、按钮、字段、选项与开关为可复用组件；文件行、提示与弹层使用可编辑自动布局。

照片和裁剪蒙层为局部图片资产；全部界面文字、控件、图标和布局在 Figma 内可编辑。可点击原型用于主路径导航与代表性状态，不模拟真实编解码。

## 响应式与输入

- 320–599dp：单列主流程。首页≥360为双列工具；320和系统大字号为单列。编辑区预览+控制；底部CTA固定在安全区上方。
- 宽≥600dp且高≥600dp：导航栏/轨道与主内容分开，编辑预览+320dp检查器；滑动分区独立。
- 高<500dp横屏：紧凑工具栏，左右预览与可滚动控制，优先保留画布和CTA；尊重左右刘海安全区。
- ≥1024dp：64dp轨道+弹性画布+320dp检查器；窗口缩放按可用区域重新计算。
- 键盘打开：预览缩至缩略图，当前字段滚入可见区域，「完成」固定在键盘上方；校验信息紧邻字段。
- iOS保留边缘返回与系统文档选择/分享；Android系统返回依次关闭弹层、退出工具、返回首页。切换方向不丢失选择、参数或进度。

## 功能兼容

现有：对比滑块/并排/叠加；宽高调整与锁比例；8种裁剪比例；自动亮度增强；六种输出格式；语言与隐私。移动端隐藏桌面专属抠图。导入明确区分「从相册导入 / 从文件导入」；导出区分「保存到相册 / 保存到文件」，单张和批量共用。相册保存支持 PNG/JPEG，文件保存支持全部六种格式。相册与文件的成功状态分别记录。

已接入 Flutter：统一导入来源面板、工作会话内继续处理、JPEG/WebP 质量与无损 WebP、透明图转 JPEG 的背景色合成、ICO 尺寸预检、批量状态/取消与重试、分享、主题、预览与大图内存保护。批量空白页的主按钮也支持多选；导入来源不限制之后的保存去向。Android 相册导入关闭选择器额外的 JPEG 重压缩；iOS 保留系统兼容表示。

仅当前会话保留输入，不承诺永久草稿/历史；显式退出前提示保留或放弃。处理完成不等于已保存。取消系统保存返回未保存结果；禁止标红为转换错误。批量取消仅停止后续项目，完成项保留。底层不提供可信百分比时显示不定进度；批次以完成文件数作进度。

不能只凭扩展名承诺可解码：导入后检测内容/方向/帧数/透明度。HEIC、AVIF、RAW、PSD、SVG等以实际解码能力为准，失败提供重新选图；动态图明确提示仅处理静帧并征得选择。PNG和WebP用于透明图；JPEG不支持透明，转换前选择背景；ICO预检尺寸并允许缩小副本。不得假称保持EXIF、ICC或HDR；在落地阶段建立回归样本矩阵验证。

## 无障碍、国际化、反馈

正文对比目标≥4.5:1，关键图形≥3:1；状态同时用文字与图标。所有触控目标≥48dp。读屏顺序为标题→预览说明→参数→主要动作。滑块附数值输入或增减替代；裁剪支持比例和尺寸输入，不能只依赖拖动。长文件名中间省略且保留扩展名，详情面板显示完整名称。

已支持的语言沿用系统/简中/繁中/英文/西语/法语/德语；需预留30–40%正文扩展、短标签最多100%。RTL仅作为未来适配规则，不在当前语言列表中虚构。语言切换保留任务。减少动态效果开启时移除缩放与弹性动画，用短淡入；成功提示保持可访问，不依赖短暂toast传递保存结果。

## 素材与交付

`assets/coast-study.png`：由 Figma AI gpt-image-2.5-flare 生成的海岸摄影示例，不是增强算法效果的实测结果。提示词：Editorial travel photography for a photo editing app example: a quiet Mediterranean coastal village, terracotta buildings, aquamarine water, stone staircase, warm late-afternoon sunlight, realistic textures, tasteful cinematic composition, no people, no text, no logos, landscape 3:2 composition.

`assets/still-life-study.png`：由同一 Figma AI 模型生成的静物摄影示例。提示词：A tasteful editorial still-life photograph: a matte cobalt-blue ceramic vase holding a single branch of orange autumn leaves on a warm off-white linen table, sunlight creating a crisp diagonal shadow on the neutral plaster wall, close-up medium composition, beautiful tactile surfaces, natural colors, no text, no logos. Square image for sample content inside a local photo editing app.

品牌矢量使用裁切取景框、上升的图像斜面和光点，提供方形原稿及圆角显示预览；iOS交付不烘焙圆角；Android提供背景、前景与单色层。正式商店素材仍需按当期平台要求导出与真机审查。


## 验证边界与实施顺序

Figma 中已创建 52 个展示屏幕／状态，另有保持导出上下文的可点击原型。原型中的自动处理、保存与系统分享均为流程演示；图像内容与大小用于设计说明，不代表实测压缩率。当前设计稿覆盖 320×740、390×844、430×932，三种手机横屏，768×1024、1024×768 和 1366×768；另有英文、深色和大字号示例。系统 200% 字体、读屏、真机键盘、色彩管理和系统选择器需 Flutter 实现后验证。

建议先接入语义颜色／字体／间距与统一编辑框架，再落实无损编辑会话、统一导出和逐文件状态；最后接入质量参数、主题、分享和内存保护。四个移动工具继续使用已有 Rust 能力；Flutter 已落实，验证边界见各次 QA 记录。

图标资源在 `assets/app-icon-*`：1024px 不透明方形原稿、iOS SVG、Android 前景／背景、单色 SVG。设计检查截图、结构记录和对比度结果在 `qa/`。


## 折叠屏扩展

新增 iPhone Duo / 折叠屏设计，包含外屏、展开内屏、书本姿态、桌面姿态、左右 Split View、键盘、可用高度减少、导出与深色状态。新增稿沿用 Studio 语义颜色、字体和组件。

具体规则、尺寸边界、状态延续与 Flutter 接入建议见 `pages/foldable.md`。画布尺寸和系统保留区是设计采样，不能直接作为机型运行常量；实际按窗口约束和系统区域重排。Figma 中的姿态演示控件位于产品画面之外。

## 导入／保存入口核对

2026-11-10：手机导入面板与设计稿统一为「从相册导入 / 从文件导入」，附来源说明；覆盖首页、对比 A/B、裁剪、增强、替换和批量添加。两类选择器的类型、多选参数、取消结果有专门回归测试。批量从首张起支持多选；保存路径与导入来源互不绑定。桌面使用系统文件选择器，不展示移动端相册保存入口。

## 原生开屏

2026-11-11：iOS、Android 11 及以前、Android 12+ 已加入原生启动资源，沿用系统外观对应的 Studio 背景与 96pt/dp 品牌图形。首页首帧就绪即交接，不新增等待路由。平台差异、主题与折叠窗口边界见 [原生开屏规范](pages/launch.md)，验证记录见 [开屏 QA](qa/launch/REVIEW.md)。
