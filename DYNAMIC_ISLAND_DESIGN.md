# 小忍灵动岛设计方案

更新时间：2026-05-19

## 1. 设计定位

小忍不常驻灵动岛，只在“冷静箱倒计时”期间以 Live Activity 出现。

产品语义：

> 小忍陪你等一下。

这不是装饰功能，而是冷静箱机制的系统级延伸：用户把一次冲动放进冷静箱后，离开 App 也能看见“我正在等一等”，到时间后再回来做决定。

## 2. 触发场景

启动 Live Activity：

- 用户在记录页点击“先放进冷静箱”。
- 记录保存为 `ResistStatus.pending`。
- 存在有效 `cooldownUntil`。
- 系统允许 Live Activities。

结束 Live Activity：

- 用户在我的页冷静箱里选择“我忍住了”。
- 用户在我的页冷静箱里选择“我还是做了”。
- 冷静时间结束后，用户返回 App 处理记录。
- 超过系统允许时间后由系统结束。

暂不启动：

- 用户选择“我忍住了”。
- 用户选择“我还是做了”。
- 普通历史记录。
- 首页资产卡点击反馈。

## 3. 信息优先级

灵动岛空间极小，只保留三类信息：

1. 小忍状态。
2. 剩余时间。
3. 道具/冲动名称。

不放：

- 长文案。
- 大段解释。
- 复杂统计。
- 目标进度。
- 多个按钮堆叠。

## 4. 视觉状态

### 冷静中

使用黄色或米白小忍，表情是“努力稳住”。

文案：

- `冷静中`
- `还剩 8 分钟`

适用：

- 刚放入冷静箱。
- 剩余时间较长。

### 快到了

使用黄色小忍，表情更专注。

文案：

- `快好了`
- `还剩 1 分钟`

适用：

- 剩余时间小于 2 分钟。

### 可决定

使用米白或绿色小忍，表情放松。

文案：

- `可以决定了`
- `现在还想要吗？`

适用：

- 冷静时间结束后。

### 已处理

不长时间停留，处理后结束 Live Activity。

如果需要短暂反馈：

- 忍住了：绿色小忍，`拿回来了`
- 没忍住：米白小忍，`看见了`

## 5. 灵动岛展示设计

### Minimal

出现条件：

- 多个 Live Activity 同时存在，系统只给最小空间。

内容：

- 一个小忍圆形头像。

设计：

```text
[小忍]
```

要求：

- 不能使用复杂表情。
- 小忍轮廓要极简。
- 使用高对比色，避免在黑色背景里糊掉。

### Compact Leading

内容：

- 小忍小头像。

设计：

```text
[小忍]
```

### Compact Trailing

内容：

- 倒计时。

设计：

```text
8m
```

规则：

- 大于 60 分钟：`2h`
- 小于 60 分钟：`8m`
- 小于 1 分钟：`now`

### Expanded

长按灵动岛后的展开形态。

结构：

```text
┌────────────────────────────┐
│ 小忍        奶茶 · 冷静中   │
│             还剩 8 分钟     │
│                            │
│ [我忍住了]      [我还是做了] │
└────────────────────────────┘
```

区域建议：

- `leading`：小忍头像。
- `center`：标题，例如 `奶茶`。
- `trailing`：剩余时间。
- `bottom`：两个轻量操作按钮。

按钮说明：

- `我忍住了`：打开 App 并处理对应记录。
- `我还是做了`：打开 App 并处理对应记录。

如果交互按钮实现复杂，v1 可先让点击/长按只打开 App 对应冷静箱详情。

## 6. 数据结构设计

新增 Widget Extension 后定义 ActivityKit attributes。

建议命名：

```swift
struct CooldownActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var typeRaw: String
        var status: CooldownLiveStatus
        var endsAt: Date
        var propIconKeyRaw: String?
    }

    var recordId: String
}
```

状态：

```swift
enum CooldownLiveStatus: String, Codable, Hashable {
    case cooling
    case almostReady
    case ready
}
```

字段说明：

- `recordId`：用于返回 App 后定位冷静箱记录。
- `title`：记录标题，如奶茶、相机、短视频。
- `typeRaw`：money / food / time，用于配色。
- `endsAt`：倒计时结束时间。
- `propIconKeyRaw`：后续可扩展为具体道具图标。

## 7. App 端实现路径

建议新增文件：

```text
RenLeMe/CooldownLiveActivityManager.swift
```

职责：

- 检查系统是否允许 Live Activities。
- 创建冷静箱 Live Activity。
- 更新 Live Activity 状态。
- 结束 Live Activity。
- 保存 `recordId -> activityId` 的映射。

