import SwiftData
import SwiftUI
import UIKit

@main
struct RenLeMeApp: App {
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
    @AppStorage("didSeedDemoRecords") private var didSeedDemoRecords = false
    @AppStorage("didCompleteWelcomeOnboarding") private var didCompleteWelcomeOnboarding = false
    @State private var selectedTab: AppTab = .home
    @State private var isPresentingRecord = false
    @State private var isShowingWelcomeOnboarding = false
    @State private var isShowingLaunchSplash = true

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
            seedDefaultGoalsIfNeeded()
            seedFoodNutritionItemsIfNeeded()
            seedDemoRecordsIfNeeded()
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

    private func seedDefaultGoalsIfNeeded() {
        guard !didSeedDefaultGoals else { return }
        modelContext.insert(Goal(title: "新相机基金", type: .money, targetValue: 3000, icon: "camera.fill"))
        modelContext.insert(Goal(title: "本周少喝 3 杯奶茶", type: .food, targetValue: 900, icon: "cup.and.saucer.fill"))
        modelContext.insert(Goal(title: "本周拿回 10 小时", type: .time, targetValue: 600, icon: "moon.stars.fill"))
        didSeedDefaultGoals = true
    }

    private func seedFoodNutritionItemsIfNeeded() {
        guard !didSeedFoodNutritionItems else { return }

        for item in FoodSeedData.items {
            modelContext.insert(item)
        }

        didSeedFoodNutritionItems = true
    }

    private func seedDemoRecordsIfNeeded() {
        guard !didSeedDemoRecords else { return }
        guard records.isEmpty else {
            didSeedDemoRecords = true
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let cameraGoalId = goals.first { $0.title.contains("相机") }?.id
        let milkTeaGoalId = goals.first { $0.title.contains("奶茶") }?.id

        modelContext.insert(ResistRecord(
            type: .food,
            title: "奶茶",
            value: 420,
            status: .resisted,
            reason: "馋了",
            createdAt: calendar.date(byAdding: .minute, value: -20, to: now) ?? now,
            resolvedAt: calendar.date(byAdding: .minute, value: -20, to: now) ?? now,
            note: "换成了热水，先过这一阵。",
            goalId: milkTeaGoalId,
            propTemplateId: "food.milkTea",
            propIconKey: .milkTea
        ))

        modelContext.insert(ResistRecord(
            type: .time,
            title: "短视频",
            value: 30,
            status: .pending,
            reason: "习惯性打开",
            createdAt: calendar.date(byAdding: .minute, value: -35, to: now) ?? now,
            cooldownUntil: calendar.date(byAdding: .minute, value: 15, to: now),
            enteredCooldown: true,
            note: "稍后再看",
            propTemplateId: "time.shortVideo",
            propIconKey: .shortVideo
        ))

        modelContext.insert(ResistRecord(
            type: .money,
            title: "相机",
            value: 128,
            status: .resisted,
            reason: "奖励自己",
            createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            resolvedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            note: "相机基金",
            goalId: cameraGoalId,
            propTemplateId: "money.camera",
            propIconKey: .camera
        ))

        modelContext.insert(ResistRecord(
            type: .food,
            title: "外卖",
            value: 800,
            status: .gaveIn,
            reason: "压力大",
            createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            resolvedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            note: "已记录",
            propTemplateId: "food.takeout",
            propIconKey: .takeout
        ))

        didSeedDemoRecords = true
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
