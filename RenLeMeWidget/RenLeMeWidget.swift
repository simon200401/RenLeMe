import AppIntents
import SwiftUI
import WidgetKit

// The widgets show what the app last wrote down (see `WidgetSnapshot`) and never open the database.
// 小忍 and the item pictures are images rendered from the app's own drawings (Assets.xcassets here);
// a widget cannot run the app's animation, so it only changes face with the state and the hour.

@main
struct RenLeMeWidgets: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        PauseEntryWidget()
        CooldownWidget()
        CooldownActivityWidget()
    }
}

// MARK: - Timeline

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot

    /// 23:00 to 06:00.
    var isNight: Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 23 || hour < 6
    }

    var todayCount: Int {
        snapshot.count(on: date)
    }

    /// The thing to show from the cooldown box: one that is already due first, else the soonest.
    var pending: WidgetSnapshot.Pending? {
        snapshot.pending.first { $0.until <= date } ?? snapshot.pending.first
    }

    static let sample = SnapshotEntry(date: .now, snapshot: WidgetSnapshot(day: Calendar.current.startOfDay(for: .now), todayCount: 3, pending: []))
}

/// One entry for now and one for every moment the picture should change without the app's help:
/// each cooldown running out, midnight, and the two ends of the night.
enum SnapshotTimeline {
    static func entries(now: Date = .now) -> [SnapshotEntry] {
        let snapshot = WidgetSnapshot.load()
        let calendar = Calendar.current
        var dates: Set<Date> = [now]

        for item in snapshot.pending where item.until > now {
            dates.insert(item.until)
        }
        for hour in [0, 6, 23] {
            if let next = calendar.nextDate(after: now, matching: DateComponents(hour: hour, minute: 0), matchingPolicy: .nextTime) {
                dates.insert(next)
            }
        }
        return dates.sorted().map { SnapshotEntry(date: $0, snapshot: snapshot) }
    }
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(context.isPreview ? .sample : SnapshotEntry(date: .now, snapshot: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        completion(Timeline(entries: SnapshotTimeline.entries(), policy: .atEnd))
    }
}

// MARK: - Look

enum WidgetPalette {
    static let paper = Color(red: 0.984, green: 0.973, blue: 0.925)
    static let night = Color(red: 0.16, green: 0.17, blue: 0.24)
    static let ink = Color(red: 0.025, green: 0.025, blue: 0.035)
    static let secondaryInk = Color(red: 0.29, green: 0.29, blue: 0.34)

    static func soft(_ type: String) -> Color {
        switch type {
        case "food": Color(red: 1.0, green: 0.855, blue: 0.929)
        case "time": Color(red: 1.0, green: 0.925, blue: 0.245)
        default: Color(red: 0.816, green: 0.957, blue: 0.859)
        }
    }
}

private extension Font {
    static func rounded(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
}

private extension WidgetSnapshot.Pending {
    /// The item's own picture if the widget has one, else the picture for its kind.
    var imageName: String {
        if let templateId {
            let name = "prop_" + templateId.replacingOccurrences(of: ".", with: "_")
            if UIImage(named: name) != nil { return name }
        }
        return "type_\(type)"
    }
}

private struct Mascot: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Image("mascot_\(name)")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Counts down by itself; once the time is up it says so instead of showing zeros.
private struct CooldownText: View {
    let item: WidgetSnapshot.Pending
    let now: Date

    var body: some View {
        if item.until > now {
            Text(timerInterval: now...item.until, countsDown: true)
                .monospacedDigit()
        } else {
            Text("到时间了")
        }
    }
}

// MARK: - Home screen: today

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: SnapshotProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("今天")
        .description("今天忍住了几次；冷静箱里有东西时显示倒计时。中号可以一键忍一下。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        switch family {
        case .systemMedium:
            medium
                .containerBackground(entry.isNight ? WidgetPalette.night : WidgetPalette.paper, for: .widget)
        default:
            if let item = entry.pending {
                smallCooldown(item)
                    .containerBackground(WidgetPalette.soft(item.type), for: .widget)
                    .widgetURL(WidgetShared.cooldownURL(item.id))
            } else {
                smallToday
                    .containerBackground(entry.isNight ? WidgetPalette.night : WidgetPalette.paper, for: .widget)
                    .widgetURL(WidgetShared.homeURL)
            }
        }
    }