保存映射：

- v1 可用 `UserDefaults`。
- 后续如需要更强一致性，可给 `ResistRecord` 增加 `liveActivityId` 字段，但这涉及 SwiftData migration，暂不建议第一版就加。

记录页接入：

- `RecordFlowView.save(status:)`
- 当 `status == .pending` 且 `cooldownUntil != nil` 时：
  - 保存 `ResistRecord`。
  - 调用 `CooldownLiveActivityManager.start(record:)`。
  - 同时保留现有本地通知。

我的页接入：

- `PendingRecordRow` 处理为“我忍住了”或“我还是做了”时：
  - 更新记录状态。
  - 清空 `cooldownUntil`。
  - 调用 `CooldownLiveActivityManager.end(recordId:)`。

## 8. Widget Extension

需要新增：

```text
RenLeMeLiveActivityExtension/
```

包含：

- Widget Extension target。
- ActivityKit / WidgetKit。
- `CooldownLiveActivityWidget.swift`。
- 共享小忍极简绘制组件。

工程配置：

- 主 App 开启 Live Activities。
- Info.plist 增加 `NSSupportsLiveActivities = YES`。
- 如果需要更频繁更新，再评估 `NSSupportsLiveActivitiesFrequentUpdates`，第一版不建议开启。

## 9. 小忍绘制规则

灵动岛版本小忍必须比 App 内更克制。

要求：

- 头像尺寸小。
- 轮廓清晰。
- 眼睛嘴巴最多 3-4 个元素。
- 不使用大面积阴影。
- 不使用复杂道具叠加。
- 优先使用 Shape/SF Symbol，不依赖大图。

建议颜色：

- 冷静中：黄色小忍。
- 可决定：米白小忍。
- 忍住成功短反馈：绿色小忍。
- 没忍住短反馈：米白或粉色小忍，但不要焦虑。

## 10. 与本地通知的关系

Live Activity 不替代本地通知。

两者分工：

- Live Activity：持续显示冷静中状态。
- 本地通知：到时间主动提醒用户。

原因：

- 不是所有设备都有灵动岛。
- 用户可能关闭 Live Activities。
- 用户可能没有一直看锁屏。
- 本地通知是更稳定的提醒兜底。

## 11. MVP 实现顺序

建议分两步做，避免影响当前上线路线。

### v1.0 不阻塞上线

- 保持当前冷静箱本地通知。
- 不把 Live Activity 作为上架必备。
- 继续完成真机回归和 App Store 材料。

### v1.1 灵动岛增强

1. 新增 Widget Extension。
2. 定义 `CooldownActivityAttributes`。
3. 做 minimal / compact / expanded UI。
4. 在 `RecordFlowView` pending 保存时启动 Live Activity。
5. 在 `ProfileView` 冷静箱处理时结束 Live Activity。
6. 真机验证 Dynamic Island 和锁屏展示。

## 12. 验收标准

功能验收：

- 放入冷静箱后，支持灵动岛的 iPhone 显示小忍 Live Activity。
- 不支持灵动岛的设备在锁屏显示 Live Activity。
- 倒计时显示正确。
- 到期后本地通知仍能触发。
- 处理冷静箱后 Live Activity 结束。
- App 重启后不会重复启动同一条 Live Activity。

视觉验收：

- Minimal 形态小忍不糊、不挤。
- Compact 倒计时可读。
- Expanded 不超过系统区域，不出现文字截断。
- 小忍表情符合冷静箱语义，不焦虑、不惩罚。

边界验收：

- 用户关闭 Live Activities 时，记录保存和本地通知不受影响。
- 用户关闭通知时，Live Activity 不受影响。
- 多条冷静箱记录同时存在时，只启动最新或最相关的一条 Live Activity。

## 13. 风险与注意事项

- ActivityKit 需要真机验证，模拟器不能完全代表灵动岛体验。
- Live Activity 动画受系统限制，不能做 App 内那种连续动态小忍。
- 内容体积有限，不能塞复杂图像。
- 多个 Live Activity 竞争灵动岛时，系统决定显示优先级。
- 如果要从灵动岛按钮直接处理记录，需要处理 App Intent / deep link，复杂度会增加。

## 14. 推荐结论

小忍可以出现在灵动岛，但最佳形态是：

> 冷静箱倒计时 Live Activity。

它既符合「忍了么」的产品核心，也不会把小忍变成无意义装饰。建议作为 v1.1 增强，不阻塞当前 v1.0 上线。
