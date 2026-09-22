import Foundation

struct AssetSummary {
    var money: Double
    var calories: Double
    var minutes: Double

    static let empty = AssetSummary(money: 0, calories: 0, minutes: 0)
}

enum AssetPeriod: String, CaseIterable, Identifiable {
    case week, month, all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "本周"
        case .month: "本月"
        case .all: "全部"
        }
    }

    func interval(at date: Date, calendar: Calendar) -> DateInterval? {
        switch self {
        case .week: calendar.dateInterval(of: .weekOfYear, for: date)
        case .month: calendar.dateInterval(of: .month, for: date)
        case .all: nil
        }
    }
}

enum StatsCalculator {
    static func assets(
        from records: [ResistRecord],
        period: AssetPeriod = .all,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> AssetSummary {
        let interval = period.interval(at: now, calendar: calendar)
        return records.reduce(into: .empty) { result, record in
            guard record.status == .resisted, record.hasEstimatedValue else { return }
            // Assets accrue when a decision is made; older records may only have a creation date.
            let earnedAt = record.resolvedAt ?? record.createdAt
            if let interval {
                guard earnedAt >= interval.start, earnedAt < interval.end else { return }
            }

            switch record.type {
            case .money:
                result.money += record.value
            case .food:
                result.calories += record.value
            case .time:
                result.minutes += record.value
            }
        }
    }

    static func currentValue(for goal: Goal, records: [ResistRecord]) -> Double {
        records.reduce(0) { partial, record in
            guard record.status == .resisted,
                  record.hasEstimatedValue,
                  record.type == goal.type,
                  record.goalId == goal.id
            else { return partial }

            return partial + record.value
        }
    }

    static func totalValue(for type: ResistType, records: [ResistRecord]) -> Double {
        records.reduce(0) { partial, record in
            guard record.status == .resisted, record.hasEstimatedValue, record.type == type else { return partial }
            return partial + record.value
        }
    }

    static func resistedToday(in records: [ResistRecord], calendar: Calendar = .current) -> Int {
        records.filter { record in
            record.status == .resisted && calendar.isDateInToday(record.createdAt)
        }.count
    }

    static func resistedThisWeek(in records: [ResistRecord], calendar: Calendar = .current) -> [ResistRecord] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return records.filter { record in
            record.status == .resisted && interval.contains(record.createdAt)
        }
    }

    static func resistedThisMonth(in records: [ResistRecord], calendar: Calendar = .current) -> [ResistRecord] {
        guard let interval = calendar.dateInterval(of: .month, for: .now) else { return [] }
        return records.filter { record in
            record.status == .resisted && interval.contains(record.createdAt)
        }
    }

    static func mostCommonReason(in records: [ResistRecord]) -> String? {
        let reasons = records.map(\.reason).filter { !$0.isEmpty }
        return Dictionary(grouping: reasons, by: { $0 })
            .max { $0.value.count < $1.value.count }?
            .key
    }

    static func dailyResistedCounts(in records: [ResistRecord], days: Int = 7, calendar: Calendar = .current) -> [Int] {
        let today = calendar.startOfDay(for: .now)
        return (0..<days).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            return records.filter { record in
                record.status == .resisted && calendar.isDate(record.createdAt, inSameDayAs: date)
            }.count
        }
    }

    static func currentRecordStreak(in records: [ResistRecord], calendar: Calendar = .current) -> Int {
        let recordedDays = Set(records.map { calendar.startOfDay(for: $0.createdAt) })
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        while recordedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    static func mostFrequentResistedTypeThisWeek(in records: [ResistRecord], calendar: Calendar = .current) -> ResistType? {
        let weekRecords = resistedThisWeek(in: records, calendar: calendar)
        guard !weekRecords.isEmpty else { return nil }

        let counts = ResistType.allCases.map { type in
            (type, weekRecords.filter { $0.type == type }.count)
        }
        guard let highestCount = counts.map(\.1).max(), highestCount > 0 else {
            return nil
        }

        let leaders = counts.filter { $0.1 == highestCount }
        return leaders.count == 1 ? leaders[0].0 : nil
    }
}

extension Double {
    var cleanString: String {
        if rounded() == self {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
    }

    var moneyString: String {
        "¥\(Int(self.rounded()))"
    }

    var calorieString: String {
        "\(Int(self.rounded())) kcal"
    }

    var hourString: String {
        let hours = self / 60
        return "\(hours.cleanString) h"
    }

    func displayValue(for type: ResistType) -> String {
        switch type {
        case .money: return moneyString
        case .food: return calorieString
        case .time:
            if self >= 60 { return hourString }
            return "\(Int(self.rounded())) min"
        }
    }
}

extension Date {
    var shortTimeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDateInToday(self) ? "HH:mm" : "M月d日"
        return formatter.string(from: self)
    }
}
