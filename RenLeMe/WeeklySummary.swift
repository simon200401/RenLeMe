import Foundation
import UserNotifications

extension Notification.Name {
    static let openWeeklySummary = Notification.Name("renleme.openWeeklySummary")
}

/// What the end-of-week notification will say. Equatable so the root view only reschedules when it changes.
struct WeeklySummaryContent: Equatable {
    var resistedCount: Int
    var assetsText: String
    var goalText: String?

    init(records: [ResistRecord], goals: [Goal], now: Date = .now, calendar: Calendar = .mondayFirst) {
        let interval = calendar.dateInterval(of: .weekOfYear, for: now)
        resistedCount = records.filter { record in
            guard record.status == .resisted, let interval else { return false }
            return interval.contains(record.resolvedAt ?? record.createdAt)
        }.count

        let assets = StatsCalculator.assets(from: records, period: .week, now: now, calendar: calendar)
        assetsText = [
            assets.money > 0 ? assets.money.moneyString : nil,
            assets.calories > 0 ? assets.calories.calorieString : nil,
            assets.minutes > 0 ? assets.minutes.displayValue(for: .time) : nil
        ]
        .compactMap { $0 }
        .joined(separator: " · ")

        if let goal = StatsCalculator.nearestUnfinishedGoal(in: goals, records: records) {
            let remaining = goal.targetValue - StatsCalculator.currentValue(for: goal, records: records)
            goalText = "「\(goal.title)」还差 \(remaining.displayValue(for: goal.type))"
        } else {
            goalText = nil
        }
    }

    var body: String {
        var parts = ["忍住 \(resistedCount) 次"]
        if !assetsText.isEmpty { parts.append(assetsText) }
        if let goalText { parts.append(goalText) }
        return parts.joined(separator: "，")
    }
}

enum WeeklySummaryScheduler {
    static let enabledKey = "weeklySummaryEnabled"
    private static let identifier = "renleme.weeklySummary"
    private static let deliveryHour = 20

    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Replaces the pending summary for the current week. Nothing is sent for a week without a resisted
    /// record, so the notification never turns into a nudge.
    static func reschedule(with content: WeeklySummaryContent, now: Date = .now, calendar: Calendar = .mondayFirst) {
        cancel()
        guard UserDefaults.standard.bool(forKey: enabledKey), content.resistedCount > 0,
              let fireDate = deliveryDate(now: now, calendar: calendar), fireDate > now
        else { return }

        let notification = UNMutableNotificationContent()
        notification.title = "本周小结"
        notification.body = content.body
        notification.sound = .default
        notification.userInfo = ["route": "results"]

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: identifier, content: notification, trigger: trigger)
        )
    }

    /// 20:00 on the last day of the current week.
    static func deliveryDate(now: Date, calendar: Calendar) -> Date? {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: week.end)
        else { return nil }
        return calendar.date(bySettingHour: deliveryHour, minute: 0, second: 0, of: lastDay)
    }
}
