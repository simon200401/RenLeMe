# 自动测试

这两个测试是独立可执行程序，不属于 Xcode 的 Test target。需要安装并选中完整 Xcode；目标测试使用 macOS 14+ 的 SwiftData 内存数据库，不读取或修改 App 实际数据。

## 小忍动作

```sh
swiftc -module-cache-path /private/tmp/renleme-motion-cache \
  RenLeMe/MascotMotion.swift Tests/MascotMotionTests.swift \
  -o /private/tmp/renleme-motion-tests
/private/tmp/renleme-motion-tests
```

检查动作边界、手持道具、表情差异、动作结束归位及不循环播放。

## 目标进度

```sh
swiftc -module-cache-path /private/tmp/renleme-goal-cache \
  RenLeMe/Models.swift RenLeMe/PropTemplates.swift \
  RenLeMe/StatsCalculator.swift Tests/GoalProgressTests.swift \
  -o /private/tmp/renleme-goal-tests
/private/tmp/renleme-goal-tests
```

检查单目标默认关联、多目标不自动分配、三类数值、冷静箱决定、编辑、重新关联及删除后的统计。测试中的颜色定义仅满足道具模板的编译依赖，不影响 App 配色。

真机权限、键盘、导航、布局和通知交互仍需按 `QA_CHECKLIST.md` 验证。
