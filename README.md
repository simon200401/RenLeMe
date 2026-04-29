# 忍了么

「忍了么」是一款温柔坚定的反冲动 iOS App。它把每一次忍住转化成三类可见资产：省下的钱、守住的热量、拿回的时间。

## 当前实现

- SwiftUI 原生 iOS App，最低目标 iOS 17。
- SwiftData 本地存储 `ResistRecord` 和 `Goal`。
- 首页展示三类忍耐资产、今日忍住次数、目标进度、最近记录。
- 历史记录页支持按类型/状态筛选、查看详情、编辑和删除记录。
- 记录页支持金钱、食物、时间三类欲望，并可选择「我忍住了」「先放进冷静箱」「我还是做了」。
- 食物记录已接入本地启动热量库，可搜索食物、填写克重并自动计算 kcal。
- 冷静箱会请求本地通知权限，到点提醒「现在还想要它吗？」。
- 目标页支持新增目标，资产由已忍住记录实时计算。
- 我的页提供基础周/月统计、温柔成就和冷静箱处理。

## 项目框架

完整产品框架、信息架构、数据模型、关键流程、当前完成度和路线图见 [`PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md)。

## 产品需求

完整产品 PRD 见 [`PRD.md`](PRD.md)。

## 运行

用 Xcode 打开 `RenLeMe.xcodeproj`，选择 iPhone 模拟器运行。

当前机器的 active developer directory 是 CommandLineTools，不是完整 Xcode，因此命令行 `xcodebuild` 在本环境不可用。
