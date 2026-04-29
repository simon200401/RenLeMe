import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @State private var pendingFeedbackMoment: MascotMoment?
    @State private var pendingFeedbackMessage: String?
    var onShowWelcome: () -> Void = {}

    private var weekRecords: [ResistRecord] {
        StatsCalculator.resistedThisWeek(in: records)
    }

    private var monthRecords: [ResistRecord] {
        StatsCalculator.resistedThisMonth(in: records)
    }

    private var pendingRecords: [ResistRecord] {
        records.filter { $0.status == .pending }
    }

    private var dailyCounts: [Int] {
        StatsCalculator.dailyResistedCounts(in: records)
    }

    private var currentStreak: Int {
        StatsCalculator.currentStreak(in: records)
    }

    private var strongestTypeThisWeek: ResistType? {
        StatsCalculator.strongestTypeThisWeek(in: records)
    }

    private var unlockedBadgeCount: Int {
        achievementBadges.filter(\.unlocked).count
    }

    private var achievementBadges: [AchievementBadge] {
        [
            AchievementBadge(
                title: "第一次忍住",
                iconKey: .badge,
                unlocked: records.contains { $0.status == .resisted },
                message: "第一次把冲动停下来，很重要。"
            ),
            AchievementBadge(
                title: "连续记录",
                iconKey: .calendar,
                unlocked: currentStreak >= 3 || weekRecords.count >= 3,
                message: "节奏已经出现了，小忍记得很清楚。"
            ),
            AchievementBadge(
                title: "拿回 5 小时",
                iconKey: .chart,
                unlocked: StatsCalculator.totalValue(for: .time, records: records) >= 300,
                message: "这些时间，本来就该回到你手里。"
            ),
            AchievementBadge(
                title: "冷静后仍选择",
                iconKey: .coolBox,
                unlocked: records.contains { $0.enteredCooldown && $0.status == .resisted },
                message: "你没有急着裁判自己，而是等了一下。"
            )
        ]
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    reflectionCard
                    statsCard
                    badgesCard
                    pendingCard
                    helpCard
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .appScrollDefaults()

            if let pendingFeedbackMoment {
                MascotFeedbackPopup(moment: pendingFeedbackMoment, message: pendingFeedbackMessage) {
                    hidePendingFeedback()
                }
            }
        }
        .navigationTitle("我的")
    }

    private var reflectionCard: some View {
        PunchyCard(fill: .punchGreen, cornerRadius: 34, padding: 20) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Review")
                        .font(.rounded(42, weight: .black))
                        .foregroundStyle(Color.white)

                    Text("复盘，不审判")
                        .font(.rounded(24, weight: .black))
                        .foregroundStyle(Color.white)

                    Text(reflectionText)
                        .font(.rounded(15, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                MascotMomentView(moment: .reviewCalm, size: 82)
            }
        }
    }

    private var statsCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text("基础统计")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)
                    .overlay(alignment: .trailing) {
                        if let chart = PropTemplate.templates.first(where: { $0.iconKey == .chart }) {
                            PropIconView(template: chart, size: 38)
                                .offset(x: 48)
                        }
                    }

                HStack(spacing: 10) {
                    SmallStat(title: "本周忍住", value: "\(weekRecords.count)", suffix: "次", fill: .punchYellow)
                    SmallStat(title: "本月忍住", value: "\(monthRecords.count)", suffix: "次", fill: .punchPink)
                    SmallStat(title: "冷静箱", value: "\(pendingRecords.count)", suffix: "件", fill: .punchGreen)
                }

                ReviewMomentumPanel(
                    dailyCounts: dailyCounts,
                    currentStreak: currentStreak,
                    strongestType: strongestTypeThisWeek,
                    reduceMotion: reduceMotion
                )
                .onTapGesture {
                    showPendingFeedback(
                        currentStreak > 0 ? .resistedSuccess : .reviewCalm,
                        message: currentStreak > 0
                            ? "连续 \(currentStreak) 天看见并处理冲动，这不是小事。"
                            : "先看见自己的节奏，就已经是在往前走。"
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    StatLine(type: .money, records: weekRecords)
                    StatLine(type: .food, records: weekRecords)
                    StatLine(type: .time, records: weekRecords)
                }
            }
        }
    }

    private var badgesCard: some View {
        PunchyCard(fill: .cream, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("GoalGoalGoal")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)

                HStack(spacing: 10) {
                    MascotMomentView(moment: unlockedBadgeCount > 0 ? .resistedSuccess : .idle, size: 58)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("已点亮 \(unlockedBadgeCount)/\(achievementBadges.count)")
                            .font(.rounded(18, weight: .black))
                            .foregroundStyle(Color.ink)
                        Text(unlockedBadgeCount > 0 ? "每个小选择，都算数。" : "第一枚会从一次小小忍住开始。")
                            .font(.rounded(13, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(achievementBadges) { badge in
                        BadgeView(badge: badge) {
                            showPendingFeedback(
                                badge.unlocked ? .resistedSuccess : .reviewCalm,
                                message: badge.unlocked
                                    ? badge.message
                                    : "这枚还没点亮。下一次记录，也许就会靠近一点。"
                            )
                        }
                    }
                }
            }
        }
    }

    private var pendingCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("冷静箱")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)

                if pendingRecords.isEmpty {
                    EmptyStateView(title: "冷静箱是空的", message: "等一下再决定，也是一种决定。", systemImage: "archivebox")
                } else {
                    VStack(spacing: 12) {
                        ForEach(pendingRecords) { record in
                            PendingRecordRow(record: record) { moment in
                                showPendingFeedback(moment)
                            }
                        }
                    }
                }
            }
        }
    }

    private var helpCard: some View {
        PunchyCard(fill: .cream, cornerRadius: 30, padding: 16) {
            Button {
                onShowWelcome()
            } label: {
                HStack(spacing: 12) {
                    AnimatedXiaoRenView(color: .punchGreen, expression: .hello, size: 58, reduceMotion: reduceMotion)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("再看一遍上手引导")
                            .font(.rounded(18, weight: .black))
                            .foregroundStyle(Color.ink)

                        Text("小忍带你快速回顾记录、冷静箱和忍耐资产。")
                            .font(.rounded(13, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                }
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityLabel("再看一遍上手引导")
        }
    }

    private var reflectionText: String {
        if records.isEmpty {
            return "下一次冲动来临时，先放这里。不是要立刻变得完美，只是多给自己一次选择。"
        }

        if let reason = StatsCalculator.mostCommonReason(in: records) {
            return "最近常出现的是「\(reason)」。也许它不只是想买、想吃或想逃开，也可能是在提醒你：这阵子有点累。"
        }

        return "没关系，至少你看见了它。下次再遇到，我们会更早认出来。"
    }

    private func showPendingFeedback(_ moment: MascotMoment, message: String? = nil) {
        if reduceMotion {
            pendingFeedbackMoment = moment
            pendingFeedbackMessage = message
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                pendingFeedbackMoment = moment
                pendingFeedbackMessage = message
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            hidePendingFeedback()
        }
    }

    private func hidePendingFeedback() {
        if reduceMotion {
            pendingFeedbackMoment = nil
            pendingFeedbackMessage = nil
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                pendingFeedbackMoment = nil
                pendingFeedbackMessage = nil
            }
        }
    }
}

private struct AchievementBadge: Identifiable {
    let title: String
    let iconKey: PropIconKey
    let unlocked: Bool
    let message: String

    var id: String { title }
}

private struct SmallStat: View {
    let title: String
    let value: String
    let suffix: String
    let fill: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.rounded(12, weight: .black))
                .foregroundStyle(Color.punchBlack.opacity(0.72))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.rounded(28, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                Text(suffix)
                    .font(.rounded(12, weight: .black))
                    .foregroundStyle(Color.punchBlack.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ReviewMomentumPanel: View {
    let dailyCounts: [Int]
    let currentStreak: Int
    let strongestType: ResistType?
    let reduceMotion: Bool
    @State private var isAlive = false

    private var maxCount: Int {
        max(dailyCounts.max() ?? 0, 1)
    }

    private var totalThisWeek: Int {
        dailyCounts.reduce(0, +)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(currentStreak > 0 ? "连续 \(currentStreak) 天" : "开始复盘")
                    .font(.rounded(20, weight: .black))
                    .foregroundStyle(Color.ink)

                Text(strongestText)
                    .font(.rounded(13, weight: .bold))
                    .foregroundStyle(Color.secondaryInk)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            HStack(alignment: .bottom, spacing: 5) {
                ForEach(Array(dailyCounts.enumerated()), id: \.offset) { index, count in
                    Capsule()
                        .fill(barColor(for: count))
                        .frame(width: 12, height: barHeight(for: count))
                        .scaleEffect(y: isAlive || reduceMotion ? 1 : 0.18, anchor: .bottom)
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.72).delay(Double(index) * 0.035),
                            value: isAlive
                        )
                }
            }
            .frame(height: 48, alignment: .bottom)

            MascotMomentView(moment: currentStreak > 0 ? .resistedSuccess : .reviewCalm, size: 52)
                .scaleEffect(isAlive && !reduceMotion ? 1.04 : 1)
                .rotationEffect(.degrees(isAlive && !reduceMotion ? -3 : 0))
        }
        .padding(14)
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.punchBlack.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("复盘趋势，本周 \(totalThisWeek) 次，连续 \(currentStreak) 天")
        .onAppear {
            guard !reduceMotion else { return }
            isAlive = true
        }
    }

    private var strongestText: String {
        guard let strongestType else {
            return totalThisWeek > 0 ? "本周已经有 \(totalThisWeek) 次选择被记录。" : "还没有趋势，先从一次记录开始。"
        }

        return "本周最常拿回的是\(strongestType.assetTitle)。"
    }

    private func barHeight(for count: Int) -> CGFloat {
        let normalized = CGFloat(count) / CGFloat(maxCount)
        return 14 + normalized * 34
    }

    private func barColor(for count: Int) -> Color {
        count > 0 ? .punchBlack : Color.punchBlack.opacity(0.12)
    }
}

