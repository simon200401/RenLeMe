# 忍了么 v1.0 上线准备清单

更新时间：2026-09-22

当前结论：产品功能与无签名 Release 包已通过工程验证。正式上线仍需完成 Apple 账号协议、签名归档、真机回归、TestFlight 和 App Store Connect 提交。

## v1.0 产品边界

- 本地使用，不提供账号、云同步或服务器上传。
- 不做联网食物搜索、广告、付费订阅、社交排名或 AI 聊天。
- 食物数据来自内置本地库和模板默认热量，用户可以手动修改。
- Live Activity / 灵动岛不进入 v1.0；扩展源码保留，但已从主工程构建与签名链路移除。

## 已自动完成并验证

- [x] Xcode 26.6 与 iOS 26.4/26.5 Simulator Runtime 可用。
- [x] 工程只保留 `RenLeMe` 主 App target 和 scheme。
- [x] `swiftc -parse RenLeMe/*.swift` 通过。
- [x] Release Simulator 构建通过。
- [x] Generic iOS Device 无签名 Archive 通过。
- [x] Release 干净安装可启动，首次欢迎引导正常出现。
- [x] Release 干净安装不插入 Demo 记录，资产初始值为 0。
- [x] App 图标、启动页和首次引导已配置。
- [x] Release 仅支持 iPhone，避免 v1.0 额外承担 iPad 截图与布局审核。
- [x] 相机、相册、通知权限说明已配置。
- [x] 隐私清单 `PrivacyInfo.xcprivacy` 已加入 App。
- [x] 已声明不使用非豁免加密，减少出口合规补充步骤。
- [x] App 内新增“数据与隐私”说明入口。
- [x] 隐私政策页、支持页及部署配置已准备在 `release-site/`。
- [x] App Store 文案、隐私问卷答案、审核备注草稿已整理。

## 需要用户完成：Apple 账号与签名

- [ ] 接受 Apple Developer 最新协议，并确认会员有效。
- [ ] 在 Xcode 登录有效开发者账号。
- [ ] 为 `com.simonx.renleme` 选择 Team，并打开自动签名。
- [ ] 使用真机完成一次签名安装。
- [ ] 使用 `Any iOS Device (arm64)` 完成正式 Archive。

详细路径见 `APP_STORE_SUBMISSION_GUIDE.md` 的第 1-3 节。

## 需要用户完成：真机回归

- [ ] 按 `QA_CHECKLIST.md` 完整走查。
- [ ] 重点验证相机、相册、通知、键盘收起与冷静箱到期提醒。
- [ ] 至少覆盖一台小屏 iPhone 和一台主流尺寸 iPhone；没有第二台设备时可用 Simulator 补布局检查。

## 需要用户完成：发布链路

- [ ] 登录 Netlify 后部署隐私政策 URL 与支持 URL。
- [ ] 在 App Store Connect 创建 App 记录。
- [ ] 上传 Archive 到 App Store Connect。
- [ ] 添加 TestFlight 内部测试版本，并完成一次干净安装回归。
- [ ] 确认 TestFlight Release 不插入 Demo 数据。
- [ ] 使用最终构建截取 App Store 截图。
- [ ] 完成隐私问卷、年龄分级、审核备注和商店文案。
- [ ] 提交审核。

## 发布材料位置

- App Store 文案与问卷答案：`APP_STORE_LISTING_DRAFT.md`
- 提交操作步骤：`APP_STORE_SUBMISSION_GUIDE.md`
- 真机回归清单：`QA_CHECKLIST.md`
- 隐私政策正文：`PRIVACY_POLICY_DRAFT.md`
- 待部署静态站点：`release-site/`
- Netlify 配置：`netlify.toml`

## 发布后再考虑

- 用户自建食物库。
- 本地数据导出或 iCloud 同步。
- 更完整的周/月趋势与复盘。
- 冷静箱提醒设置。
- AI 复盘摘要。
- Live Activity / 灵动岛。
