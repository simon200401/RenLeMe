# 自动测试

这两个测试是独立可执行程序，不属于 Xcode 的 Test target。需要安装并选中完整 Xcode；目标测试使用 macOS 14+ 的 SwiftData 内存数据库，不读取或修改 App 实际数据。

## 小忍动作

```sh
swiftc -module-cache-path /private/tmp/renleme-motion-cache \
  RenLeMe/MascotMotion.swift Tests/MascotMotionTests.swift \
  -o /private/tmp/renleme-motion-tests
/private/tmp/renleme-motion-tests
```

检查 24 个动作的幅度边界、手持道具、动作结束归位及不循环播放，以及三类成功动作、踱步、升级、点头等动作的关键姿势。

## 目标进度

```sh
swiftc -module-cache-path /private/tmp/renleme-goal-cache \
  RenLeMe/Models.swift RenLeMe/PropTemplates.swift \
  RenLeMe/StatsCalculator.swift RenLeMe/RecordInsights.swift Tests/GoalProgressTests.swift \
  -o /private/tmp/renleme-goal-tests
/private/tmp/renleme-goal-tests
```

检查单目标默认关联、同类目标一个一个攒和溢出、指定“先攒这个”、三类数值、冷静箱决定、编辑、重新关联及删除后的统计；还检查“我的”页回顾数据的门槛、心动高峰曲线、一起多少天、CSV 导出和冷静时长的文字。测试中的颜色定义仅满足道具模板的编译依赖，不影响 App 配色。

真机权限、键盘、导航、布局和通知交互仍需按 `QA_CHECKLIST.md` 验证。