    private var primary: Color { entry.isNight ? .white : WidgetPalette.ink }
    private var secondary: Color { entry.isNight ? .white.opacity(0.6) : WidgetPalette.secondaryInk }

    private var face: String {
        if entry.isNight { return "asleep" }
        return entry.todayCount > 0 ? "proud" : "hello"
    }

    /// The number in one corner, 小忍 in the other.
    private var smallToday: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today")
                .font(.rounded(14))
                .foregroundStyle(secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.todayCount)")
                    .font(.rounded(58))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text("次")
                    .font(.rounded(17))
            }
            .foregroundStyle(primary)

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)
                Mascot(name: face, size: 66)
            }
        }
        .padding(14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今天忍住 \(entry.todayCount) 次")
    }

    private func smallCooldown(_ item: WidgetSnapshot.Pending) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                Spacer(minLength: 0)
                Mascot(name: "cooling", size: 50)
            }

            Spacer(minLength: 0)

            Text(item.title)
                .font(.rounded(17))
                .lineLimit(1)
            CooldownText(item: item, now: entry.date)
                .font(.rounded(26))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(item.until > entry.date ? "冷静中" : "去做决定")
                .font(.rounded(12))
                .foregroundStyle(WidgetPalette.secondaryInk)
        }
        .foregroundStyle(WidgetPalette.ink)
        .padding(14)
    }

    /// 小忍 and the count on the left; the three ways into a pause on the right.
    private var medium: some View {
        HStack(spacing: 12) {
            Link(destination: WidgetShared.homeURL) {
                VStack(spacing: 6) {
                    Mascot(name: face, size: 70)
                    Text("Today: \(entry.todayCount) 次")
                        .font(.rounded(14))
                        .foregroundStyle(primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: 104)
                .frame(maxHeight: .infinity)
            }

            HStack(spacing: 8) {
                ForEach([UrgeKind.money, .food, .time], id: \.rawValue) { kind in
                    Link(destination: WidgetShared.pauseURL(kind.rawValue)) {
                        VStack(spacing: 6) {
                            Image("badge_\(kind.rawValue)")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                            Text(kind.title)
                                .font(.rounded(13))
                                .foregroundStyle(WidgetPalette.ink)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(WidgetPalette.soft(kind.rawValue))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Lock screen: one tap into a pause

struct PauseEntryConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "忍一下"
    static var description = IntentDescription("点一下直接进入暂停。")

    @Parameter(title: "哪一类", default: .money)
    var kind: UrgeKind
}

struct PauseEntry: TimelineEntry {
    let date: Date
    let kind: UrgeKind
}

struct PauseEntryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PauseEntry {
        PauseEntry(date: .now, kind: .money)
    }

    func snapshot(for configuration: PauseEntryConfiguration, in context: Context) async -> PauseEntry {
        PauseEntry(date: .now, kind: configuration.kind)
    }

    func timeline(for configuration: PauseEntryConfiguration, in context: Context) async -> Timeline<PauseEntry> {
        Timeline(entries: [PauseEntry(date: .now, kind: configuration.kind)], policy: .never)
    }
}

struct PauseEntryWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "PauseEntryWidget", intent: PauseEntryConfiguration.self, provider: PauseEntryProvider()) { entry in
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18, weight: .black))
                    Text(entry.kind.title)
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .containerBackground(.clear, for: .widget)
            .widgetURL(WidgetShared.pauseURL(entry.kind.rawValue))
            .accessibilityLabel("忍一下，\(entry.kind.title)")
        }
        .configurationDisplayName("忍一下")
        .description("锁屏上一键进入暂停。长按可以选想买、想吃或想玩。")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Lock screen: the cooldown box

struct CooldownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CooldownWidget", provider: SnapshotProvider()) { entry in
            CooldownWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("冷静箱")
        .description("最近一件在冷静的东西还要等多久。")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct CooldownWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        if let item = entry.pending {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                    Text(item.title)
                        .lineLimit(1)
                }
                .font(.system(size: 13, weight: .bold))

                CooldownText(item: item, now: entry.date)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetURL(WidgetShared.cooldownURL(item.id))
        } else {
            VStack(alignment: .leading, spacing: 1) {
                Text("忍了么")
                    .font(.system(size: 13, weight: .bold))
                Text("Today: \(entry.todayCount) 次")
                    .font(.system(size: 20, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetURL(WidgetShared.homeURL)
        }
    }
}
