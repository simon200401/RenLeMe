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

/// Which goal of each kind the user has chosen to save towards first.
enum GoalFocus {
    /// Bumped on every change, so screens holding it in `@AppStorage` redraw.
    static let versionKey = "goalFocusVersion"

    private static func key(for type: ResistType) -> String {
        "focusGoalId.\(type.rawValue)"
    }

    static func stored() -> [ResistType: UUID] {
        var result: [ResistType: UUID] = [:]
        for type in ResistType.allCases {
            if let raw = UserDefaults.standard.string(forKey: key(for: type)), let id = UUID(uuidString: raw) {
                result[type] = id
            }
        }
        return result
    }

    static func set(_ goal: Goal) {
        UserDefaults.standard.set(goal.id.uuidString, forKey: key(for: goal.type))
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: versionKey) + 1, forKey: versionKey)
    }
}

/// How far along every goal is. Within one kind of urge goals fill one at a time: each resisted
/// record counts towards the goal it was put in, and whatever goes past that goal's target passes
/// on to the next one in line, so nothing is lost inside a goal that is already done.
struct GoalLedger {
    private var values: [UUID: Double] = [:]
    private var targets: [UUID: Double] = [:]
    private var focusIds: [ResistType: UUID] = [:]
    private var unfinishedCounts: [ResistType: Int] = [:]

    init(goals: [Goal], records: [ResistRecord], preferred: [ResistType: UUID] = GoalFocus.stored()) {
        for type in ResistType.allCases {
            let ofType = goals.filter { $0.type == type }
            guard !ofType.isEmpty else { continue }

            var filled: [UUID: Double] = [:]
            var spare = 0.0
            for goal in ofType {
                let own = StatsCalculator.currentValue(for: goal, records: records)
                filled[goal.id] = min(own, goal.targetValue)
                spare += max(own - goal.targetValue, 0)
                targets[goal.id] = goal.targetValue
            }

            // The line: the chosen goal first, then whichever is furthest along, then the oldest.
            let line = ofType.enumerated().sorted { lhs, rhs in
                let lhsChosen = lhs.element.id == preferred[type]
                let rhsChosen = rhs.element.id == preferred[type]
                if lhsChosen != rhsChosen { return lhsChosen }
                let lhsShare = (filled[lhs.element.id] ?? 0) / max(lhs.element.targetValue, 1)
                let rhsShare = (filled[rhs.element.id] ?? 0) / max(rhs.element.targetValue, 1)
                return lhsShare == rhsShare ? lhs.offset < rhs.offset : lhsShare > rhsShare
            }.map(\.element)

            for goal in line where spare > 0 {
                let room = goal.targetValue - (filled[goal.id] ?? 0)
                guard room > 0 else { continue }
                let passed = min(room, spare)
                filled[goal.id, default: 0] += passed
                spare -= passed
            }
            // Every goal of this kind is full: the rest stays visible on the first in line.
            if spare > 0, let first = line.first {
                filled[first.id, default: 0] += spare
            }

            let unfinished = line.filter { (filled[$0.id] ?? 0) < $0.targetValue }
            unfinishedCounts[type] = unfinished.count
            // With a single goal a record still lands on it once it is done, as it always has.
            focusIds[type] = unfinished.first?.id ?? (ofType.count == 1 ? ofType[0].id : nil)
            values.merge(filled) { _, new in new }
        }
    }

    func value(for goal: Goal) -> Double {
        values[goal.id] ?? 0
    }

    func progress(of goal: Goal) -> Double {
        value(for: goal) / max(goal.targetValue, 1)
    }

    func remaining(for goal: Goal) -> Double {
        max(goal.targetValue - value(for: goal), 0)
    }

    func isFinished(_ goal: Goal) -> Bool {
        progress(of: goal) >= 1
    }

    /// The goal new records of this kind go to.
    func focusId(for type: ResistType) -> UUID? {
        focusIds[type]
    }

    /// True for the goal being saved towards, when there is another one waiting behind it.
    func isFocus(_ goal: Goal) -> Bool {
        focusIds[goal.type] == goal.id && (unfinishedCounts[goal.type] ?? 0) > 1
    }

    /// Whether this goal could be moved to the front of the line.
    func canBecomeFocus(_ goal: Goal) -> Bool {
        !isFinished(goal) && focusIds[goal.type] != goal.id
    }
}

enum StatsCalculator {
    static func defaultGoalId(for type: ResistType, goals: [Goal]) -> UUID? {
        let matchingGoals = goals.filter { $0.type == type }
        return matchingGoals.count == 1 ? matchingGoals.first?.id : nil
    }

    /// The unfinished goal closest to completion, optionally limited to one type.
    static func nearestUnfinishedGoal(in goals: [Goal], records: [ResistRecord], type: ResistType? = nil) -> Goal? {
        let ledger = GoalLedger(goals: goals, records: records)
        return goals
            .filter { type == nil || $0.type == type }
            .map { ($0, ledger.progress(of: $0)) }
            .filter { $0.1 < 1 }
            .max { $0.1 < $1.1 }?
            .0
    }

    /// Where a new record lands unless the user picks otherwise: the goal being saved towards.
    static func suggestedGoalId(for type: ResistType, goals: [Goal], records: [ResistRecord]) -> UUID? {
        GoalLedger(goals: goals, records: records).focusId(for: type)
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

    /// What the records linked to this goal add up to, before any overflow is passed along.
    /// Screens show `GoalLedger` values instead.
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
            // Counted on the day of the decision, so something that waited overnight counts today.
            record.status == .resisted && calendar.isDateInToday(record.resolvedAt ?? record.createdAt)
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
