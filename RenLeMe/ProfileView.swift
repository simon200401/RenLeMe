import SwiftData
import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @AppStorage(WeeklySummaryScheduler.enabledKey) private var weeklySummaryEnabled = false
    @AppStorage(AppSettings.cooldownReminderKey) private var cooldownReminderEnabled = true
    @AppStorage(AppSettings.hapticsKey) private var hapticsEnabled = true
    @State private var isShowingGrowth = false
    @State private var isShowingDataPrivacy = false
    @State private var notificationsDenied = false
    @State private var exportFile: ExportFile?
    @State private var exportFailed = false
    @State private var heroFace: DynamicMascotExpression?
    /// Bumped when a cooldown length changes, so the settings row re-reads it.
    @State private var cooldownLengthToken = 0
    var onShowWelcome: () -> Void = {}

    private var growth: MascotGrowth {
        MascotGrowth(records: records)
    }

    private var insights: RecordInsights {
        RecordInsights(records: records)
    }

    private var pendingRecords: [ResistRecord] {
        records.filter { $0.status == .pending }
    }

    private var milestones: [Milestone] {
        [
            Milestone(title: "第一次忍住", symbol: "star.fill",
                      isReached: records.contains { $0.status == .resisted }),
            Milestone(title: "冷静后忍住", symbol: "archivebox.fill",
                      isReached: records.contains { $0.enteredCooldown && $0.status == .resisted }),
            Milestone(title: "拿回 5 小时", symbol: "clock.fill",
                      isReached: StatsCalculator.totalValue(for: .time, records: records) >= 300),
            Milestone(title: "第一个目标", symbol: "target", isReached: !goals.isEmpty)
        ]
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    profileCard

                    cooldownBoxLink
                        .padding(.top, 4)

                    sectionTitle("回顾")
                    if insights.peakTime == nil {
                        reviewWaitingCard
                    } else {
                        peakTimeCard
                    }
                    typeRowsCard

                    sectionTitle("里程碑")
                    milestoneRow

                    sectionTitle("提醒")
                    reminderGroup

                    sectionTitle("偏好")
                    preferenceGroup

                    sectionTitle("数据与帮助")
                    dataGroup
                }
.padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 18)
                .padding(.bottom, 24)
            }
            .appScrollDefaults()
        }
        .onAppear {
            heroFace = MascotVariety.next(
                from: growth.resistedCount > 0 ? [.proud, .settled, .hello, .heartEyes] : [.hello, .curious, .settled],
                avoiding: [heroFace]
            )
        }
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingGrowth) {
            GrowthLadderView(growth: growth)
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingDataPrivacy) {
            NavigationStack {
                DataPrivacyView()
            }
        }
        .sheet(item: $exportFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
        .alert("通知没有打开", isPresented: $notificationsDenied) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("知道了", role: .cancel) {}
        } message: {
            Text("在系统设置里允许通知后，再打开这个提醒。")
        }
        .alert("导出失败，请重试", isPresented: $exportFailed) {
            Button("知道了", role: .cancel) {}
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.rounded(22, weight: .black))
            .foregroundStyle(Color.ink)
            .padding(.top, 10)
            .padding(.leading, 2)
    }

    // MARK: - 我和小忍

    private var profileCard: some View {
        Button {
            AppHaptics.lightTap()
            isShowingGrowth = true
        } label: {
            PunchyCard(fill: .cream, cornerRadius: 34, padding: 20) {
                HStack(spacing: 16) {
                    AnimatedXiaoRenView(
                        color: Color(red: 1.0, green: 0.949, blue: 0.839),
                        expression: heroFace ?? .hello,
                        size: 92,
                        reduceMotion: reduceMotion
                    )
                    .frame(width: 98, height: 94)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            StatusChip(title: "Lv.\(growth.level) \(growth.stage.title)", fill: .punchBlack)

                            if let remaining = growth.remainingToNextStage {
                                Text("再忍 \(remaining) 次")
                                    .font(.rounded(13, weight: .black))
                                    .foregroundStyle(Color.secondaryInk)
                            }
                        }

                        Text("已忍住 \(growth.resistedCount) 次")
                            .font(.rounded(28, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(togetherText)
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("查看小忍的等级")
        .accessibilityIdentifier("profileCard")
    }

    private var togetherText: String {
        let days = RecordInsights.daysTogether(records: records)
        return days > 0 ? "一起 \(days) 天" : "从第一笔开始算"
    }

    // MARK: - 回顾

    /// One calm card instead of three empty ones while there is nothing to review yet.
    private var reviewWaitingCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 26, padding: 16) {
            HStack(spacing: 14) {
                AnimatedXiaoRenView(
                    color: Color(red: 1.0, green: 0.949, blue: 0.839),
                    expression: .curious,
                    size: 62,
                    reduceMotion: reduceMotion
                )
                .frame(width: 66, height: 62)

                VStack(alignment: .leading, spacing: 8) {
                    Text("再记 \(max(RecordInsights.peakTimeMinimum - insights.urgeCount, 1)) 笔，就能看出心动高峰在什么时候")
                        .font(.rounded(16, weight: .black))
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    ProgressLine(
                        progress: Double(insights.urgeCount) / Double(RecordInsights.peakTimeMinimum),
                        tint: .punchBlack
                    )
                    .opacity(0.35)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("reviewWaitingCard")
    }

    /// When urges tend to come, as a day of bars. Each bar is stacked in the three urge colours,
    /// so the chart says what as well as when.
    @ViewBuilder
    private var peakTimeCard: some View {
        if let peak = insights.peakTime {
            PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("心动高峰")
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(Color.secondaryInk)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(peak.periodName)
                                .font(.rounded(32, weight: .black))
                                .foregroundStyle(Color.punchBlack)
                            Text(peak.hourRange)
                                .font(.rounded(17, weight: .black))
                                .foregroundStyle(Color.secondaryInk)
                        }
                    }

                    VStack(spacing: 8) {
                        DayCurve(values: peak.curve, peakHour: peak.peakHour)
                            .frame(height: 124)

                        HStack {
                            ForEach(["凌晨", "早上", "中午", "傍晚", "深夜"], id: \.self) { label in
                                Text(label)
                                    .font(.rounded(11, weight: .black))
                                    .foregroundStyle(Color.secondaryInk)
                                if label != "深夜" { Spacer(minLength: 0) }
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("一天的起伏曲线，心动高峰在\(peak.peakTitle)")
                }
            }
            .accessibilityIdentifier("peakTimeCard")
        }
    }

    /// How many times each kind of urge has been resisted, one line apiece.
    private var typeRowsCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(spacing: 10) {
                ForEach(ResistType.allCases) { type in
                    let resisted = records.filter { $0.type == type && $0.status == .resisted }.count

                    HStack(spacing: 12) {
                        TypeIcon(type: type, size: 38)

                        Text(type.urgeTitle)
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(Color.ink)

                        Spacer()

                        if resisted > 0 {
                            Text("忍住")
                                .font(.rounded(13, weight: .black))
                                .foregroundStyle(Color.secondaryInk)
                            Text("\(resisted)")
                                .font(.rounded(18, weight: .black))
                                .foregroundStyle(Color.ink)
                                .monospacedDigit()
                            Text("次")
                                .font(.rounded(13, weight: .black))
                                .foregroundStyle(Color.secondaryInk)
                        } else {
                            Text("还没有")
                                .font(.rounded(13, weight: .black))
                                .foregroundStyle(Color.secondaryInk)
                        }
                    }
                    .padding(12)
                    .background(Color.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .accessibilityIdentifier("typeRowsCard")
    }

    // MARK: - 里程碑

    private var milestoneRow: some View {
        HStack(spacing: 8) {
            ForEach(milestones) { milestone in
                VStack(spacing: 8) {
                    Image(systemName: milestone.isReached ? milestone.symbol : "lock.fill")
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(milestone.isReached ? Color.punchBlack : .secondaryInk)
                        .frame(width: 42, height: 42)
                        .background(milestone.isReached ? Color.punchYellow : Color.punchBlack.opacity(0.08))
                        .clipShape(Circle())

                    Text(milestone.title)
                        .font(.rounded(11, weight: .black))
                        .foregroundStyle(milestone.isReached ? Color.ink : .secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .background(milestone.isReached ? Color.cardBackground : Color.punchBlack.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(milestone.title)，\(milestone.isReached ? "已达成" : "未达成")")
            }
        }
    }

    // MARK: - 冷静箱

    private var cooldownBoxLink: some View {
        NavigationLink {
            CooldownBoxView()
        } label: {
            SettingsGroup {
                SettingRow(symbol: "archivebox.fill", tint: Color.softBlockColor(for: .money), title: "冷静箱") {
                    Text("\(pendingRecords.count) 件")
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                    chevron
                }
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityIdentifier("cooldownBoxLink")
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.rounded(13, weight: .black))
            .foregroundStyle(Color.punchBlack)
    }

    // MARK: - 设置

    private var reminderGroup: some View {
        SettingsGroup {
            SettingRow(symbol: "bell.fill", tint: .punchYellow, title: "冷静到期提醒") {
                Toggle("冷静到期提醒", isOn: Binding(
                    get: { cooldownReminderEnabled },
                    set: { setCooldownReminder($0) }
                ))
                .labelsHidden()
                .tint(Color.punchGreen)
                .accessibilityIdentifier("cooldownReminderToggle")
            }

            SettingDivider()

            SettingRow(symbol: "calendar", tint: Color.softBlockColor(for: .food), title: "每周小结", subtitle: "周日 20:00") {
                Toggle("每周小结", isOn: Binding(
                    get: { weeklySummaryEnabled },
                    set: { setWeeklySummary($0) }
                ))
                .labelsHidden()
                .tint(Color.punchGreen)
                .accessibilityIdentifier("weeklySummaryToggle")
            }
        }
    }

    private var preferenceGroup: some View {
        SettingsGroup {
            NavigationLink {
                CooldownLengthView { cooldownLengthToken += 1 }
            } label: {
                SettingRow(symbol: "hourglass", tint: Color.softBlockColor(for: .time), title: "冷静时长", subtitle: cooldownLengthSummary) {
                    chevron
                }
            }
            .buttonStyle(PressableScaleStyle())

            SettingDivider()

            SettingRow(symbol: "iphone.radiowaves.left.and.right", tint: Color.softBlockColor(for: .money), title: "震动") {
                Toggle("震动", isOn: $hapticsEnabled)
                    .labelsHidden()
                    .tint(Color.punchGreen)
                    .accessibilityIdentifier("hapticsToggle")
            }
        }
    }

    private var cooldownLengthSummary: String {
        _ = cooldownLengthToken
        return ResistType.allCases.map(\.cooldownDurationText).joined(separator: " · ")
    }

    private var dataGroup: some View {
        SettingsGroup {
            Button(action: exportRecords) {
                SettingRow(symbol: "square.and.arrow.up.fill", tint: Color.softBlockColor(for: .money), title: "导出记录", subtitle: "\(records.count) 条，表格文件") {
                    chevron
                }
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityIdentifier("exportRecordsButton")

            SettingDivider()

            Button {
                isShowingDataPrivacy = true
            } label: {
                SettingRow(symbol: "lock.shield.fill", tint: .punchYellow, title: "数据与隐私") {
                    chevron
                }
            }
            .buttonStyle(PressableScaleStyle())

            SettingDivider()

            Button(action: onShowWelcome) {
                SettingRow(symbol: "book.fill", tint: Color.softBlockColor(for: .food), title: "再看一遍引导") {
                    chevron
                }
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityLabel("再看一遍上手引导")

            SettingDivider()

            NavigationLink {
                AboutView()
            } label: {
                SettingRow(symbol: "info.circle.fill", tint: Color.softBlockColor(for: .time), title: "关于与反馈") {
                    Text(AboutView.versionText)
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                    chevron
                }
            }
            .buttonStyle(PressableScaleStyle())
        }
    }

    // MARK: - 动作

    private func setCooldownReminder(_ enabled: Bool) {
        guard enabled else {
            cooldownReminderEnabled = false
            for record in pendingRecords {
                CooldownCoordinator.cancel(recordId: record.id)
            }
            return
        }
        WeeklySummaryScheduler.requestAuthorization { granted in
            cooldownReminderEnabled = granted
            notificationsDenied = !granted
            guard granted else { return }
            // Things already waiting get their reminder back.
            for record in pendingRecords {
                CooldownCoordinator.schedule(for: record)
            }
        }
    }

    private func setWeeklySummary(_ enabled: Bool) {
        guard enabled else {
            weeklySummaryEnabled = false
            return
        }
        WeeklySummaryScheduler.requestAuthorization { granted in
            weeklySummaryEnabled = granted
            notificationsDenied = !granted
        }
    }

    private func exportRecords() {
        AppHaptics.lightTap()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("忍了么记录-\(formatter.string(from: Date())).csv")
        do {
            try RecordInsights.csv(records: records, goals: goals).write(to: url, atomically: true, encoding: .utf8)
            exportFile = ExportFile(url: url)
        } catch {
            exportFailed = true
        }
    }
}

private struct Milestone: Identifiable {
    let title: String
    let symbol: String
    let isReached: Bool

    var id: String { title }
}

private struct ExportFile: Identifiable {
    let url: URL

    var id: URL { url }
}

/// The system share sheet, for saving or sending the exported file.
private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 回顾卡片

/// The day drawn as one soft line over a yellow wash, with a ring on its highest point.
private struct DayCurve: View {
    /// 24 values in 0...1, midnight first.
    let values: [Double]
    let peakHour: Int

    private static let topInset: CGFloat = 12
    private static let baseInset: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let points = points(in: size)
            let line = line(through: points)
            let peak = point(forHour: peakHour, in: size)
            let base = size.height - Self.baseInset

            ZStack {
                // The wash under the line.
                Path { path in
                    path.addPath(line)
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.closeSubpath()
                }
                .fill(Color.softBlockColor(for: .time))

                Path { path in
                    path.move(to: CGPoint(x: peak.x, y: peak.y))
                    path.addLine(to: CGPoint(x: peak.x, y: base))
                }
                .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 5]))

                line
                    .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(Color.white)
                    .overlay { Circle().stroke(Color.punchBlack, lineWidth: 3.5) }
                    .frame(width: 15, height: 15)
                    .position(peak)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func point(forHour hour: Int, in size: CGSize) -> CGPoint {
        let usable = size.height - Self.topInset - Self.baseInset
        return CGPoint(
            x: size.width * (CGFloat(hour) + 0.5) / 24,
            y: size.height - Self.baseInset - usable * CGFloat(values[hour])
        )
    }

    /// One point per hour, plus one at each edge so the line runs the full width.
    private func points(in size: CGSize) -> [CGPoint] {
        let hours = values.indices.map { point(forHour: $0, in: size) }
        guard let first = hours.first, let last = hours.last else { return [] }
        return [CGPoint(x: 0, y: first.y)] + hours + [CGPoint(x: size.width, y: last.y)]
    }

    private func line(through points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            // A Catmull-Rom spline: each stretch leans on the points either side of it, so the
            // line flows through every hour without flattening out at each one.
            for index in 0..<points.count - 1 {
                let previous = points[max(index - 1, 0)]
                let from = points[index]
                let to = points[index + 1]
                let next = points[min(index + 2, points.count - 1)]
                path.addCurve(
                    to: to,
                    control1: CGPoint(x: from.x + (to.x - previous.x) / 6, y: from.y + (to.y - previous.y) / 6),
                    control2: CGPoint(x: to.x - (next.x - from.x) / 6, y: to.y - (next.y - from.y) / 6)
                )
            }
        }
    }
}

// MARK: - 设置行

private struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .punchBlack.opacity(0.14), radius: 0, x: 0, y: 5)
    }
}

private struct SettingDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.punchBlack.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 62)
    }
}

private struct SettingRow<Accessory: View>: View {
    let symbol: String
    let tint: Color
    let title: String
    var subtitle: String?
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.punchBlack)
                .frame(width: 36, height: 36)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rounded(16, weight: .black))
                    .foregroundStyle(Color.ink)

                if let subtitle {
                    Text(subtitle)
                        .font(.rounded(12, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 8)

            accessory
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}

// MARK: - 冷静箱

private struct CooldownBoxView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @State private var cooldownAction: CooldownActionRequest?
    @State private var feedbackMoment: MascotMoment?

    private var pendingRecords: [ResistRecord] {
        records
            .filter { $0.status == .pending }
            .sorted { ($0.cooldownUntil ?? .distantFuture) < ($1.cooldownUntil ?? .distantFuture) }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    if pendingRecords.isEmpty {
                        PunchyCard(fill: .cardBackground) {
                            EmptyStateView(title: "冷静箱是空的", message: "", systemImage: "archivebox")
                        }
                    } else {
                        ForEach(pendingRecords) { record in
                            PunchyCard(fill: .cardBackground, cornerRadius: 28, padding: 14) {
                                PendingRecordRow(record: record, onRequest: { cooldownAction = $0 }) { moment in
                                    show(moment)
                                }
                            }
                        }
                    }
                }
.padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .appScrollDefaults()

            if let feedbackMoment {
                MascotFeedbackPopup(moment: feedbackMoment) {
                    self.feedbackMoment = nil
                }
            }
        }
        .navigationTitle("冷静箱")
        .navigationBarTitleDisplayMode(.inline)
        .cooldownActionSheet(request: $cooldownAction) { moment in
            show(moment)
        }
        .task(id: feedbackMoment) {
            guard feedbackMoment != nil else { return }
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                feedbackMoment = nil
            }
        }
    }

    private func show(_ moment: MascotMoment) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72)) {
            feedbackMoment = moment
        }
    }
}

