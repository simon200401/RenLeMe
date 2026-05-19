# 「忍了么」项目框架说明

更新时间：2026-05-14

## 1. 一句话定位

「忍了么」是一款温柔但有行动感的冲动管理 iOS App。它面向容易冲动消费、控制饮食或浪费时间的年轻用户，帮助用户在“想买、想吃、想刷”的瞬间先记录、再决定，通过正反馈降低自责感，提升自我管理的持续性。

核心不是“管住用户”，而是让用户重新拿回选择权。

## 2. 产品主线

用户每次产生冲动时，App 引导用户完成一次轻量记录：

1. 选择欲望类型：金钱、食物、时间。
2. 选择具体道具：内置模板或自选道具。
3. 填写数值：金额、kcal、分钟。
4. 做一个决定：我忍住了、先放进冷静箱、我还是做了。
5. 结果进入首页资产、目标进度、历史记录、我的页复盘。

三种结果的语义：

- `忍住了`：计入资产，给正反馈。
- `冷静箱`：延迟决定，暂不计入资产，到期提醒用户再判断。
- `没忍住`：不扣分、不羞辱，作为复盘数据沉淀。

## 3. 当前信息架构

App 使用 4 个底部 Tab。

### 首页

首页负责即时正反馈，展示用户“拿回了什么”。

当前模块：

- Today 顶部卡片与周点阵。
- 我的忍耐资产：省下的钱、守住的热量、拿回的时间。
- 目标去向：默认目标与进度卡。
- 最近记录：显示具体道具、状态、时间。
- 右下角快速入口：忍一下。

首页设计原则：

- 资产卡保留强色块和大数字。
- 小忍在资产卡中只承担正反馈，不使用焦虑/纠结表情。
- 最近记录减少装饰小忍，优先突出记录信息和具体道具。

### 记录页

记录页是核心使用场景，当前流程为：

1. 选择欲望类型。
2. 选择一个具体道具。
3. 填写价值。
4. 做一个决定。

关键行为：

- 第二部分道具选择默认收缩。
- 自选道具固定在第一位，展开后才显示内置模板。
- 已选道具再次点击可以取消。
- 食物模板有默认 kcal，用户不填时使用默认值。
- 时间类、金钱类默认要求用户输入数值。
- 自选道具支持相册/拍照上传图片，模拟器不支持真机拍照时按钮会置灰。
- 输入键盘可通过“完成”、下滑或点击空白收起。

### 目标页

目标页把忍住的价值投向具体目标。

当前模块：

- 默认目标：新相机基金、本周少喝 3 杯奶茶、本周拿回 10 小时。
- 新增目标。
- 编辑目标。
- 删除目标。
- 每张目标卡显示具体道具、进度、状态小忍。

目标计算规则：

- 优先统计关联了该目标 `goalId` 的 `resisted` 记录。
- 未关联记录不自动计入具体目标。
- 目标值不改变记录本身，只用于进度展示。

### 我的页

我的页负责复盘、统计和冷静箱处理。

当前模块：

- Review 复盘卡。
- 基础统计：本周忍住、本月忍住、冷静箱数量。
- 复盘趋势：本周记录节奏。
- 本周三类资产统计。
- GoalGoalGoal 成就区。
- 冷静箱列表。
- 再看一遍上手引导入口。

复盘语气：

- 不使用“失败”“堕落”“管不住”等惩罚词。
- `gaveIn` 展示为“没忍住”，但语义仍是观察数据。

## 4. 数据模型

当前使用 SwiftData 本地持久化。

### ResistRecord

一次冲动记录。

核心字段：

- `id`
- `typeRaw`: money / food / time
- `title`
- `value`
- `unitRaw`: cny / kcal / minute
- `statusRaw`: resisted / pending / gaveIn
- `reason`
- `createdAt`
- `resolvedAt`
- `cooldownUntil`
- `enteredCooldown`
- `note`
- `goalId`

食物库相关字段：

- `foodNutritionItemId`
- `foodSourceName`
- `foodSourceVersion`
- `foodServingGrams`
- `foodEnergyKcalPer100g`

道具系统相关字段：

- `propTemplateId`
- `propIconKeyRaw`
- `customImagePath`

### Goal

目标模型。

字段：

- `id`
- `title`
- `typeRaw`
- `targetValue`
- `deadline`
- `icon`
- `createdAt`

### FoodNutritionItem

本地食物库条目。

字段：

