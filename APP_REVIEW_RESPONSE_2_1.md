# Guideline 2.1 审核补充材料

这次通知要求补充信息，并未指出某个具体崩溃或功能缺陷。以下内容基于当前仓库；发送前请确认待审核构建与其一致。

## 你需要先完成

1. 在真实 iPhone 上更新至最新正式版 iOS，通过 TestFlight 安装本次提交审核的同一构建。记录型号、iOS 版本、App 版本和构建号。
2. 按 QA_CHECKLIST.md 做真机测试，尤其是保存、重启后数据保留、相机、相册、拒绝权限后的手动录入、冷静箱、目标进度和删除。发现问题先修复，不要把未测试写成通过。
3. 用控制中心的屏幕录制，从手机主屏幕点击 App 图标开始录制。不要使用模拟器、设计稿或专门的截图演示构建。
4. 推荐录制约 3–5 分钟；这是建议，不是 Apple 规定时长。使用自己手动创建的测试内容，避免拍入个人敏感信息。
5. 将视频作为审核消息附件上传；若上传受限，提供无需登录、无需申请权限即可观看的稳定链接。用未登录浏览器检查链接。
6. 将下面英文中所有方括号替换为真实信息。完成测试后才填写测试结果，不要原样提交占位符。

## 推荐录屏顺序

1. 从主屏幕启动 App，展示新手指引（若已完成，可通过应用内入口再次查看）及首页。
2. 创建一个金钱目标，例如 300 元；回到记录页创建一条 30 元记录并关联目标，选择“我忍住了”，展示反馈、资产与目标进度。
3. 新建食物记录，展示本地食物选择或手动热量输入，选择“我还是做了”，展示保存后的“没忍住”状态。
4. 新建时间记录并暂缓决定，展示冷静箱中的记录，再完成处理。不需要为了录视频等待整个倒计时。
5. 展示目标编辑、相册选图（或拍照）及时间单位选择；展示历史记录与复盘。
6. 编辑或删除一条测试记录；退出并重新打开 App，展示其余数据仍被保存。

## 提交位置

- App Store Connect → App → 忍了么 → App 审核 → 当前审核消息 → 回复。粘贴英文并附视频。
- 当前 iOS 版本页面 → App 审核信息 → 备注（Notes）。同步填写相同六项信息及可访问的视频链接，然后保存。
- 不必仅因为这封补充信息通知就重新上传构建；若测试发现缺陷、待审核构建与说明不一致，则修复后上传新构建，并更新视频与说明。

## 英文答复（补齐占位符后用于回复及 Notes）

Hello App Review Team,

Thank you for your message. Below is the requested information for RenLeMe (忍了么).

1. Physical-device demonstration and testing

Video: [ATTACHMENT FILENAME OR ACCESSIBLE VIDEO URL]
Device: [IPHONE MODEL]
Operating system: [IOS VERSION — LATEST PUBLIC RELEASE]
App version/build: [VERSION AND BUILD NUMBER]
Physical-device QA performed and results: [ACTUAL TESTS AND RESULTS]

The recording begins with launching the app and demonstrates recording a decision, viewing accumulated totals, using the cooling box, managing goals, and reviewing records. The app has no account registration, login, paid content, or in-app purchases. User-entered notes and photos are private local content; the app does not provide public posting, a community feed, or communication between users.

2. Purpose and target audience

RenLeMe is a lightweight personal self-management app for people who want to pause before impulsive purchases, discretionary eating, or spending time on distractions. Users record a choice, decide immediately or revisit it later in a cooling box, and track progress toward personal goals. A mascot provides supportive feedback without punishing unsuccessful attempts. Amounts, calories, and time are user-entered values or estimates, not automatically measured savings or health outcomes.

3. Setup and access to main features

No account, credentials, payment, external device, or sample file is required. Launch the app and complete the introductory guide. In Record (记录), choose money, food, or time, enter the item and optional details, then choose to resist, proceed, or defer the decision. Home (首页) displays totals and recent records. Open the cooling box to revisit deferred decisions. Goals (目标) allows users to create and edit targets and link records to them. Profile (我的) provides review and data-management features. Camera/photos are optional for custom item and goal images; notifications are optional for cooling reminders. Manual recording remains available without these permissions. A fresh installation starts without personal records or goals.

4. External services, tools, and platforms

Core functionality runs locally using Apple's native frameworks, including SwiftData for on-device persistence, system photo/camera interfaces, and local notifications. There is no remote application backend, authentication provider, payment processor, advertising SDK, or runtime AI service. The app includes a small offline food reference library attributed to USDA FoodData Central; it does not query the USDA API at runtime. Netlify hosts the public support and privacy-policy website, not users' app records or photos.

Support: https://renleme.netlify.app/support.html
Privacy policy: https://renleme.netlify.app/privacy.html

5. Regional availability and behavior

The app provides the same features and content across all enabled storefronts, without region-specific feature restrictions. Its current interface is primarily Simplified Chinese. Money entries use yuan (¥), with no automatic currency conversion; calorie and time units are consistent across regions.

6. Regulated services and third-party materials

The app is a personal logging and reflection tool. It does not provide banking, payments, investment services, medical diagnosis, treatment, or individualized medical advice. Food calorie values are reference estimates, not clinical recommendations. The bundled food reference data is attributed to USDA FoodData Central, whose data is public domain under CC0: https://fdc.nal.usda.gov/api-guide/#bkmk-4 . User-selected images remain private on the device and are not distributed to other users. The app does not offer a third-party media catalog or licensed entertainment service.

Thank you for reviewing our submission.

## 发送前核对

- 本文不是已完成真机测试的证明；请补充实际测试结果与视频。
- 当前代码对食物数据有 USDA 来源标注，但没有逐条 FDC ID。若被要求提供精确数据溯源，应补充原始条目，不能将代码中的来源标注当作已经完成独立核验。
- 确认实际提交版本没有账号、收费、远端同步或新 SDK；如有变化，必须同步修改答复。
- 如包含额外第三方受保护素材，需披露并准备授权，不能仅凭本文推定版权合规。
- 开发时使用 AI 工具不等于 App 内调用 AI 服务；审核第 4 项主要描述 App 实际运行依赖。

## 官方参考

- Apple 审核消息回复：https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/reply-to-app-review-messages
- USDA 数据许可：https://fdc.nal.usda.gov/api-guide/ （Licensing 部分）
