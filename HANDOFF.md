# 忍了么项目交接文档

这份文档用于把当前项目交给另一个对话窗口或开发者，让对方快速接上上下文。

## 项目是什么

「忍了么」是一款冲动管理 iOS App。用户在想买东西、想吃高热量食物、想刷短视频/游戏/熬夜时，可以先记录这次冲动，再选择：

- 我忍住了。
- 先放进冷静箱。
- 我还是做了。

App 把“忍住”转化成三类可见资产：

- 省下的钱。
- 守住的热量。
- 拿回的时间。

产品语气是低羞耻、强正反馈、温柔复盘。核心价值不是批评用户，而是让用户多一次选择权。

## 当前版本状态

这是一个可运行的 SwiftUI + SwiftData Demo，已完成主流程。

已完成：

- 首页资产总览。
- 记录页完整流程。
- 道具模板系统。
- 自选道具图片。
- 本地食物库和 kcal 计算。
- 冷静箱和本地通知。
- 目标创建、编辑、删除、进度展示。
- 我的页统计、复盘、成就、冷静箱处理。
- 历史列表、详情、编辑、删除。
- 小忍动态反馈系统。
- 首次启动新手引导。
- App 图标和自定义启动页。
- 上线准备清单和隐私政策草稿。

还未完成或待加强：

- 单元测试/UI 测试。
- App Store 隐私政策 URL 和支持 URL 部署。
- 真机多尺寸完整回归。
- 更完整的趋势图表。
- 冷静箱提醒设置页。
- 用户自建食物库编辑入口。

## 技术栈

- iOS 17+
- SwiftUI
- SwiftData
- UserNotifications
- UIKit bridge for camera/photo picker
- 本地 AppStorage 做种子数据和引导状态

不使用：

- 账号系统。
- 云同步。
- 后端服务。
- 联网食物搜索。
- 外部图片资产库。

## 核心代码入口

```text
RenLeMe/RenLeMeApp.swift
```

负责：

- App 入口。
- SwiftData modelContainer。
- 四个 Tab。
- 启动页和新手引导 overlay。
- 默认目标、食物库、Demo 记录种子数据。
- Release/TestFlight 默认不插入 Demo 假记录。

```text
RenLeMe/Models.swift
```

负责：

- `ResistType`
- `ValueUnit`
- `ResistStatus`
- `ResistRecord`
- `Goal`
- `FoodNutritionItem`

```text
RenLeMe/PropTemplates.swift
```

负责：

- 道具分类。
- 道具图标 key。
- 内置道具模板。
- 模板匹配规则。

```text
RenLeMe/Components.swift
```

负责：

- 视觉系统。
- 小忍绘制和小忍反馈弹窗。
- 道具图标。
- 卡片、按钮、状态 chip、进度条。
- 本地图片存储 helper。
- 键盘收起 modifier。

```text
RenLeMe/RecordFlowView.swift
```

负责：

- 记录主流程。
- 类型选择。
- 道具选择和自选道具。
- 拍照/相册。
- 食物库入口。
- 数值填写。
- 三种决策保存。
- 冷静箱通知。

```text
RenLeMe/HomeView.swift
RenLeMe/GoalsView.swift
RenLeMe/ProfileView.swift
```

负责三大主页面。

```text
RenLeMe/HistoryRecordsView.swift
RenLeMe/RecordDetailView.swift
RenLeMe/EditRecordView.swift
```

负责历史、详情、编辑。

## 数据模型重点

`ResistRecord` 是核心模型。

重要字段：

- `typeRaw`: money / food / time
- `statusRaw`: resisted / pending / gaveIn
- `title`
- `value`
- `unitRaw`
- `reason`
- `goalId`
- `cooldownUntil`
- `enteredCooldown`
- `propTemplateId`
- `propIconKeyRaw`
- `customImagePath`
- 食物来源字段：`foodNutritionItemId`、`foodServingGrams`、`foodEnergyKcalPer100g`

状态语义：

- `resisted` 展示为“忍住了”，计入资产。
- `pending` 展示为“冷静箱”，暂不计入资产。
- `gaveIn` 展示为“没忍住”，不计入资产，不惩罚。

## 产品规则

资产统计：

- 只统计 `resisted`。
- 不统计 `pending`。
- 不统计 `gaveIn`。
- 金钱、kcal、分钟互不换算。

食物记录：

- 优先用具体模板：奶茶、零食、外卖、甜品、炸鸡。
- 模板有默认 kcal。
- 用户手动填写时优先用户输入。
- 本地食物库用于更精确的克重计算。
- 不做联网搜索。

目标：

- 默认目标是新相机基金、本周少喝 3 杯奶茶、本周拿回 10 小时。
- 目标进度优先由关联 `goalId` 的 resisted 记录计算。

冷静箱：

- 金钱默认 24 小时。
- 食物默认 10 分钟。
- 时间默认 15 分钟。
- 到期发本地通知。

上线注意：

- Demo 假记录只在 Debug 构建中自动插入。
- Release/TestFlight 默认不插入 Demo 假记录。
- 默认目标和本地食物库仍会种子插入，作为产品初始模板能力。

## 视觉和交互方向

当前设计方向：

- 高饱和卡通风。
- 奶油底色。
- 粗黑圆体字。
- 大色块卡片。
- 黑色胶囊按钮。
- 金钱绿、食物粉、时间黄、UI 蓝。
- 小忍作为情绪反馈角色。

重要设计约束：

- 页面里不要堆解释性文案。
- 不要随便堆小忍，小忍要对应用户行为。
- 最近记录里优先显示信息，不要让小忍喧宾夺主。
- 资产卡可以有小忍正反馈。
- 记录页小忍用于“冲动当下”和“做决定后”的反馈。
- 我的页复盘小忍要平静，不要焦虑。

## 当前生成资产

产品 PPT：

```text
outputs/manual-portfolio/presentations/renleme-portfolio/output/RenLeMe-Product-Presentation.pptx
```

模拟器截图素材：

```text
outputs/manual-portfolio/presentations/renleme-portfolio/assets/app-screens/
```

这些 `outputs/` 当前未纳入 Git 版本控制，属于作品集/展示产物。

上线相关文档：

```text
RELEASE_READINESS.md
PRIVACY_POLICY_DRAFT.md
APP_STORE_LISTING_DRAFT.md
```

## 运行和验证

用 Xcode 打开：

```text
RenLeMe.xcodeproj
```

静态验证：

```bash
swiftc -parse RenLeMe/*.swift
plutil -lint RenLeMe.xcodeproj/project.pbxproj
```

模拟器建议用 iPhone 17 Pro 或接近尺寸设备验证。

必须手动跑的主流程：

- 首次启动和新手引导。
- 首页资产卡点击反馈。
- 记录页金钱/食物/时间三类流程。
- 自选道具相册/真机拍照。
- 食物库搜索和克重计算。
- 三种决策保存。
- 冷静箱处理。
- 目标新增/编辑/删除。
- 历史筛选、详情、编辑、删除。
- 我的页引导入口和冷静箱列表。

## 下一步建议

最优先：

- 做一次真机完整回归，尤其是拍照权限、相册权限、通知权限、键盘收起、滚动区域。
- 补最小单元测试，优先覆盖 `StatsCalculator`。
- 部署隐私政策和支持页面 URL。

暂时不要：

- 不要引入后端。
- 不要做联网食物搜索。
- 不要大改 SwiftData 模型，除非确认迁移方案。
- 不要把 App 变成复杂习惯打卡或重型健康管理。
