# 「忍了么」项目框架说明

更新时间：2026-10-07

## 1. 一句话定位

「忍了么」是一款温柔但有行动感的冲动管理 iOS App。它面向容易冲动消费、控制饮食或浪费时间的年轻用户，帮助用户在“想买、想吃、想刷”的瞬间先记录、再决定，通过正反馈降低自责感，提升自我管理的持续性。

核心不是“管住用户”，而是让用户重新拿回选择权。

## 2. 产品主线

用户产生冲动时，App 先帮他停一下，再让他决定：

1. 在“今天”点想买、想吃或想玩。
2. 选一样物品（或自填）。
3. 停 15 秒：三次呼吸，小忍陪着。
4. 做一个决定：我忍住了、再等等、我还是做了。
5. 忍住之后再补数值（可不填），并投向一个目标。
6. 结果进入成果、目标进度、小忍的等级和“我的”页回顾。

三种结果的语义：

- `忍住了`：计入成果，给正反馈。
- `冷静箱`：延迟决定，暂不计入，到期提醒再判断。
- `没忍住`：不扣分、不羞辱，只是一条记录。

已经做完决定、只想记一笔时，走“直接记录”（原来的完整表单）。

## 3. 当前信息架构

App 使用 3 个底部 Tab：今天、成果、我的。各页的内容和顺序见 [`HANDOFF.md`](HANDOFF.md) 的“页面结构”，这里只列职责。

### 今天

做事的地方：开始一次暂停，处理冷静箱里待决定的东西，看一眼目标。文件：`HomeView.swift`、`PauseFlowView.swift`、`SlidingPeekMascot.swift`、`GrowthLadderView.swift`。

### 成果

看得见的东西：三类资产、目标（“资产去向”）、最近记录；从这里进入全部目标和历史记录。文件：`ResultsView.swift`、`GoalsView.swift`、`HistoryRecordsView.swift`、`RecordDetailView.swift`、`EditRecordView.swift`。

### 我的

了解自己和调整 App：我和小忍、冷静箱、回顾、里程碑、提醒、偏好、数据与帮助。文件：`ProfileView.swift`、`RecordInsights.swift`、`WeeklySummary.swift`。

### 直接记录

完整表单：类型、物品（含自选图片）、数值、原因、备注、目标、三种决定。文件：`RecordFlowView.swift`、`FoodPickerView.swift`。

## 4. 数据模型

当前使用 SwiftData 本地持久化。

### ResistRecord

一次冲动记录。

核心字段：

- `id`
- `typeRaw`: money / food / time
- `title`
- `value`
- `hasEstimatedValue`：数值是否已填写，待补充记录不计入资产。
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
- `customImagePath`
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

当前模板（完整列表以 `PropTemplates.swift` 为准）：

- 想吃 22 个：奶茶、可乐、薯片、炸鸡、汉堡、薯条、蛋糕、冰淇淋、巧克力、泡面、披萨、蛋挞、甜甜圈、啤酒、外卖、火锅、烧烤、麻辣烫、夜宵、辣条、零食、甜品。
- 想玩 14 个：短视频、打游戏、追剧、刷社交、逛购物 App、熬夜、拖延、看直播、看小说、摸鱼、赖床、闲聊、睡觉、时钟。
- 想买 28 个：衣服、护肤彩妆、鞋子、包、游戏充值、耳机、数码配件、盲盒、手办潮玩、会员、直播打赏、咖啡、打车等。
- UI：冷静箱、成就、日历、统计（不进入选择路径）。

暂停流程里按用户的使用次数排序，默认显示 10 个，其余在“更多”里。

默认值策略：

- 想吃类只有份量明确的才给默认热量，份量写在模板的 `caption` 里并在补数值页显示（例如“1 罐 330ml 含糖 ≈ 140 kcal”）。共 14 项。
- 份量不确定的（外卖、火锅、烧烤、麻辣烫、夜宵、辣条、零食、甜品）不给默认值。
- 奶茶 420 是典型值，不同店家同规格可差一倍；薯条、蛋糕、冰淇淋、巧克力、披萨、甜甜圈、啤酒 7 项的数值没有核对来源。
- 想买和想玩由用户自填，补数值页有快捷数值。

匹配规则：

- 优先用 `propTemplateId`。
- 其次用 `propIconKeyRaw`。
- 最后用记录标题和模板标题匹配：先找完全相同的，再做模糊匹配。
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
- `MascotReaction` / `MascotMotionSample`：短动作及姿态参数，定义在 `MascotMotion.swift`。

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

- 所有小忍默认有呼吸起伏，眼睛看向手指（`MascotAttention.swift`），每次进入页面换一个适合该位置的表情（`MascotVariety`）。
- 今天页顶部的小忍根据最近发生的事决定表情和开场白；可以戳（害羞、头晕、背过身）、拉伸；放着不动会睡着。
- 暂停页的小忍有四个专属表情：馋、鼓气、吹气、放下了，跟着三次呼吸切换。
- 三类忍住成功的动作不同（抱紧钱包、推开杯子、按停闹钟），都以跳起转圈收尾；升级时先缩后弹大。
- 决定页按下按钮时小忍先点头或轻拍，再生效。
- 今天页底部和成果页底部各有一只藏在线后面的小忍：前者随手机倾斜滑动、点一下跳出来，后者点一下缩回去。
- 等级：见第 11 节。
- 动作短暂播放后回到安静状态；页面离开、进入后台、输入或弹窗遮挡时暂停。Reduce Motion 下不播放动作。
- 颜色：页面上的小忍是米白色，绿、粉、黄只表示三类；保留白色描边。

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

