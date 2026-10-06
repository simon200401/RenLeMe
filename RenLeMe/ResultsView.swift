import SwiftData
import SwiftUI

struct ResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @AppStorage("homeAssetPeriod") private var assetPeriod: AssetPeriod = .week
    @State private var editingGoal: Goal?
    @State private var addingGoalType: ResistType?
    @State private var assetFaces: [ResistType: DynamicMascotExpression] = [:]
    @State private var completedGoalMoment: MascotMoment?
    @State private var activeAssetType: ResistType?
    @State private var recordToDelete: ResistRecord?
    @State private var isConfirmingDelete = false
    @State private var deleteFailed = false

    private var assets: AssetSummary {
        StatsCalculator.assets(from: records, period: assetPeriod)
    }

    private var completedWeekdays: Set<Int> {
        let weekRecords = StatsCalculator.resistedThisWeek(in: records)
        return Set(weekRecords.map { Calendar.current.component(.weekday, from: $0.createdAt) })
    }

    private var recentRecords: [ResistRecord] {
        Array(records.prefix(5))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PunchyCard(fill: .cream, cornerRadius: 28, padding: 16) {
                        WeekDotRow(completedWeekdays: completedWeekdays, activeColor: .punchBlack)
                    }
                    assetGrid
                    goalSection
                    recentSection
                    PeekingMascot()
                        .padding(.top, 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 32)
            }
            .appScrollDefaults()

            if let completedGoalMoment {
                MascotFeedbackPopup(moment: completedGoalMoment) {
                    hideGoalCelebration()
                }
                .zIndex(5)
            }
        }
        .onAppear {
            assetFaces = MascotVariety.distinctFaces(previous: assetFaces, pool: MascotVariety.assetPool)
        }
        .navigationTitle("成果")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: activeAssetType) {
            guard let activeAssetType else { return }
            do {
                try await Task.sleep(for: .seconds(1.3))
            } catch {
                return
            }
            if self.activeAssetType == activeAssetType { self.activeAssetType = nil }
        }
        .task(id: completedGoalMoment) {
            guard completedGoalMoment != nil else { return }
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            hideGoalCelebration()
        }
        .alert("删除这条记录？", isPresented: $isConfirmingDelete) {
            Button("删除", role: .destructive) { deleteSelectedRecord() }
            Button("取消", role: .cancel) { recordToDelete = nil }
        } message: {
            Text("「\(recordToDelete?.title ?? "这条记录")」删除后不可恢复，对应资产和目标进度会同步更新。")
        }
        .alert("删除失败，请重试", isPresented: $deleteFailed) {
            Button("知道了", role: .cancel) {}
        }
        .sheet(item: $addingGoalType) { type in
            NavigationStack {
                AddGoalView(initialType: type)
            }
        }
        .sheet(item: $editingGoal) { goal in
            NavigationStack {
                EditGoalView(goal: goal)
            }
        }
    }

    private var assetGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("我的忍耐资产")
                .font(.rounded(34, weight: .black))
                .foregroundStyle(Color.punchBlack)

            Picker("资产时间范围", selection: $assetPeriod) {
                ForEach(AssetPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)
            .accessibilityIdentifier("assetPeriodPicker")

            VStack(spacing: 12) {
                assetCard(.money, value: assets.money.moneyString)
                HStack(spacing: 12) {
                    assetCard(.food, value: assets.calories.calorieString)
                    assetCard(.time, value: assets.minutes.displayValue(for: .time))
                }
            }
        }
    }

    private func assetCard(_ type: ResistType, value: String) -> some View {
        AssetBlockCard(
            type: type,
            value: value,
            subtitle: "",
            isPaused: completedGoalMoment != nil || editingGoal != nil || (activeAssetType != nil && activeAssetType != type),
            face: assetFaces[type],
            onReaction: { activeAssetType = type }
        )
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("资产去向")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)

                Spacer()

                NavigationLink {
                    GoalsView()
                } label: {
                    StatusChip(title: goals.isEmpty ? "新建" : "全部", fill: .punchBlack)
                }
                .accessibilityIdentifier("goalsLink")
            }

            if goals.isEmpty {
                GoalPlaceholderCard {
                    addingGoalType = .money
                }
                .accessibilityIdentifier("resultsAddGoalButton")
            } else {
                VStack(spacing: 12) {
                    ForEach(goals.prefix(3)) { goal in
                        GoalProgressCard(goal: goal, records: records) {
                            if isGoalCompleted(goal) {
                                showGoalCelebration(.goalCompleted(goal.type))
                            } else {
                                editingGoal = goal
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近记录")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)

                Spacer()

                NavigationLink {
                    HistoryRecordsView()
                } label: {
                    StatusChip(title: "全部", fill: .punchBlack)
                }
            }

            if recentRecords.isEmpty {
                PunchyCard(fill: .cardBackground) {
                    EmptyStateView(title: "还没有记录", message: "", systemImage: "tray")
                }
            } else {
                ForEach(recentRecords) { record in
                    NavigationLink {
                        RecordDetailView(record: record)
                    } label: {
                        RecordRow(record: record)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button(role: .destructive) {
                            requestDeletion(of: record)
                        } label: {
                            Label("删除记录", systemImage: "trash")
                        }
                    }
                    .accessibilityAction(named: "删除记录") {
                        requestDeletion(of: record)
                    }
                }
            }
        }
    }

    private func requestDeletion(of record: ResistRecord) {
        recordToDelete = record
        isConfirmingDelete = true
    }

    private func deleteSelectedRecord() {
        guard let record = recordToDelete else { return }
        let id = record.id
        let imagePath = record.customImagePath
        modelContext.delete(record)
        do {
            try modelContext.save()
            CooldownCoordinator.cancel(recordId: id)
            LocalImageStore.delete(imagePath)
        } catch {
            modelContext.rollback()
            deleteFailed = true
        }
        recordToDelete = nil
    }

    private func isGoalCompleted(_ goal: Goal) -> Bool {
        StatsCalculator.currentValue(for: goal, records: records) / max(goal.targetValue, 1) >= 1
    }

    private func showGoalCelebration(_ moment: MascotMoment) {
        if reduceMotion {
            completedGoalMoment = moment
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                completedGoalMoment = moment
            }
        }
    }

    private func hideGoalCelebration() {
        if reduceMotion {
            completedGoalMoment = nil
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                completedGoalMoment = nil
            }
        }
    }
}