private struct StatLine: View {
    let type: ResistType
    let records: [ResistRecord]

    private var value: Double {
        StatsCalculator.totalValue(for: type, records: records)
    }

    var body: some View {
        HStack(spacing: 12) {
            TypeIcon(type: type, size: 38)
            Text("本周\(type.assetTitle)")
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.secondaryInk)
            Spacer()
            Text(value.displayValue(for: type))
                .font(.rounded(16, weight: .black))
                .foregroundStyle(Color.ink)
        }
        .padding(12)
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct BadgeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let badge: AchievementBadge
    var onTap: () -> Void
    @State private var flash = false

    private var template: PropTemplate {
        PropTemplate.uiTemplates().first { $0.iconKey == badge.iconKey } ?? PropTemplate.uiTemplates()[0]
    }

    var body: some View {
        Button {
            onTap()
            playFlash()
        } label: {
            HStack(spacing: 8) {
                PropIconView(template: template, size: 38)
                    .opacity(badge.unlocked ? 1 : 0.42)
                    .scaleEffect(flash && badge.unlocked ? 1.12 : 1)

                Text(badge.title)
                    .font(.rounded(13, weight: .black))
                    .foregroundStyle(badge.unlocked ? Color.ink : Color.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(badge.unlocked ? Color.punchYellow.opacity(flash ? 1 : 0.88) : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if badge.unlocked {
                    Circle()
                        .fill(Color.punchGreen)
                        .frame(width: 10, height: 10)
                        .padding(8)
                        .scaleEffect(flash ? 1.35 : 1)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.punchBlack.opacity(badge.unlocked ? 0 : 0.08), lineWidth: 1)
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("\(badge.title)，\(badge.unlocked ? "已点亮" : "未点亮")")
    }

    private func playFlash() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.52)) {
            flash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.easeOut(duration: 0.18)) {
                flash = false
            }
        }
    }
}

private struct PendingRecordRow: View {
    let record: ResistRecord
    var onResolve: (MascotMoment) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RecordRow(record: record)

            HStack(spacing: 10) {
                Button {
                    record.status = .resisted
                    record.resolvedAt = .now
                    record.cooldownUntil = nil
                    onResolve(.resistedSuccess)
                } label: {
                    Text("我忍住了")
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.punchBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())

                Button {
                    record.status = .gaveIn
                    record.resolvedAt = .now
                    record.cooldownUntil = nil
                    onResolve(.gaveInSaved)
                } label: {
                    Text("我还是做了")
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cream)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
    }
}