文件：`LaunchScreen.storyboard`、`LaunchSplashView.swift`、`WelcomeOnboardingView.swift`。

- 系统启动画面是米色背景加小忍图案（用户要求保留图案）。
- 之后是约 1.5 秒的自定义启动过渡页。
- 首次进入展示 6 页新手引导，文案已按新流程改写。
- 完成后用 `@AppStorage("didCompleteWelcomeOnboarding")` 记录；“我的 → 再看一遍引导”可重看。

## 10. 种子数据

入口：`RenLeMeApp.swift`

使用 `@AppStorage` 防止重复插入：

- `didSeedFoodNutritionItems`
- `didCompleteWelcomeOnboarding`

上线策略：

- Debug、Release 和 TestFlight 均不插入 Demo 记录，启动注入逻辑已移除。
- 不插入默认目标；旧测试版只清理准确匹配的三张系统预设目标，用户自建目标保留。
- 已有记录在覆盖安装时保留，旧示例可以手动删除。
- 本地食物库保留，用作产品初始可用能力。

## 11. 统计规则

文件：`StatsCalculator.swift`、`RecordInsights.swift`、`MascotGrowth.swift`。

资产：

- 只有 `status == .resisted` 且有数值的记录计入；`pending`、`gaveIn` 不计入。
- 三类不互相换算。时间内部以分钟保存，满 60 分钟时展示为小时。
- 一周是周一到周日（`Calendar.mondayFirst`）。
- 本周、本月、全部，以及“今天的次数”，都按决定时间归属（旧记录回退到创建时间）。

目标（`GoalLedger`）：

- 一笔记录只投给一个目标；同类目标一个一个攒，有一个“正在攒”的目标（`GoalFocus`，用户可指定）。
- 超过目标值的部分流到同类的下一个目标，不跨类。
- 分配在显示时计算，不改记录。`StatsCalculator.currentValue` 是分配之前的原始数，界面一律用 `GoalLedger`。

等级（`MascotGrowth`）：

- 按累计忍住次数，门槛 0、3、10、25、50、100，只升不降。

回顾（`RecordInsights`）：

- “心动高峰”按每次冲动出现的钟点统计，不论结果；满 5 笔才显示，曲线做过平滑，标题里的时段按真实次数算。
- 三类各忍住几次。
- 还保留着三项界面没用的计算（三类比例、冷静后比例、最想要的东西），有测试覆盖。
- 页面上不出现带分母的“率”。

## 12. 当前完成度

已完成：

- 三 Tab 架构：今天、成果、我的。
- 暂停流程、冷静箱（叠放和展开）、直接记录。
- 目标：新增、编辑、删除、一个一个攒和溢出。
- 小忍：等级、23 个表情、24 个动作、眼睛跟手、戳和拉伸、会说话。
- “我的”：回顾、里程碑、冷静到期提醒、每周小结、冷静时长（含自定义）、震动、CSV 导出、邮件反馈。
- 历史、详情、编辑、删除；本地食物库；新手引导；App 图标和启动页。
- 帮助站和隐私政策已按新流程更新并部署。

仍需补强：

- 没有 UI 自动测试；交互流程靠真机手动回归（`QA_CHECKLIST.md`）。
- 性能和耗电没有测过（所有小忍持续做动画）。
- 想吃类 7 项默认热量未核对；新增物品沿用旧图标。
- 帮助站的反馈表单未启用。
- 发布材料（截图、文案、构建）是改版之前的，需要重做。

发布材料：`RELEASE_READINESS.md`、`PRIVACY_POLICY_DRAFT.md`、`APP_STORE_LISTING_DRAFT.md`、`APP_REVIEW_RESPONSE_2_1.md`。隐私政策与支持页源码在 `release-site/`，已部署到 `https://renleme.netlify.app/privacy.html` 和 `https://renleme.netlify.app/support.html`。

## 13. 建议实现路径

如果新对话窗口继续开发：

1. 先读 `HANDOFF.md`，尤其是“用户明确否掉的做法”。
2. 跑 `Tests/README.md` 里的两组测试，再用 Xcode 构建。
3. 界面改动先出草图或实际渲染给用户看，再动 App。
4. 改完装到模拟器或真机再说“改好了”；模拟器的点击注入不可靠，交互要请用户在真机上确认。

## 14. 验证命令

```bash
plutil -lint RenLeMe.xcodeproj/project.pbxproj
xcodebuild -project RenLeMe.xcodeproj -scheme RenLeMe -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

自动测试见 `Tests/README.md`。

## 15. 重要产品约束

- 不做羞辱式自律，不做惩罚机制，不把没忍住叫失败。
- 不打分：不出现忍住率、百分比评价。
- 不做会归零的东西（连续天数、会熄灭的成就）。
- 不催促：提醒默认关闭或可关，没有记录的那一周不发小结。
- 不做联网食物搜索；不把三类资产合并成一个总分。
- 不随意堆小忍，小忍必须对应具体行为；不新增小忍的配色。
- 不在页面放太多解释性文案，优先让 UI 本身表达功能。
