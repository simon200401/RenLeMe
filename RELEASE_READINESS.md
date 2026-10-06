# 忍了么 v1.0 上线准备清单

更新时间：2026-10-06（构建与审核状态）；2026-10-07 补充说明

> 2026-10-06 之后 App 做了一轮改版（三个标签、暂停流程、新的“我的”页，见 [`HANDOFF.md`](HANDOFF.md)）。下面的构建、归档和审核状态都早于这轮改版。重新发布前需要：用新代码打包并递增构建号；按 [`QA_CHECKLIST.md`](QA_CHECKLIST.md) 做真机回归；重截 App Store 截图并核对商店文案；确认隐私问卷仍然准确（新增了本地的每周小结通知、动作传感器、CSV 导出和邮件反馈，均不上传数据）。App 现在只支持 iPhone 竖屏。

当前结论：产品主流程已实现，隐私政策与支持页面已部署。此前已提交旧构建并收到 2.1 补充资料要求；当前工作区又包含键盘、冷静箱、小忍动作和目标关联修复，需要重新打包并验证。最新上传、处理及审核结果以 App Store Connect 为准。

当前工程版本：`1.0 (3)`。如构建号 3 已上传，应继续递增；发布必须包含当前工作区改动，不能只按旧 Git 提交打包。

历史 Release Archive：2026-09-22 21:58（香港时间），源码提交 `365951b`，版本 `1.0 (1)`。不包含后续修复，不用于本次发布。

本机归档路径：`/Users/simonx/Library/Developer/Xcode/Archives/2026-09-22/RenLeMe-1.0-1-365951b.xcarchive`。

## v1.0 产品边界

- 本地使用，不提供账号、云同步或服务器上传。
- 不做联网食物搜索、广告、付费订阅、社交排名或 AI 聊天。
- 食物数据来自内置本地库和模板默认热量，用户可以手动修改。
- Live Activity / 灵动岛不进入 v1.0；扩展及共享源码、工程引用、旧设计方案均已移除。

## 已自动完成并验证

- [x] Xcode 26.6 与 iOS 26.4/26.5 Simulator Runtime 可用。
- [x] 工程只保留 `RenLeMe` 主 App target 和 scheme。
- [x] `swiftc -parse RenLeMe/*.swift` 通过。
- [x] Release Simulator 构建通过。
- [x] Generic iOS Device 无签名 Archive 通过。
- [x] Apple Development 自动签名 Archive 通过，Bundle ID 与 Team 正确。
- [x] Release 干净安装可启动，首次欢迎引导正常出现。
- [x] Release 干净安装不插入 Demo 记录，资产初始值为 0。
- [x] 已移除 Debug/Release 共用启动路径中的演示记录与默认目标注入逻辑；本地食物库保留，已有真实记录不自动清除。
- [x] 旧测试版覆盖安装时会清理三张系统预设目标卡，用户自建目标和记录保留。
- [x] App 图标、启动页和首次引导已配置。
- [x] Release 仅支持 iPhone，避免 v1.0 额外承担 iPad 截图与布局审核。
- [x] 相机、相册、通知权限说明已配置。
- [x] 隐私清单 `PrivacyInfo.xcprivacy` 已加入 App。
- [x] 已声明不使用非豁免加密，减少出口合规补充步骤。
- [x] App 内新增“数据与隐私”说明入口。
- [x] 隐私政策页与支持页已部署到 Netlify 正式站点。
- [x] App Store 文案、隐私问卷答案、审核备注草稿已整理。

## 需要用户确认：Apple 分发账号

- [x] Xcode 已登录有效开发者账号，主 App 自动签名正常。
- [x] `com.simonx.renleme` 已使用 Team `37D28864BV` 完成签名 Archive。
- [ ] 在 Apple Developer 与 App Store Connect 确认没有待接受协议或商务信息。
- [ ] 在 Organizer 上传时确认 Xcode 能创建或使用 Apple Distribution 证书。
- [ ] 使用真机完成一次签名安装。

2026-09-22 已确认钥匙串中 Apple Development 与 Apple Distribution 身份均有效。最新 Archive 使用 Apple Development 签名，上传时仍需完成分发签名和描述文件验证。详细路径见 `APP_STORE_SUBMISSION_GUIDE.md` 的第 1-3 节。

## 需要用户完成：真机回归

- [ ] 按 `QA_CHECKLIST.md` 完整走查。
- [ ] 重点验证相机、相册、通知、键盘收起与冷静箱到期提醒。
- [ ] 至少覆盖一台小屏 iPhone 和一台主流尺寸 iPhone；没有第二台设备时可用 Simulator 补布局检查。

## 需要用户完成：发布链路

- [x] Netlify 正式站点已部署并验证：`https://renleme.netlify.app`。
- [x] 已创建 App Store Connect 记录并提交过旧构建。
- [ ] 上传包含当前修复的新 Archive 到 App Store Connect。
- [ ] 添加 TestFlight 内部测试版本，并完成一次干净安装回归。
- [ ] 确认 TestFlight Release 不插入 Demo 数据。
- [ ] 使用最终构建截取 App Store 截图。
- [ ] 完成隐私问卷、年龄分级、审核备注和商店文案。
- [ ] 提供最新真机录屏并回复 2.1 补充要求，更新审核 Notes。
- [ ] 选择最终构建，重新提交审核。

## 发布材料位置

- App Store 文案与问卷答案：`APP_STORE_LISTING_DRAFT.md`
- 提交操作步骤：`APP_STORE_SUBMISSION_GUIDE.md`
- 2.1 审核回复与录屏脚本：`APP_REVIEW_RESPONSE_2_1.md`
- 真机回归清单：`QA_CHECKLIST.md`
- 隐私政策正文：`PRIVACY_POLICY_DRAFT.md`
- 已部署静态站点源码：`release-site/`
- Netlify 配置：`netlify.toml`
- 支持 URL：`https://renleme.netlify.app/support.html`
- 隐私政策 URL：`https://renleme.netlify.app/privacy.html`

## 发布后再考虑

- 用户自建食物库。
- 本地数据导出或 iCloud 同步。
- 更完整的周/月趋势与复盘。
- 冷静箱提醒设置。
- AI 复盘摘要。
- Live Activity / 灵动岛。
