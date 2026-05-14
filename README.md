# 忍了么 RenLeMe

「忍了么」是一款面向冲动消费、饮食控制、时间管理场景的轻量化 iOS App。它帮助用户在“想买、想吃、想刷”的瞬间先记录、再决定，并把忍住后的价值转化成三类可见资产：省下的钱、守住的热量、拿回的时间。

当前版本是可运行 Demo，已覆盖首页、记录、目标、我的、历史详情、编辑、冷静箱、新手引导、App 图标与启动页等主流程。

## 快速理解

- 产品定位：低羞耻、强正反馈的反冲动自我管理工具。
- 核心闭环：选择冲动类型 -> 选择/自选道具 -> 填写数值 -> 做决定 -> 首页资产/目标/复盘更新。
- 三类场景：金钱、食物、时间。
- 三种结果：忍住了、冷静箱、没忍住。
- 数据策略：SwiftData 本地存储，不做账号、不做云同步、不做联网食物搜索。
- 视觉方向：高饱和卡通风，奶油底色、绿色/粉色/黄色/蓝色分类、小忍动态角色反馈。

## 文档入口

- 给新对话窗口的交接文档：[`HANDOFF.md`](HANDOFF.md)
- 完整项目框架：[`PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md)
- 原始产品需求：[`PRD.md`](PRD.md)
- 真机回归清单：[`QA_CHECKLIST.md`](QA_CHECKLIST.md)

## 代码结构

```text
RenLeMe/
  RenLeMeApp.swift              App 入口、Tab、启动页/新手引导、种子数据
  Models.swift                  SwiftData 模型与核心枚举
  PropTemplates.swift           道具模板系统
  StatsCalculator.swift         资产、目标、周/月统计计算
  Components.swift              共享 UI、道具图标、小忍、反馈弹窗、键盘处理
  HomeView.swift                首页资产、目标进度、最近记录
  RecordFlowView.swift          记录流程、道具选择、自选图片、冷静箱通知
  GoalsView.swift               目标列表、新增/编辑目标
  ProfileView.swift             复盘、统计、成就、冷静箱处理、引导入口
  HistoryRecordsView.swift      历史筛选列表
  RecordDetailView.swift        记录详情
  EditRecordView.swift          编辑记录
  FoodPickerView.swift          本地食物库搜索与份量计算
  FoodSeedData.swift            本地食物种子库
  LaunchSplashView.swift        自定义启动过渡页
  WelcomeOnboardingView.swift   动态小忍新手引导
```

## 运行方式

用 Xcode 打开 `RenLeMe.xcodeproj`，选择 iPhone Simulator 运行。当前工程面向 iOS 17+，本地数据使用 SwiftData。

常用静态检查：

```bash
swiftc -parse RenLeMe/*.swift
plutil -lint RenLeMe.xcodeproj/project.pbxproj
```
