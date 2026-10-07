import SwiftData
import SwiftUI

/// The closing card for a goal: shown when a full goal is tapped, where the user takes it off the
/// board, and again from the shelf to look back at it. It states what happened and asks nothing —
/// what the user did with the money or the time is theirs.
struct GoalAchievedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var records: [ResistRecord]

    let goal: Goal
    @State private var saveFailed = false

    private var resistedCount: Int {
        records.filter { $0.status == .resisted && $0.goalId == goal.id }.count
    }

    private var days: Int {
        let end = goal.achievedAt ?? .now
        let span = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: goal.createdAt), to: Calendar.current.startOfDay(for: end)
        ).day ?? 0
        return max(span, 0) + 1
    }

    /// One plain sentence instead of a row of figures.
    private var summary: String {
        let amount = goal.targetValue.displayValue(for: goal.type)
        let verb: String = switch goal.type {
        case .money: "攒够了"
        case .food: "守住了"
        case .time: "拿回了"
        }
        // Part of a goal can come from what spilled over from another one, with no record of its own.
        let effort = resistedCount > 0 ? "，忍住 \(resistedCount) 次" : ""
        return "用了 \(days) 天\(effort)，\(verb) \(amount)。"
    }

    var body: some View {
        ZStack {
            Color.softBlockColor(for: goal.type).ignoresSafeArea()

            if !goal.isAchieved {
                ConfettiBurst()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 18) {
                Spacer(minLength: 8)

                ZStack(alignment: .bottomTrailing) {
                    GoalIconView(goal: goal, size: 112)

                    AnimatedXiaoRenView(
                        color: Color(red: 1.0, green: 0.949, blue: 0.839),
                        expression: goal.isAchieved ? .proud : .celebrate,
                        size: 64,
                        reduceMotion: reduceMotion,
                        reaction: goal.isAchieved ? nil : .celebrate
                    )
                    .offset(x: 26, y: 18)
                }
                .padding(.bottom, 6)

                VStack(spacing: 8) {
                    Text(goal.isAchieved ? "已实现" : "实现了")
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(Color.secondaryInk)

                    Text(goal.title)
                        .font(.rounded(28, weight: .black))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(summary)
                        .font(.rounded(16, weight: .black))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let achievedAt = goal.achievedAt {
                        Text(Self.dateText(achievedAt))
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                    }
                }

                Spacer(minLength: 8)

                if goal.isAchieved {
                    Button("放回目标里") { setAchieved(nil) }
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .padding(.vertical, 8)
                        .accessibilityIdentifier("goalReopenButton")
                } else {
                    VStack(spacing: 6) {
                        Button {
                            AppHaptics.success()
                            setAchieved(.now)
                        } label: {
                            Text("收进已实现")
                                .font(.rounded(18, weight: .black))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.punchBlack)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PressableScaleStyle())
                        .accessibilityIdentifier("goalAchieveButton")

                        Button("先留着") { dismiss() }
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("没有保存成功，请重试", isPresented: $saveFailed) {
            Button("知道了", role: .cancel) {}
        }
    }

    private func setAchieved(_ date: Date?) {
        goal.achievedAt = date
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            saveFailed = true
        }
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

/// The shelf: every goal the user has taken down, most recent first.
struct AchievedGoalsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var opened: Goal?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                if goals.achieved.isEmpty {
                    PunchyCard(fill: .cardBackground, cornerRadius: 24) {
                        EmptyStateView(title: "还没有实现的目标", message: "", systemImage: "flag")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(goals.achieved) { goal in
                            Button {
                                opened = goal
                            } label: {
                                tile(goal)
                            }
                            .buttonStyle(PressableScaleStyle())
                            .accessibilityLabel("\(goal.title)，\(goal.achievedAt.map(GoalAchievedSheet.dateText) ?? "")实现")
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 28)
                }
            }
            .appScrollDefaults()
        }
        .navigationTitle("已实现")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { goal in
            GoalAchievedSheet(goal: goal)
        }
    }

    private func tile(_ goal: Goal) -> some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 24, padding: 14) {
            VStack(spacing: 10) {
                GoalIconView(goal: goal, size: 72)

                VStack(spacing: 4) {
                    Text(goal.title)
                        .font(.rounded(16, weight: .black))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(goal.targetValue.displayValue(for: goal.type))
                        .font(.rounded(13, weight: .black))
                        .foregroundStyle(Color.secondaryInk)

                    if let achievedAt = goal.achievedAt {
                        Text(GoalAchievedSheet.dateText(achievedAt))
                            .font(.rounded(12, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// The way onto the shelf: one slim row with the goals' own pictures. Not shown while the shelf is empty.
struct AchievedShelfRow: View {
    let goals: [Goal]

    private static let iconLimit = 4

    var body: some View {
        let achieved = goals.achieved
        if !achieved.isEmpty {
            NavigationLink {
                AchievedGoalsView()
            } label: {
                PunchyCard(fill: .cardBackground, cornerRadius: 24, padding: 12) {
                    HStack(spacing: 8) {
                        Text("已实现 · \(achieved.count)")
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.ink)

                        Spacer(minLength: 6)

                        ForEach(achieved.prefix(Self.iconLimit)) { goal in
                            GoalIconView(goal: goal, size: 34)
                        }

                        Image(systemName: "chevron.right")
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                    }
                    .frame(height: HomeView.slimRowHeight)
                }
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityLabel("已实现的目标，\(achieved.count) 个")
            .accessibilityIdentifier("achievedShelfRow")
        }
    }
}
