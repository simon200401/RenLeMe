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
        return true
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
        if let recordId = response.notification.request.content.userInfo["recordId"] as? String {
            UserDefaults.standard.set(recordId, forKey: "renleme.pendingCooldownRoute")
            NotificationCenter.default.post(name: .openCooldownRecord, object: recordId)
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
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
        .modelContainer(for: [ResistRecord.self, Goal.self, FoodNutritionItem.self])
    }
}

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @AppStorage("didSeedDefaultGoals") private var didSeedDefaultGoals = false
    @AppStorage("didSeedFoodNutritionItems") private var didSeedFoodNutritionItems = false
    @AppStorage("didRemoveLegacyDefaultGoalsV1") private var didRemoveLegacyDefaultGoalsV1 = false
    @AppStorage("didCompleteWelcomeOnboarding") private var didCompleteWelcomeOnboarding = false
    @State private var selectedTab: AppTab = .home
    @State private var isPresentingRecord = false
    @State private var isShowingWelcomeOnboarding = false
    @State private var isShowingLaunchSplash = true
    @State private var routedCooldownRecord: ResistRecord?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(onAddRecord: { isPresentingRecord = true })
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.symbolName)
            }
            .tag(AppTab.home)

            NavigationStack {
                RecordFlowView()
            }
            .tabItem {
                Label(AppTab.record.title, systemImage: AppTab.record.symbolName)
            }
            .tag(AppTab.record)

            NavigationStack {
                GoalsView()
            }
            .tabItem {
                Label(AppTab.goals.title, systemImage: AppTab.goals.symbolName)
            }
            .tag(AppTab.goals)

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
        .tint(.accentPurple)
        .blur(radius: isShowingWelcomeOnboarding ? 2.4 : 0)
        .saturation(isShowingWelcomeOnboarding ? 0.58 : 1)
        .brightness(isShowingWelcomeOnboarding ? -0.05 : 0)
        .scaleEffect(isShowingWelcomeOnboarding ? 0.985 : 1)
        .animation(.easeOut(duration: 0.22), value: isShowingWelcomeOnboarding)
        .sheet(isPresented: $isPresentingRecord) {
            NavigationStack {
                RecordFlowView(isModal: true)
            }
            .presentationDetents([.large])
        }
        .sheet(item: $routedCooldownRecord) { record in
            NavigationStack {
                RecordDetailView(record: record)
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
            removeLegacyDefaultGoalsIfNeeded()
            seedFoodNutritionItemsIfNeeded()
            routePendingCooldownIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCooldownRecord)) { notification in
            guard let rawId = notification.object as? String, let id = UUID(uuidString: rawId) else { return }
            routeToCooldownRecord(id: id)
        }
        .onChange(of: records.count) { _, _ in
            routePendingCooldownIfNeeded()
        }
        .appKeyboardDismissal()
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
        guard !didSeedFoodNutritionItems else { return }

        for item in FoodSeedData.items {
            modelContext.insert(item)
        }

        didSeedFoodNutritionItems = true
    }

}

enum AppTab: Hashable {
    case home
    case record
    case goals
    case profile

    var title: String {
        switch self {
        case .home: "首页"
        case .record: "记录"
        case .goals: "目标"
        case .profile: "我的"
        }
    }

    var symbolName: String {
        switch self {
        case .home: "house.fill"
        case .record: "plus.circle.fill"
        case .goals: "target"
        case .profile: "person.crop.circle"
        }
    }
}
