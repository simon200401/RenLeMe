# 忍了么 1.0 上架执行指南

更新时间：2026-09-22

## 当前已准备

- Bundle ID：`com.simonx.renleme`
- 版本：`1.0`
- 构建号：`1`
- 平台：iPhone，最低 iOS 17
- 类别：Lifestyle / 生活
- 隐私清单：`RenLeMe/PrivacyInfo.xcprivacy`
- 商店文案：`APP_STORE_LISTING_DRAFT.md`
- 隐私页：`release-site/privacy.html`
- 支持页：`release-site/support.html`
- 灵动岛扩展 Target 已从工程移除
- Apple Development 签名 Archive 已验证通过

## 1. 接受 Apple 协议

1. 打开 [Apple Developer Account](https://developer.apple.com/account/)，使用开发者账号登录。
2. 如果首页出现 Program License Agreement 横幅，点击 `Review Agreement`，阅读后接受。
3. 打开 [App Store Connect](https://appstoreconnect.apple.com/)。
4. 进入 `Business（商务）`，检查 Agreements 是否存在 `Pending User Info` 或待接受协议。
5. 回到 Xcode，打开 `Xcode → Settings → Accounts`，选择 Apple ID，点击 `Download Manual Profiles` 或刷新账号。

只有 Account Holder 能接受部分协议。若按钮不可用，需要让团队的 Account Holder 操作。

## 2. 检查签名

1. 用 Xcode 打开 `RenLeMe.xcodeproj`。
2. 左侧选中蓝色 `RenLeMe` 工程，再选择 TARGETS 下的 `RenLeMe`。
3. 打开 `Signing & Capabilities`。
4. 勾选 `Automatically manage signing`。
5. Team 选择你的有效开发者团队；Bundle Identifier 保持 `com.simonx.renleme`。
6. 顶部运行目标选择 `Any iOS Device (arm64)`，确认 Signing 区域不再显示红色错误。当前工程已成功生成 Apple Development 签名 Archive。

当前钥匙串已有 Apple Development 证书，但尚未发现 Apple Distribution 证书。上传时如果 Xcode 不能自动创建：进入 `Xcode → Settings → Accounts → Manage Certificates`，点击 `+` 创建 `Apple Distribution`，再回到 Organizer 重试。

## 3. 真机回归

1. 将 iPhone 连接到 Mac，并在手机上开启开发者模式：`设置 → 隐私与安全性 → 开发者模式`。
2. Xcode 顶部选择该 iPhone，按 `⌘R` 安装。
3. 删除旧版 App 后重新安装，按 `QA_CHECKLIST.md` 从头检查。
4. 必测：首次引导、拍照、相册、通知、键盘收起、冷静箱到期、记录增删改、目标增删改、小屏文字布局。

## 4. 创建 App Store Connect 记录

1. 打开 `App Store Connect → My Apps（我的 App）`。
2. 点击左上角 `+ → New App`。
3. Platform 选 iOS，名称填“忍了么”，Primary Language 选简体中文。
4. Bundle ID 选择 `com.simonx.renleme`，SKU 可填 `renleme-ios-1`。
5. 在 App Information 中选择主类别 Lifestyle，并完成 Age Rating：当前内容项均为“无”。

## 5. Archive 与 TestFlight

1. Xcode 顶部运行目标选择 `Any iOS Device (arm64)`。
2. 选择 `Product → Archive`。
3. Organizer 出现后选择最新 Archive，点击 `Distribute App → App Store Connect → Upload`。
4. 上传完成后打开 `App Store Connect → 忍了么 → TestFlight`，等待 Apple 处理构建。
5. 添加内部测试员并安装 TestFlight 版本，删除旧版后做一次干净首启检查。

每次重新上传必须增加 Build：TARGETS `RenLeMe → General → Build`，从 1 改为 2、3……

## 6. App Privacy 与审核信息

1. 进入 `App Store Connect → 忍了么 → App Privacy → Get Started`。
2. 选择“否，我们不会从此 App 收集数据”。当前版本没有账号、分析 SDK、广告 SDK或服务器上传。
3. 在版本页面填写：
   - Support URL：`https://renleme.netlify.app/support.html`
   - Privacy Policy URL：`https://renleme.netlify.app/privacy.html`
4. Review Information 不需要测试账号。
5. Notes 使用 `APP_STORE_LISTING_DRAFT.md` 中的 App Review 备注。
6. Export Compliance：工程已声明不使用非豁免加密；如果后台仍询问，选择 App 不使用非豁免加密。

## 7. 截图与提交

1. 在版本页面的 App Previews and Screenshots 区域查看当前要求的 iPhone 尺寸。
2. 使用相同尺寸的最新 Simulator 截图，至少覆盖首页、记录、冷静箱、目标、我的。
3. 填写描述、副标题、关键词和新版本说明。
4. 选择已处理完成的构建，填写版权信息与联系信息。
5. 完成所有红色必填项后，点击 `Add for Review`，再点击 `Submit for Review`。
