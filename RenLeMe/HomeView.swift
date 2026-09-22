import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var editingGoal: Goal?
    @State private var completedGoalMoment: MascotMoment?
    @AppStorage("homeAssetPeriod") private var assetPeriod: AssetPeriod = .week
    @State private var recordToDelete: ResistRecord?
    @State private var isConfirmingDelete = false
    @State private var deleteFailed = false

    let onAddRecord: () -> Void

    private var assets: AssetSummary {
        StatsCalculator.assets(from: records, period: assetPeriod)
    }

    private var todayCount: Int {
        StatsCalculator.resistedToday(in: records)
    }

    private var recentRecords: [ResistRecord] {
        Array(records.prefix(5))
    }

    private var pendingRecords: [ResistRecord] {
        records
            .filter { $0.status == .pending }
            .sorted {
                ($0.cooldownUntil ?? .distantFuture) < ($1.cooldownUntil ?? .distantFuture)
            }
    }

    private var completedWeekdays: Set<Int> {
        let weekRecords = StatsCalculator.resistedThisWeek(in: records)
        return Set(weekRecords.map { Calendar.current.component(.weekday, from: $0.createdAt) })
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    pendingSection
                    assetGrid
                    goalProgressSection
                    recentSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 100)
            }
            .appScrollDefaults()

            Button(action: onAddRecord) {
                Image(systemName: "plus")
                    .font(.rounded(30, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(width: 66, height: 66)
                    .background(Color.punchBlack)
                    .clipShape(Circle())
                    .shadow(color: .punchBlack.opacity(0.24), radius: 0, x: 0, y: 8)
            }
            .buttonStyle(PressableScaleStyle())
            .padding(.trailing, 22)
            .padding(.bottom, 24)
            .accessibilityLabel("忍一下")
            .accessibilityIdentifier("addRecordButton")

            if let completedGoalMoment {
                MascotFeedbackPopup(moment: completedGoalMoment) {
                    hideGoalCelebration()
                }
                .zIndex(5)
            }
        }
        .navigationTitle("忍了么")
        .navigationBarTitleDisplayMode(.inline)
        .alert("删除这条记录？", isPresented: $isConfirmingDelete) {
            Button("删除", role: .destructive) { deleteSelectedRecord() }
            Button("取消", role: .cancel) { recordToDelete = nil }
        } message: {
            Text("「\(recordToDelete?.title ?? "这条记录")」删除后不可恢复，对应资产和目标进度会同步更新。")
        }
        .alert("删除失败，请重试", isPresented: $deleteFailed) {
            Button("知道了", role: .cancel) {}
        }
        .sheet(item: $editingGoal) { goal in
            NavigationStack {
                EditGoalView(goal: goal)
            }
        }
    }

    private var hero: some View {
        PunchyCard(fill: .cream, cornerRadius: 34, padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today: \(todayCount) 次")
                            .font(.rounded(30, weight: .black))
                            .foregroundStyle(Color.punchBlack)

                    }

                    Spacer()

                    AnimatedXiaoRenView(
                        color: todayCount > 0 ? Color.punchGreen : Color(red: 1.0, green: 0.949, blue: 0.839),
                        expression: todayCount > 0 ? .celebrate : .hello,
                        size: 72,
                        reduceMotion: reduceMotion
                    )
                }

                WeekDotRow(completedWeekdays: completedWeekdays, activeColor: .punchBlack)
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
                AssetBlockCard(type: .money, value: assets.money.moneyString, subtitle: "")
                HStack(spacing: 12) {
                    AssetBlockCard(type: .food, value: assets.calories.calorieString, subtitle: "")
                    AssetBlockCard(type: .time, value: assets.minutes.displayValue(for: .time), subtitle: "")
                }
            }
        }
    }

    @ViewBuilder
    private var pendingSection: some View {
        if let record = pendingRecords.first {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "继续冷静")

                NavigationLink {
                    RecordDetailView(record: record)
                } label: {
                    PunchyCard(
                        fill: Color.softBlockColor(for: record.type),
                        cornerRadius: 26,
                        padding: 14
                    ) {
                        HStack(spacing: 12) {
                            RecordPropIconView(record: record, size: 52)

                            VStack(alignment: .leading, spacing: 7) {
                                Text(record.title)
                                    .font(.rounded(19, weight: .black))
                                    .foregroundStyle(Color.ink)
                                    .lineLimit(1)

                                CooldownStatusLabel(record: record)
                            }

                            Spacer(minLength: 6)

                            if pendingRecords.count > 1 {
                                Text("+\(pendingRecords.count - 1)")
                                    .font(.rounded(14, weight: .black))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.punchBlack)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.rounded(14, weight: .black))
                                    .foregroundStyle(Color.punchBlack)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("继续处理\(record.title)")
            }
        }
    }

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "资产去向")

            if goals.isEmpty {
                PunchyCard(fill: .punchYellow) {
                    EmptyStateView(title: "还没有目标", message: "", systemImage: "target")
                }
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
        goalProgress(for: goal) >= 1
    }

    private func goalProgress(for goal: Goal) -> Double {
        let current = StatsCalculator.currentValue(for: goal, records: records)
        return current / max(goal.targetValue, 1)
    }

    private func showGoalCelebration(_ moment: MascotMoment) {
        if reduceMotion {
            completedGoalMoment = moment
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                completedGoalMoment = moment
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            hideGoalCelebration()
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

private struct GoalProgressCard: View {
    let goal: Goal
    let records: [ResistRecord]
    var onTap: () -> Void = {}

    private var current: Double {
        StatsCalculator.currentValue(for: goal, records: records)
    }

    private var progress: Double {
        current / max(goal.targetValue, 1)
    }

    private var remaining: Double {
        max(goal.targetValue - current, 0)
    }

    var body: some View {
        Button(action: onTap) {
            PunchyCard(fill: Color.softBlockColor(for: goal.type), cornerRadius: 28, padding: 16) {
                HStack(spacing: 14) {
                    GoalIconView(goal: goal, size: 68)

                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 10) {
                            Text(goal.title)
                                .font(.rounded(18, weight: .black))
                                .foregroundStyle(Color.ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)

                            Spacer()

                            StatusChip(title: "\(Int(min(progress, 1) * 100))%", fill: .punchBlack)
                        }

                        ProgressLine(progress: progress, tint: Color.blockColor(for: goal.type))

                        Text(remaining > 0 ? "还差 \(remaining.displayValue(for: goal.type))" : "已经完成，点一下庆祝。")
                            .font(.rounded(13, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("\(goal.title)，进度 \(Int(min(progress, 1) * 100))%，点击\(remaining > 0 ? "编辑目标" : "庆祝完成")")
    }
}

struct RecordRow: View {
    let record: ResistRecord

    private var rowFill: Color {
        switch record.status {
        case .resisted: Color.softBlockColor(for: record.type)
        case .pending: Color.punchYellow.opacity(0.82)
        case .gaveIn: Color.cardBackground
        }
    }

    var body: some View {
        PunchyCard(fill: rowFill, cornerRadius: 24, padding: 12) {
            HStack(spacing: 12) {
                RecordPropIconView(record: record, size: 48)

                VStack(alignment: .leading, spacing: 5) {
                    Text(record.title)
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("\(recordValueText) · \(record.status.title)")
                        .font(.rounded(13, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    if record.type == .food, let grams = record.foodServingGrams, let source = record.foodSourceName {
                        Text("\(grams.cleanString)g · \(source)")
                            .font(.rounded(11, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    StatusChip(title: record.status.title, fill: statusColor)
                    Text(record.createdAt.shortTimeText)
                        .font(.rounded(12, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
    }

    private var statusColor: Color {
        switch record.status {
        case .resisted: .punchGreen
        case .pending: .punchBlack
        case .gaveIn: .secondaryInk
        }
    }

    private var recordValueText: String {
        record.displayValueText
    }
}
