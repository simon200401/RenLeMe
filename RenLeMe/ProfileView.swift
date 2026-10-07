import SwiftData
import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @AppStorage(WeeklySummaryScheduler.enabledKey) private var weeklySummaryEnabled = false
    @AppStorage(AppSettings.cooldownReminderKey) private var cooldownReminderEnabled = true
    @AppStorage(AppSettings.liveActivityKey) private var liveActivityEnabled = true
    @ObservedObject private var cloudBackup = CloudBackup.shared
    @AppStorage(AppSettings.hapticsKey) private var hapticsEnabled = true
    @State private var isShowingGrowth = false
    @State private var isShowingDataPrivacy = false
    @State private var notificationsDenied = false
    @State private var exportFile: ExportFile?
    @State private var exportFailed = false
    @State private var heroFace: DynamicMascotExpression?
    /// Bumped when a cooldown length changes, so the settings row re-reads it.
    @State private var cooldownLengthToken = 0
    /// The hour under the finger while the day curve is being dragged across; nil shows the peak.
    @State private var scrubbedHour: Int?
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
                    AchievedShelfRow(goals: goals)

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
            // Dragging across the curve reads off any part of the day; letting go returns to the peak.
            let block = (scrubbedHour ?? peak.peakHour) / 3
            let count = peak.counts[block]

            PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scrubbedHour == nil ? "心动高峰" : "这个时段")
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(Color.secondaryInk)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(RecordInsights.PeakTime.periodName(forBlock: block))
                                .font(.rounded(32, weight: .black))
                                .foregroundStyle(Color.punchBlack)
                            Text(RecordInsights.PeakTime.hourRange(forBlock: block))
                                .font(.rounded(17, weight: .black))
                                .foregroundStyle(Color.secondaryInk)

                            Spacer(minLength: 8)

                            Text("\(count) 次")
                                .font(.rounded(22, weight: .black))
                                .foregroundStyle(Color.punchBlack)
                                .contentTransition(.numericText())
                        }
                        .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: block)
                    }

                    VStack(spacing: 8) {
                        DayCurve(values: peak.curve, markerHour: scrubbedHour ?? peak.peakHour, isScrubbing: scrubbedHour != nil)
                            .frame(height: 124)
                            .overlay {
                                HorizontalScrubber { fraction in
                                    let hour = fraction.map { min(max(Int($0 * 24), 0), 23) }
                                    if let hour, hour / 3 != (scrubbedHour ?? -3) / 3 {
                                        AppHaptics.lightTap()
                                    }
                                    scrubbedHour = hour
                                }
                            }

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
                    .accessibilityLabel("一天的起伏曲线，心动高峰在\(peak.peakTitle)，\(peak.counts[peak.peakIndex]) 次。左右滑动可以看其他时段")
                    .accessibilityAdjustableAction { direction in
                        let current = (scrubbedHour ?? peak.peakHour) / 3
                        let next = direction == .increment ? min(current + 1, 7) : max(current - 1, 0)
                        scrubbedHour = next * 3 + 1
                    }
                    .accessibilityValue("\(RecordInsights.PeakTime.periodName(forBlock: block)) \(RecordInsights.PeakTime.hourRange(forBlock: block))，\(count) 次")
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

            SettingRow(symbol: "timer", tint: Color.softBlockColor(for: .money), title: "锁屏和灵动岛倒计时", subtitle: "8 小时以内的冷静") {
                Toggle("锁屏和灵动岛倒计时", isOn: $liveActivityEnabled)
                    .labelsHidden()
                    .tint(Color.punchGreen)
                    .accessibilityIdentifier("liveActivityToggle")
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
            // The switch is here, on the page itself; what the backup holds and restoring are one step in.
            SettingRow(symbol: "icloud.fill", tint: Color.softBlockColor(for: .time), title: "iCloud 自动备份", subtitle: cloudBackup.statusText) {
                Toggle("iCloud 自动备份", isOn: Binding(
                    get: { cloudBackup.isEnabled },
                    set: { enabled in Task { await cloudBackup.setEnabled(enabled) } }
                ))
                .labelsHidden()
                .tint(Color.punchGreen)
                .accessibilityIdentifier("cloudBackupToggle")
            }

            SettingDivider()

            NavigationLink {
                CloudBackupView()
            } label: {
                SettingRow(symbol: "arrow.clockwise.icloud.fill", tint: Color.softBlockColor(for: .money), title: "备份与恢复") {
                    chevron
                }
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityIdentifier("cloudBackupRow")

            SettingDivider()

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 24 values in 0...1, midnight first.
    let values: [Double]
    /// Where the marker stands: the peak, or the hour under the finger.
    let markerHour: Int
    /// While a finger is on it the line runs the full height, so it shows even where the curve is flat.
    var isScrubbing = false

    private static let topInset: CGFloat = 12
    private static let baseInset: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let points = points(in: size)
            let line = line(through: points)
            let peak = point(forHour: markerHour, in: size)
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

                // A view rather than a path, so it glides with the marker instead of jumping.
                VerticalDash()
                    .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 5]))
                    .frame(width: 2, height: max(base - lineTop(above: peak), 0))
                    .position(x: peak.x, y: (lineTop(above: peak) + base) / 2)

                line
                    .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(Color.white)
                    .overlay { Circle().stroke(Color.punchBlack, lineWidth: 3.5) }
                    .frame(width: 15, height: 15)
                    .position(peak)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: markerHour)
            .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: isScrubbing)
        }
    }

    private func lineTop(above marker: CGPoint) -> CGFloat {
        isScrubbing ? 0 : marker.y
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

private struct VerticalDash: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

/// Reports where a finger is across its width, 0 to 1, and nil shortly after it lifts. It only takes
/// over when the finger moves sideways, so dragging up or down across it still scrolls the page; a
/// tap counts too.
private struct HorizontalScrubber: UIViewRepresentable {
    var onChange: (CGFloat?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:))))
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onChange = onChange
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChange: (CGFloat?) -> Void
        private var release: DispatchWorkItem?

        init(onChange: @escaping (CGFloat?) -> Void) {
            self.onChange = onChange
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            report(pan)
            if pan.state == .ended || pan.state == .cancelled || pan.state == .failed {
                letGo(after: 1.2)
            }
        }

        @objc func handleTap(_ tap: UITapGestureRecognizer) {
            report(tap)
            letGo(after: 2)
        }

        private func report(_ recognizer: UIGestureRecognizer) {
            guard let view = recognizer.view, view.bounds.width > 0 else { return }
            release?.cancel()
            onChange(min(max(recognizer.location(in: view).x / view.bounds.width, 0), 1))
        }

        /// The reading lingers for a moment after the finger lifts, then the card goes back to the peak.
        private func letGo(after delay: TimeInterval) {
            release?.cancel()
            let item = DispatchWorkItem { [weak self] in self?.onChange(nil) }
            release = item
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
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

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(ResistType.allCases) { type in
                        CooldownLengthCard(type: type, onChange: onChange)
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
        .appKeyboardDismissal()
    }
}

