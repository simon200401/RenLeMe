import Foundation

/// Patterns worth a look on the "我的" page. Each one stays nil until there are enough records for
/// it to mean something, so a single entry never shows up as "100%".
struct RecordInsights {
    struct PeakTime {
        /// Urges per three-hour block, midnight first.
        let counts: [Int]
        /// The same blocks split by kind of urge.
        let typeCounts: [[ResistType: Int]]
        /// Urges per hour of the day, midnight first.
        let hourCounts: [Int]
        let peakIndex: Int

        /// The day as a gentle curve: hourly counts blurred into their neighbours, scaled so the
        /// highest point is 1. A handful of records would otherwise draw as isolated spikes.
        var curve: [Double] {
            var values = hourCounts.map(Double.init)
            for _ in 0..<6 {
                values = values.indices.map { hour in
                    let before = values[(hour + 23) % 24]
                    let after = values[(hour + 1) % 24]
                    return before * 0.25 + values[hour] * 0.5 + after * 0.25
                }
            }
            let highest = values.max() ?? 0
            return highest > 0 ? values.map { $0 / highest } : values
        }

        /// The hour where the curve tops out inside the peak block, so the marker and the title agree.
        var peakHour: Int {
            let curve = curve
            return (peakIndex * 3..<peakIndex * 3 + 3).max { curve[$0] < curve[$1] } ?? peakIndex * 3
        }

        var periodName: String {
            ["凌晨", "凌晨", "早上", "上午", "中午", "下午", "晚上", "夜里"][peakIndex]
        }

        var hourRange: String {
            ["0–3 点", "3–6 点", "6–9 点", "9–12 点", "12–3 点", "3–6 点", "6–9 点", "9–12 点"][peakIndex]
        }

        var peakTitle: String {
            "\(periodName) \(hourRange)"
        }
    }

    struct TypeRate: Identifiable {
        let type: ResistType
        let resisted: Int
        let decided: Int

        var id: String { type.rawValue }
        var rate: Double { decided > 0 ? Double(resisted) / Double(decided) : 0 }
    }

    struct CooldownEffect {
        let resisted: Int
        let decided: Int

        var rate: Double { Double(resisted) / Double(decided) }
    }

    static let peakTimeMinimum = 5
    static let typeRateMinimum = 3
    static let cooldownMinimum = 2

    /// Every urge counts here, whatever came of it.
    let urgeCount: Int
    /// Urges that ended one way or the other.
    let decidedCount: Int
    /// Decided urges that went through the cooldown box first.
    let cooledCount: Int

    struct TopItem {
        let title: String
        let count: Int
    }

    /// The thing wanted most often, once something has come up more than once.
    let topItem: TopItem?
    let peakTime: PeakTime?
    let typeRates: [TypeRate]?
    let cooldownEffect: CooldownEffect?

    init(records: [ResistRecord], calendar: Calendar = .current) {
        urgeCount = records.count
        let decided = records.filter { $0.status != .pending }
        decidedCount = decided.count
        let cooled = decided.filter(\.enteredCooldown)
        cooledCount = cooled.count

        let titleCounts = Dictionary(grouping: records, by: \.title).mapValues(\.count)
        // Ties go to the title that sorts first, so the answer does not flicker between launches.
        if let top = titleCounts.max(by: { ($0.value, $1.key) < ($1.value, $0.key) }), top.value >= 2 {
            topItem = TopItem(title: top.key, count: top.value)
        } else {
            topItem = nil
        }

        if records.count >= Self.peakTimeMinimum {
            var counts = Array(repeating: 0, count: 8)
            var typeCounts = Array(repeating: [ResistType: Int](), count: 8)
            var hourCounts = Array(repeating: 0, count: 24)
            for record in records {
                let hour = calendar.component(.hour, from: record.createdAt)
                let block = hour / 3
                hourCounts[hour] += 1
                counts[block] += 1
                typeCounts[block][record.type, default: 0] += 1
            }
            let peak = counts.indices.max { counts[$0] < counts[$1] } ?? 0
            peakTime = PeakTime(counts: counts, typeCounts: typeCounts, hourCounts: hourCounts, peakIndex: peak)
        } else {
            peakTime = nil
        }

        if decided.count >= Self.typeRateMinimum {
            typeRates = ResistType.allCases.map { type in
                let ofType = decided.filter { $0.type == type }
                return TypeRate(type: type, resisted: ofType.filter { $0.status == .resisted }.count, decided: ofType.count)
            }
        } else {
            typeRates = nil
        }

        if cooled.count >= Self.cooldownMinimum {
            cooldownEffect = CooldownEffect(resisted: cooled.filter { $0.status == .resisted }.count, decided: cooled.count)
        } else {
            cooldownEffect = nil
        }
    }

    /// Calendar days since the first record, counting that day. Never goes down.
    static func daysTogether(records: [ResistRecord], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard let first = records.map(\.createdAt).min() else { return 0 }
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: first), to: calendar.startOfDay(for: now)
        ).day ?? 0
        return max(days, 0) + 1
    }

    /// The whole history as a spreadsheet-friendly CSV, newest first.
    static func csv(records: [ResistRecord], goals: [Goal]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let goalTitles = Dictionary(goals.map { ($0.id, $0.title) }, uniquingKeysWith: { first, _ in first })

        func cell(_ text: String) -> String {
            "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }

        var lines = ["记录时间,类型,物品,结果,数值,单位,决定时间,投向目标,备注"]
        for record in records.sorted(by: { $0.createdAt > $1.createdAt }) {
            let unit: String = switch record.type {
            case .money: "元"
            case .food: "kcal"
            case .time: "分钟"
            }
            lines.append([
                cell(formatter.string(from: record.createdAt)),
                cell(record.type.title),
                cell(record.title),
                cell(record.status.title),
                record.hasEstimatedValue ? record.value.cleanString : "",
                unit,
                cell(record.resolvedAt.map(formatter.string(from:)) ?? ""),
                cell(record.goalId.flatMap { goalTitles[$0] } ?? ""),
                cell(record.note)
            ].joined(separator: ","))
        }
        // The byte-order mark makes Excel read the Chinese text correctly.
        return "\u{FEFF}" + lines.joined(separator: "\n") + "\n"
    }
}