- `name`
- `aliasesText`
- `category`
- `energyKcalPer100g`
- `defaultServingName`
- `defaultServingGrams`
- `sourceName`
- `sourceVersion`
- `sourceFoodId`
- `state`
- `isVerified`
- `updatedAt`

## 5. 道具模板系统

文件：`PropTemplates.swift`

UI-only 配置层，但记录会保存 `propTemplateId` 和 `propIconKeyRaw`，用于后续显示具体图标。

分类：

- `ui`：软件 UI 资产，蓝色，不进入主记录选择路径。
- `food`：食物类，粉色，单位 kcal。
- `time`：时间类，黄色，单位 minute。
- `money`：金钱类，绿色，单位 cny。

当前模板：

- 食物：奶茶、零食、外卖、甜品、炸鸡。
- 时间：时钟、打游戏、追剧、短视频、睡觉、闲聊、熬夜、拖延。
- 金钱：钱包、相机、衣服、游戏设备、杂物、手机、电脑、首饰、会员、化妆品、鞋子、包、盲盒、旅行、报课。
- UI：冷静箱、成就、日历、统计。

默认值策略：

- 奶茶 420 kcal。
- 零食 180 kcal。
- 外卖 800 kcal。
- 甜品 320 kcal。
- 炸鸡 620 kcal。
- 金钱和时间类由用户自填。

匹配规则：

- 优先用 `propTemplateId`。
- 其次用 `propIconKeyRaw`。
- 最后用记录标题和模板标题做模糊匹配。
- 匹配失败时走 fallback 图标或通用道具。

## 6. 食物体系

当前策略是“本地轻量食物库 + 模板默认 kcal”，不做联网搜索。

实现：

- `FoodSeedData.swift` 提供本地食物库种子。
- `FoodPickerView.swift` 支持本地搜索、选择食物、填写克重。
- 选择本地食物后按 `kcal/100g * servingGrams` 计算。
- 找不到食物时，用户可回到模板默认 kcal 或手动填写。

产品边界：

- 不做联网食物搜索。
- 不做拍照识别食物。
- 不声明营养医学权威，只作为轻量估算。

## 7. 小忍反馈系统

小忍不是装饰贴纸，而是根据用户行为出现的情绪反馈角色。

核心枚举：

- `MascotMood`
- `MascotMoment`
- `DynamicMascotExpression`

主要场景：

- `idle`：默认/平静。
- `choosing`：用户正在选择。
- `resistedSuccess`：忍住成功。
- `coolingSaved`：放进冷静箱。
- `gaveInSaved`：没忍住后的温柔反馈。
- `observingRecord`：历史/记录中的观察状态。
- `assetPositive`：首页资产正反馈。
- `goalProgress`：目标有进展。
- `goalCompleted`：目标完成。
- `reviewCalm`：我的页复盘。

交互方式：

- 首页三张资产卡点击后有轻微抖动/触感反馈，并触发小忍动态反应。
- 记录页做决定后使用小忍反馈弹窗。
- 冷静箱处理后给对应反馈。
- 目标卡根据进度展示不同小忍状态。
- 新手引导中的小忍是动态绘制，不是静态贴图。
- Respect Reduce Motion：减少明显弹跳动画。

## 8. 视觉系统

当前方向：强色块卡通风。

核心元素：

- 奶油底色。
- 粗黑圆体字。
- 大圆角色块卡片。
- 黑色主按钮。
- 分类色：
  - 金钱：绿色。
  - 食物：粉色。
  - 时间：黄色。
  - UI：蓝色。
- 小忍：米白/绿色/粉色/黄色等状态变化，白色粗边、轻阴影。

已执行的体验取舍：

- 删除大量解释性文案，避免页面啰嗦。
- 图标不再无意义堆叠，重点道具和小忍分工明确。
- 记录页道具区默认收起，降低首屏滚动压力。
- 复盘页和最近记录减少外显装饰，避免信息噪音。

## 9. App 启动和新手引导

文件：

- `LaunchSplashView.swift`
- `WelcomeOnboardingView.swift`

当前行为：

- 启动后展示自定义启动过渡页，文案为“忍一下”。
- 首次进入展示新手引导弹窗，背景淡化。
- 引导包含完整页面介绍和产品上手流程。
- 完成后用 `@AppStorage("didCompleteWelcomeOnboarding")` 记录，不再自动弹出。
- 我的页保留“再看一遍上手引导”入口。

## 10. 种子数据

入口：`RenLeMeApp.swift`

使用 `@AppStorage` 防止重复插入：

- `didSeedDefaultGoals`
- `didSeedFoodNutritionItems`
- `didSeedDemoRecords`
- `didCompleteWelcomeOnboarding`