/// One kind of urge: four ready-made lengths, or any length typed in by hand.
private struct CooldownLengthCard: View {
    private enum Unit: String, CaseIterable, Identifiable {
        case minute = "分钟"
        case hour = "小时"
        case day = "天"

        var id: String { rawValue }

        var seconds: TimeInterval {
            switch self {
            case .minute: 60
            case .hour: 60 * 60
            case .day: 24 * 60 * 60
            }
        }
    }

    let type: ResistType
    var onChange: () -> Void

    @State private var seconds: TimeInterval
    @State private var isCustom: Bool
    @State private var amountText: String
    @State private var unit: Unit
    @FocusState private var isAmountFocused: Bool

    init(type: ResistType, onChange: @escaping () -> Void) {
        self.type = type
        self.onChange = onChange
        let current = type.cooldownSeconds
        // Shown in the largest unit that divides it evenly.
        let unit = Unit.allCases.last { current.truncatingRemainder(dividingBy: $0.seconds) == 0 } ?? .minute
        _seconds = State(initialValue: current)
        _isCustom = State(initialValue: !type.cooldownOptions.contains(current))
        _unit = State(initialValue: unit)
        _amountText = State(initialValue: (current / unit.seconds).cleanString)
    }

    /// The typed length in seconds, when it is a whole number inside the allowed range.
    private var typedSeconds: TimeInterval? {
        guard let amount = Double(amountText), amount > 0, amount == amount.rounded() else { return nil }
        let value = amount * unit.seconds
        return AppSettings.cooldownRange.contains(value) ? value : nil
    }

    var body: some View {
        PunchyCard(fill: Color.softBlockColor(for: type), cornerRadius: 26, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    TypeMascotBadge(type: type, size: 44)
                    Text(type.urgeTitle)
                        .font(.rounded(20, weight: .black))
                        .foregroundStyle(Color.ink)

                    Spacer()

                    Text(AppSettings.durationText(seconds))
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 8) {
                    ForEach(type.cooldownOptions, id: \.self) { option in
                        chip(AppSettings.durationText(option), isSelected: !isCustom && seconds == option) {
                            isAmountFocused = false
                            isCustom = false
                            apply(option)
                        }
                    }

                    chip("自定义", isSelected: isCustom) {
                        isCustom = true
                        isAmountFocused = true
                    }
                }

                if isCustom {
                    HStack(spacing: 8) {
                        AppTextField(placeholder: "数字", text: $amountText, keyboardType: .numberPad, focus: $isAmountFocused)
                            .frame(width: 96)
                            .background(Color.softCream)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        Picker("单位", selection: $unit) {
                            ForEach(Unit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if typedSeconds == nil {
                        Text("填 1 分钟到 30 天之间的整数")
                            .font(.rounded(12, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                    }
                }
            }
        }
        .onChange(of: amountText) { _, _ in applyTyped() }
        .onChange(of: unit) { _, _ in applyTyped() }
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            AppHaptics.lightTap()
            action()
        } label: {
            Text(title)
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

    /// A typed value takes effect as soon as it is valid; an invalid one leaves the last length in place.
    private func applyTyped() {
        guard isCustom, let typedSeconds else { return }
        apply(typedSeconds)
    }

    private func apply(_ value: TimeInterval) {
        seconds = value
        UserDefaults.standard.set(value, forKey: AppSettings.cooldownKey(for: type))
        onChange()
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
                        title: "数据在本机和你的 iCloud",
                        text: "记录、目标和自选图片保存在这台手机上。打开“iCloud 自动备份”时，会另存一份到你自己的 iCloud，用来在重装或换手机后恢复；这份备份我们看不到，可以在“我的”页随时关掉。我们没有服务器，不收集这些数据。",
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