// MARK: - 冷静时长

private struct CooldownLengthView: View {
    var onChange: () -> Void
    @State private var chosen: [ResistType: TimeInterval] = [:]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(ResistType.allCases) { type in
                        PunchyCard(fill: Color.softBlockColor(for: type), cornerRadius: 26, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    TypeMascotBadge(type: type, size: 44)
                                    Text(type.urgeTitle)
                                        .font(.rounded(20, weight: .black))
                                        .foregroundStyle(Color.ink)
                                }

                                HStack(spacing: 8) {
                                    ForEach(type.cooldownOptions, id: \.self) { seconds in
                                        let isSelected = (chosen[type] ?? type.cooldownSeconds) == seconds
                                        Button {
                                            AppHaptics.lightTap()
                                            UserDefaults.standard.set(seconds, forKey: AppSettings.cooldownKey(for: type))
                                            chosen[type] = seconds
                                            onChange()
                                        } label: {
                                            Text(AppSettings.durationText(seconds))
                                                .font(.rounded(14, weight: .black))
                                                .foregroundStyle(isSelected ? Color.white : .punchBlack)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.75)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 11)
                                                .background(isSelected ? Color.punchBlack : .softCream)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(PressableScaleStyle())
                                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                                    }
                                }
                            }
                        }
                    }

                    Text("只影响之后放进冷静箱的。")
                        .font(.rounded(13, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .padding(.leading, 4)
                }
.padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("冷静时长")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 关于

private struct AboutView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static var versionText: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private static let feedbackEmail = "xuzihao1218@126.com"
    private static let supportURL = URL(string: "https://renleme.netlify.app/support.html")

    /// Opens Mail with the address, a subject and the app version already filled in.
    private static var mailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "忍了么反馈"),
            URLQueryItem(name: "body", value: "\n\n——\n忍了么 \(versionText) · iOS \(UIDevice.current.systemVersion)")
        ]
        return components.url
    }
    private static let privacyURL = URL(string: "https://renleme.netlify.app/privacy.html")

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        AnimatedXiaoRenView(color: .punchGreen, expression: .hello, size: 110, reduceMotion: reduceMotion)

                        Text("忍了么")
                            .font(.rounded(30, weight: .black))
                            .foregroundStyle(Color.ink)

                        Text("版本 \(Self.versionText)")
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                    }
                    .padding(.vertical, 18)

                    SettingsGroup {
                        if let mailURL = Self.mailURL {
                            Link(destination: mailURL) {
                                SettingRow(symbol: "envelope.fill", tint: Color.softBlockColor(for: .food), title: "发邮件反馈", subtitle: Self.feedbackEmail) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.rounded(13, weight: .black))
                                        .foregroundStyle(Color.punchBlack)
                                }
                            }
                            .accessibilityIdentifier("emailFeedbackLink")

                            SettingDivider()
                        }

                        if let supportURL = Self.supportURL {
                            Link(destination: supportURL) {
                                SettingRow(symbol: "bubble.left.and.bubble.right.fill", tint: .punchYellow, title: "使用帮助与反馈") {
                                    Image(systemName: "arrow.up.right")
                                        .font(.rounded(13, weight: .black))
                                        .foregroundStyle(Color.punchBlack)
                                }
                            }
                        }

                        SettingDivider()

                        if let privacyURL = Self.privacyURL {
                            Link(destination: privacyURL) {
                                SettingRow(symbol: "hand.raised.fill", tint: Color.softBlockColor(for: .money), title: "隐私政策") {
                                    Image(systemName: "arrow.up.right")
                                        .font(.rounded(13, weight: .black))
                                        .foregroundStyle(Color.punchBlack)
                                }
                            }
                        }
                    }
                }
.padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DataPrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    privacyBlock(
                        icon: "iphone.gen3",
                        title: "数据保存在本机",
                        text: "记录、目标、自选图片和食物数据不会上传到服务器。删除 App 可能同时删除这些数据；可以在“我的”页导出一份记录。",
                        fill: .punchGreen
                    )
                    privacyBlock(
                        icon: "camera.fill",
                        title: "相机与相册",
                        text: "只在你主动为自选道具拍照或选图时使用。",
                        fill: .punchPink
                    )
                    privacyBlock(
                        icon: "bell.fill",
                        title: "通知",
                        text: "只用于冷静箱到期提醒和你主动打开的每周小结，都是本地通知，可随时关闭。",
                        fill: .punchYellow
                    )
                    privacyBlock(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "动作传感器",
                        text: "只用于让“今天”页底部的小忍随手机倾斜滑动，不保存也不上传。",
                        fill: .cream
                    )
                    privacyBlock(
                        icon: "hand.raised.fill",
                        title: "没有广告追踪",
                        text: "当前版本不需要账号，不读取支付账单或健康数据，也不使用广告追踪。",
                        fill: .cream
                    )
                }
.padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("数据与隐私")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
                    .font(.rounded(15, weight: .black))
            }
        }
    }

    private func privacyBlock(icon: String, title: String, text: String, fill: Color) -> some View {
        PunchyCard(fill: fill, cornerRadius: 26, padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.rounded(24, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.rounded(18, weight: .black))
                        .foregroundStyle(Color.ink)
                    Text(text)
                        .font(.rounded(14, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct PendingRecordRow: View {
    let record: ResistRecord
    let onRequest: (CooldownActionRequest) -> Void
    var onResolve: (MascotMoment) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RecordRow(record: record)
            CooldownStatusLabel(record: record)
            CooldownDecisionActions(record: record, onRequest: onRequest, onFeedback: onResolve)
        }
    }
}
