# 忍了么 RenLeMe

「忍了么」是一款轻量的冲动管理 iOS App。想买、想吃、想玩的时候，先停 15 秒再决定；忍住的部分变成三类看得见的成果：省下的钱、守住的热量、拿回的时间，并攒向自己设的目标。

2026-10-06 做过一轮以“让人愿意再打开”为目标的改版，页面结构和核心流程都变了，详见 [`HANDOFF.md`](HANDOFF.md)。发布状态见 [`RELEASE_READINESS.md`](RELEASE_READINESS.md)，其中的构建信息早于这轮改版。

## 快速理解

- 产品定位：低羞耻、强正反馈；不批评、不催促、不打分。
- 三个标签：今天、成果、我的。
- 核心闭环：点想买 / 想吃 / 想玩 -> 选物品 -> 停 15 秒 -> 做决定 -> 忍住后补数值 -> 成果、目标和小忍的等级更新。
- 三种结果：忍住了、冷静箱、没忍住。
- 数据策略：SwiftData 本地存储，不做账号、云同步、联网食物搜索；可导出 CSV。
- 视觉方向：高饱和卡通风，奶油底色，绿 / 粉 / 黄表示三类，米白色的小忍是贯穿全程的角色。

## 文档入口

- 给新对话窗口的交接文档：[`HANDOFF.md`](HANDOFF.md)
- 完整项目框架：[`PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md)
- 真机回归清单：[`QA_CHECKLIST.md`](QA_CHECKLIST.md)
- 上线准备清单：[`RELEASE_READINESS.md`](RELEASE_READINESS.md)
- 隐私政策草稿：[`PRIVACY_POLICY_DRAFT.md`](PRIVACY_POLICY_DRAFT.md)
- App Store 文案草稿：[`APP_STORE_LISTING_DRAFT.md`](APP_STORE_LISTING_DRAFT.md)
- 审核补充资料：[`APP_REVIEW_RESPONSE_2_1.md`](APP_REVIEW_RESPONSE_2_1.md)
- 自动测试运行方式：[`Tests/README.md`](Tests/README.md)
- 历史产品分析（非当前实现规范）：[`PRODUCT_ANALYSIS_2026-09-21.md`](PRODUCT_ANALYSIS_2026-09-21.md)

## 代码结构

```text
RenLeMe/
  RenLeMeApp.swift              App 入口、三个 Tab、启动页/新手引导、通知路由、种子数据
  Models.swift                  SwiftData 模型、核心枚举、设置项（AppSettings）
  PropTemplates.swift           物品模板（想买 28、想吃 22、想玩 14）
  StatsCalculator.swift         资产统计、目标分配（GoalLedger）、“正在攒”的目标（GoalFocus）
  RecordInsights.swift          “我的”页回顾数据、一起多少天、CSV 导出
  MascotGrowth.swift            小忍的等级
  WeeklySummary.swift           每周小结通知
  CooldownCoordinator.swift     冷静箱处理与到期通知
  HomeView.swift                今天：入口、待决定、目标
  PauseFlowView.swift           暂停流程：选物品、15 秒、决定、补数值
  ResultsView.swift             成果：资产、目标、最近记录
  ProfileView.swift             我的：回顾、里程碑、设置、冷静箱、导出、关于
  GrowthLadderView.swift        等级面板
  SlidingPeekMascot.swift       今天页底部随倾斜滑动的小忍
  RecordFlowView.swift          直接记录
  GoalsView.swift               全部目标、新增/编辑/删除目标
  HistoryRecordsView.swift      历史筛选列表
  RecordDetailView.swift        记录详情与冷静箱决定
  EditRecordView.swift          编辑记录
  FoodPickerView.swift          本地食物库搜索与份量计算
  FoodSeedData.swift            本地食物种子库
  Components.swift              共享 UI、图标、反馈弹窗、气泡、冷静箱操作面板
  PropGlyphs.swift              第二批物品图标
  QuickEntry.swift              App 外的入口：图标长按菜单、Siri 和快捷指令、链接
  WidgetSnapshot.swift          App 和小组件共用的快照（两个 target 都编译）
  WidgetBridge.swift            App 把快照写给小组件
  CooldownActivity.swift        冷静倒计时实时活动的数据和按钮动作（两个 target 都编译）
  CooldownLiveActivity.swift    App 开始、更新、结束实时活动；全 App 共用的数据库
  GoalAchievement.swift         目标的收尾卡和“已实现”陈列页
  WelcomeOnboardingView.swift   新手引导；小忍的绘制（AnimatedXiaoRenView）和全部表情
  MascotMotion.swift            小忍的动作
  MascotAttention.swift         小忍的眼睛跟手指
  Celebration.swift             彩带
  LaunchSplashView.swift        启动过渡页
release-site/                   已部署的帮助与隐私页面（renleme.netlify.app）
release-site-drafts/            还没启用的反馈表单
Tests/                          两组独立自动测试
```

## 运行方式

用 Xcode 打开 `RenLeMe.xcodeproj`，选择 iPhone Simulator 或真机运行。当前工程面向 iOS 17+，只支持 iPhone 竖屏，本地数据使用 SwiftData。倾斜、震动、通知和相机只能在真机上验证。

说明：Debug、Release 与 TestFlight 均不自动插入 Demo 记录或默认目标。干净安装从零记录、零资产和空目标开始，仅保留内置食物库；覆盖安装不会清除已有真实记录。

常用静态检查：

```bash
swiftc -parse RenLeMe/*.swift
plutil -lint RenLeMe.xcodeproj/project.pbxproj
```

灵动岛扩展已移除。冷静箱只使用 App 内处理和本地通知，不需要额外扩展签名。