默认目标：

- 新相机基金。
- 本周少喝 3 杯奶茶。
- 本周拿回 10 小时。

Demo 记录：

- 奶茶：忍住了，420 kcal。
- 短视频：冷静箱，30 min。
- 相机：忍住了，¥128。
- 外卖：没忍住，800 kcal。

上线策略：

- Demo 记录只在 Debug 构建中自动插入。
- Release/TestFlight 默认不插入 Demo 记录，保证正式用户首次进入不会看到假历史。
- 默认目标和本地食物库保留，用作产品模板和初始可用能力。

## 11. 统计规则

文件：`StatsCalculator.swift`

核心规则：

- 只有 `status == .resisted` 计入资产。
- `pending` 不计入资产。
- `gaveIn` 不计入资产，只进入复盘/历史。
- 三类资产不互相换算。
- 时间内部以分钟保存，大于等于 60 分钟时可展示为小时。

当前支持：

- 全量资产统计。
- 目标当前值统计。
- 某类型总资产。
- 今日忍住次数。
- 本周忍住记录。
- 本月忍住记录。
- 近 7 天每日忍住次数。
- 当前连续天数。
- 本周最强类型。
- 最常见触发原因。

## 12. 当前完成度

已完成：

- 原生 SwiftUI 工程。
- SwiftData 本地存储。
- 四 Tab 主架构。
- 首页、记录、目标、我的完整主流程。
- 历史、详情、编辑、删除。
- 道具模板系统。
- 自选道具与相册/拍照图片。
- 本地食物库与份量计算。
- 冷静箱与本地通知。
- 小忍情绪反馈弹窗。
- 首页资产卡互动。
- 动态新手引导。
- App 图标。
- 自定义启动页。
- Demo 种子数据。
- 上线准备清单。
- 隐私政策草稿。
- 产品交付版 PPT：`outputs/manual-portfolio/presentations/renleme-portfolio/output/RenLeMe-Product-Presentation.pptx`

仍需补强：

- 单元测试和 UI 测试。
- 真机多尺寸完整回归。
- 更细的趋势统计图表。
- 冷静箱提醒设置页。
- 目标 deadline 的完整 UI。
- 隐私政策 URL、支持 URL 和 App Store 上架材料。
- 用户自建食物库编辑入口。

已新增但仍需外部部署：

- `RELEASE_READINESS.md`
- `PRIVACY_POLICY_DRAFT.md`
- `APP_STORE_LISTING_DRAFT.md`

隐私政策草稿需要在提交 App Store 前部署为公开 URL。

## 13. 建议实现路径

如果新对话窗口继续开发，建议按下面顺序推进：

1. 先读 `HANDOFF.md`、`README.md`、`PROJECT_OVERVIEW.md`。
2. 跑 `swiftc -parse RenLeMe/*.swift` 和 `plutil -lint RenLeMe.xcodeproj/project.pbxproj`。
3. 用 Xcode 或 XcodeBuildMCP 在 iPhone Simulator 跑一遍首页、记录、目标、我的。
4. 按 `QA_CHECKLIST.md` 做真机回归。
5. 再进入具体功能开发，避免一上来重构视觉或模型。

优先级建议：

- P0：修复任何编译/启动/主流程阻断。
- P1：真机体验、滚动、键盘、触控、图片权限。
- P2：隐私 URL、支持 URL、App Store 截图和上架材料。
- P3：统计增强、冷静箱设置、用户自建食物库。
- P4：云同步、账号、AI 教练等长期能力。

## 14. 验证命令

```bash
swiftc -parse RenLeMe/*.swift
plutil -lint RenLeMe.xcodeproj/project.pbxproj
```

模拟器验证建议：

- 首次启动：启动页 -> 新手引导 -> 首页。
- 记录页：金钱/食物/时间切换，道具展开/收起，自选道具，三种决策。
- 食物库：搜索已有食物、搜索不存在食物、份量计算。
- 冷静箱：新增 pending、我的页处理为忍住/没忍住。
- 目标：新增、编辑、删除，进度正确。
- 历史：筛选、详情、编辑、删除。

## 15. 重要产品约束

- 不做羞辱式自律。
- 不做惩罚机制。
- 不把没忍住叫失败。
- 不做联网食物搜索。
- 不把三类资产合并成一个总分。
- 不随意堆小忍，小忍必须对应具体用户行为或情绪反馈。
- 不在页面放太多解释性文案，优先让 UI 本身表达功能。
