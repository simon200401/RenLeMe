import SwiftData
import SwiftUI
import UIKit
import UserNotifications

extension Notification.Name {
    static let openCooldownRecord = Notification.Name("renleme.openCooldownRecord")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        QuickEntry.installShortcutItems()
        CooldownLiveActivity.install()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // SwiftUI still owns the window; this only adds somewhere for the icon menu to report to.
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let recordId = userInfo["recordId"] as? String {
            UserDefaults.standard.set(recordId, forKey: "renleme.pendingCooldownRoute")
            NotificationCenter.default.post(name: .openCooldownRecord, object: recordId)
        } else if userInfo["route"] as? String == "results" {
            UserDefaults.standard.set(true, forKey: "renleme.pendingWeeklySummaryRoute")
            NotificationCenter.default.post(name: .openWeeklySummary, object: nil)
        }
        completionHandler()
    }
}

@main
struct RenLeMeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        let titleColor = UIColor(red: 0.025, green: 0.025, blue: 0.035, alpha: 1)
        let backgroundColor = UIColor(red: 0.965, green: 0.953, blue: 0.909, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 18, weight: .black)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 36, weight: .black)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        // At the top of a page the bar is see-through (the page is the same colour anyway), so things
        // just under it, like 小忍's speech bubble, are not cut off by the bar's edge.
        let edgeAppearance = UINavigationBarAppearance()
        edgeAppearance.configureWithTransparentBackground()
        edgeAppearance.titleTextAttributes = appearance.titleTextAttributes
        edgeAppearance.largeTitleTextAttributes = appearance.largeTitleTextAttributes
        UINavigationBar.appearance().scrollEdgeAppearance = edgeAppearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = titleColor

        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 15, weight: .black)
        ], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 15, weight: .black)
        ], for: .selected)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 1.0, green: 0.988, blue: 0.925, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(AppStore.container)
    }
}

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @AppStorage("didSeedDefaultGoals") private var didSeedDefaultGoals = false
    @AppStorage(FoodSeedData.versionKey) private var foodSeedVersion = 0
    @AppStorage("didRemoveLegacyDefaultGoalsV1") private var didRemoveLegacyDefaultGoalsV1 = false
    @AppStorage("didCompleteWelcomeOnboarding") private var didCompleteWelcomeOnboarding = false
    @State private var selectedTab: AppTab = .home
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(WeeklySummaryScheduler.enabledKey) private var weeklySummaryEnabled = false
    @AppStorage(AppSettings.liveActivityKey) private var liveActivityEnabled = true
    @ObservedObject private var cloudBackup = CloudBackup.shared
    @State private var pauseType: ResistType?
    @State private var isPresentingRecord = false
    @State private var isShowingWelcomeOnboarding = false
    @State private var isShowingLaunchSplash = true
    @State private var routedCooldownRecord: ResistRecord?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    onPause: { pauseType = $0 },
                    onDirectRecord: { isPresentingRecord = true },
                    onShowResults: { selectedTab = .results }
                )
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.symbolName)
            }
            .tag(AppTab.home)

            NavigationStack {
                ResultsView()
            }
            .tabItem {
                Label(AppTab.results.title, systemImage: AppTab.results.symbolName)
            }
            .tag(AppTab.results)

            NavigationStack {
                ProfileView {
                    showWelcomeOnboarding()
                }
            }
            .tabItem {
                Label(AppTab.profile.title, systemImage: AppTab.profile.symbolName)
            }
            .tag(AppTab.profile)
        }
        .tint(.punchBlack)
        .environment(\.mascotMotionEnabled,
                     !isShowingLaunchSplash && !isShowingWelcomeOnboarding && pauseType == nil && !isPresentingRecord && routedCooldownRecord == nil)
        .blur(radius: isShowingWelcomeOnboarding ? 2.4 : 0)
        .saturation(isShowingWelcomeOnboarding ? 0.58 : 1)
        .brightness(isShowingWelcomeOnboarding ? -0.05 : 0)
        .scaleEffect(isShowingWelcomeOnboarding ? 0.985 : 1)
        .animation(.easeOut(duration: 0.22), value: isShowingWelcomeOnboarding)
        .sheet(item: $pauseType) { type in
            NavigationStack {
                PauseFlowView(type: type)
                    .environment(\.mascotMotionEnabled, true)
            }
            .presentationDetents([.large])
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $isPresentingRecord) {
            NavigationStack {
                RecordFlowView(isModal: true)
                    .environment(\.mascotMotionEnabled, true)
            }
            .presentationDetents([.large])
        }
        .sheet(item: $routedCooldownRecord) { record in
            NavigationStack {
                RecordDetailView(record: record)
                    .environment(\.mascotMotionEnabled, true)
            }
        }
        .overlay {
            if isShowingLaunchSplash {
                LaunchSplashView {
                    finishLaunchSplash()
                }
                .zIndex(20)
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }

            if isShowingWelcomeOnboarding {
                WelcomeOnboardingView {
                    finishWelcomeOnboarding()
                }
                .zIndex(10)
            }
        }
        .task {
            AppStore.adoptStrayStoreIfNeeded()
            removeLegacyDefaultGoalsIfNeeded()
            seedFoodNutritionItemsIfNeeded()
            routePendingCooldownIfNeeded()
            routePendingWeeklySummaryIfNeeded()
            routePendingPauseIfNeeded()
            rescheduleWeeklySummary()
            MascotAttention.shared.install()
            await cloudBackup.refresh()
        }
        // A backup from a previous install or another phone: ask before doing anything with it.
        .alert(
            "在 iCloud 里找到一份备份",
            isPresented: Binding(
                get: { cloudBackup.foreign != nil && !isShowingLaunchSplash && !isShowingWelcomeOnboarding },
                set: { _ in }
            ),
            presenting: cloudBackup.foreign
        ) { archive in
            Button("恢复") {
                Task { await cloudBackup.restore(archive) }
            }
            Button("不用", role: .cancel) {
                cloudBackup.decline(archive)
            }
        } message: { archive in
            Text("\(CloudBackup.dateText(archive.createdAt))，来自“\(archive.deviceName)”，\(archive.records.count) 条记录、\(archive.goals.count) 个目标。恢复只会补上这台手机没有的，不会改动已有的。选“不用”的话，之后这台手机的数据会替换掉这份备份。")
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPause)) { _ in
            routePendingPauseIfNeeded()
        }
        .onOpenURL { url in
            QuickEntry.handle(url: url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHome)) { _ in
            dismissPresentedFlows()
            selectedTab = .home
        }
        .onChange(of: widgetSnapshot, initial: true) { _, snapshot in
            WidgetBridge.publish(snapshot)
        }
        .task(id: liveActivityTrigger) {
            guard scenePhase == .active else { return }
            await CooldownLiveActivity.reconcile(with: records)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCooldownRecord)) { notification in
            guard let rawId = notification.object as? String, let id = UUID(uuidString: rawId) else { return }
            routeToCooldownRecord(id: id)
        }
        .onChange(of: records.count) { _, _ in
            routePendingCooldownIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openWeeklySummary)) { _ in
            routePendingWeeklySummaryIfNeeded()
        }
        .onChange(of: weeklySummary) { _, _ in
            rescheduleWeeklySummary()
        }
        .onChange(of: weeklySummaryEnabled) { _, _ in
            rescheduleWeeklySummary()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                rescheduleWeeklySummary()
                Task { await cloudBackup.refresh() }
            } else if phase == .background {
                Task { await cloudBackup.backUp() }
            }
        }
        .onChange(of: selectedTab) { _, _ in
            UIApplication.shared.dismissKeyboard()
        }
    }

    /// Changes whenever the cooldown box, the switch, or being in front does.
    private var liveActivityTrigger: String {
        let waiting = records
            .filter { $0.status == .pending }
            .map { "\($0.id.uuidString)@\($0.cooldownUntil?.timeIntervalSinceReferenceDate ?? 0)" }
            .sorted()
            .joined(separator: ",")
        return "\(liveActivityEnabled)|\(scenePhase == .active)|\(waiting)"
    }

    private var widgetSnapshot: WidgetSnapshot {
        // Read here so a new day is noticed when the app comes back to the front.
        _ = scenePhase
        return WidgetBridge.snapshot(from: records)
    }

    private var weeklySummary: WeeklySummaryContent {
        WeeklySummaryContent(records: records, goals: goals)
    }

    private func rescheduleWeeklySummary() {
        WeeklySummaryScheduler.reschedule(with: weeklySummary)
    }

    private func routePendingWeeklySummaryIfNeeded() {
        let key = "renleme.pendingWeeklySummaryRoute"
        guard UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.removeObject(forKey: key)
        dismissPresentedFlows()
        selectedTab = .results
    }

    /// Straight into the pause for the kind chosen outside the app. Someone who has not been through
    /// the welcome yet sees that first; the choice is dropped rather than sprung on them afterwards.
    private func routePendingPauseIfNeeded() {
        guard let type = QuickEntry.takePending(), didCompleteWelcomeOnboarding else { return }
        guard pauseType != type else { return }
        isShowingLaunchSplash = false
        isPresentingRecord = false
        routedCooldownRecord = nil
        selectedTab = .home
        pauseType = type
    }

    private func dismissPresentedFlows() {
        pauseType = nil
        isPresentingRecord = false
        routedCooldownRecord = nil
    }

    private func finishLaunchSplash() {
        withAnimation(.easeOut(duration: 0.22)) {
            isShowingLaunchSplash = false
        }

        showWelcomeOnboardingIfNeeded()
    }

    private func showWelcomeOnboardingIfNeeded() {
        guard !didCompleteWelcomeOnboarding else { return }

        showWelcomeOnboarding()
    }

    private func showWelcomeOnboarding() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                isShowingWelcomeOnboarding = true
            }
        }
    }

    private func finishWelcomeOnboarding() {
        didCompleteWelcomeOnboarding = true
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            isShowingWelcomeOnboarding = false
        }
    }

    private func routePendingCooldownIfNeeded() {
        guard let rawId = UserDefaults.standard.string(forKey: "renleme.pendingCooldownRoute"),
              let id = UUID(uuidString: rawId)
        else { return }

        routeToCooldownRecord(id: id)
    }

    private func routeToCooldownRecord(id: UUID) {
        guard let record = records.first(where: { $0.id == id }) else { return }
        guard record.status == .pending else {
            UserDefaults.standard.removeObject(forKey: "renleme.pendingCooldownRoute")
            return
        }

        UserDefaults.standard.removeObject(forKey: "renleme.pendingCooldownRoute")
        isShowingLaunchSplash = false
        isShowingWelcomeOnboarding = false
        pauseType = nil
        isPresentingRecord = false
        routedCooldownRecord = record
    }

    private func removeLegacyDefaultGoalsIfNeeded() {
        guard !didRemoveLegacyDefaultGoalsV1 else { return }
        guard didSeedDefaultGoals else {
            didRemoveLegacyDefaultGoalsV1 = true
            return
        }

        let legacyGoals = goals.filter(isLegacyDefaultGoal)
        let legacyGoalIDs = Set(legacyGoals.map(\.id))

        for record in records where record.goalId.map(legacyGoalIDs.contains) == true {
            record.goalId = nil
        }
        for goal in legacyGoals {
            modelContext.delete(goal)
        }

        do {
            try modelContext.save()
            didSeedDefaultGoals = false
            didRemoveLegacyDefaultGoalsV1 = true
        } catch {
            modelContext.rollback()
            #if DEBUG
            print("Failed to remove legacy default goals: \(error.localizedDescription)")
            #endif
        }
    }

    private func isLegacyDefaultGoal(_ goal: Goal) -> Bool {
        switch (goal.title, goal.type, goal.targetValue, goal.icon) {
        case ("新相机基金", .money, 3000, "camera.fill"):
            true
        case ("少喝奶茶", .food, 900, "cup.and.saucer.fill"),
             ("本周少喝 3 杯奶茶", .food, 900, "cup.and.saucer.fill"):
            true
        case ("拿回 10 小时", .time, 600, "moon.stars.fill"),
             ("本周拿回 10 小时", .time, 600, "moon.stars.fill"):
            true
        default:
            false
        }
    }

    private func seedFoodNutritionItemsIfNeeded() {
        guard foodSeedVersion < FoodSeedData.version else { return }
        FoodSeedData.sync(into: modelContext)
        foodSeedVersion = FoodSeedData.version
    }

}

enum AppTab: Hashable {
    case home
    case results
    case profile

    var title: String {
        switch self {
        case .home: "今天"
        case .results: "成果"
        case .profile: "我的"
        }
    }

    var symbolName: String {
        switch self {
        case .home: "pause.circle.fill"
        case .results: "chart.bar.fill"
        case .profile: "person.crop.circle"
        }
    }
}
