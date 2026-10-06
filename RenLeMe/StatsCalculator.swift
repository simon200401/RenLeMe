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

extension Calendar {
    /// The user's calendar with weeks running Monday to Sunday, which is how the app draws a week
    /// everywhere. Without this, regions that start the week on Sunday would count "this week"
    /// differently from the Mon–Sun row on screen.
    static var mondayFirst: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }
}

enum StatsCalculator {
    static func defaultGoalId(for type: ResistType, goals: [Goal]) -> UUID? {
        let matchingGoals = goals.filter { $0.type == type }
        return matchingGoals.count == 1 ? matchingGoals.first?.id : nil
    }

    /// The unfinished goal closest to completion, optionally limited to one type.
    static func nearestUnfinishedGoal(in goals: [Goal], records: [ResistRecord], type: ResistType? = nil) -> Goal? {
        goals
            .filter { type == nil || $0.type == type }
            .map { ($0, currentValue(for: $0, records: records) / max($0.targetValue, 1)) }
            .filter { $0.1 < 1 }
            .max { $0.1 < $1.1 }?
            .0
    }

    /// Where a new record lands unless the user picks otherwise: the only goal of its type, or the
    /// unfinished one closest to completion when there are several.
    static func suggestedGoalId(for type: ResistType, goals: [Goal], records: [ResistRecord]) -> UUID? {
        defaultGoalId(for: type, goals: goals)
            ?? nearestUnfinishedGoal(in: goals, records: records, type: type)?.id
    }

    static func assets(
        from records: [ResistRecord],
        period: AssetPeriod = .all,
        now: Date = .now,
        calendar: Calendar = .mondayFirst
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

    static func resistedToday(in records: [ResistRecord], calendar: Calendar = .mondayFirst) -> Int {
        records.filter { record in
            record.status == .resisted && calendar.isDateInToday(record.createdAt)
        }.count
    }

    static func resistedThisWeek(in records: [ResistRecord], calendar: Calendar = .mondayFirst) -> [ResistRecord] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return records.filter { record in
            record.status == .resisted && interval.contains(record.createdAt)
        }
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
