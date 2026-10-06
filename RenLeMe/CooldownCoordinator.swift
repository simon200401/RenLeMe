import Foundation
import UserNotifications

enum CooldownCoordinator {
    static func schedule(for record: ResistRecord) {
        guard record.status == .pending, let cooldownUntil = record.cooldownUntil else { return }

        let recordId = record.id
        let identifier = recordId.uuidString
        let title = record.title
        cancelNotification(recordId: recordId)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "现在再决定"
            content.body = "「\(title)」已经冷静了一会儿。"
            content.sound = .default
            content.userInfo = ["recordId": identifier]

            let interval = max(cooldownUntil.timeIntervalSinceNow, 1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    @MainActor
    static func extend(_ record: ResistRecord, by interval: TimeInterval) {
        record.status = .pending
        record.resolvedAt = nil
        record.cooldownUntil = Date().addingTimeInterval(interval)
        record.enteredCooldown = true
        schedule(for: record)
    }

    @MainActor
    static func resolve(_ record: ResistRecord, as status: ResistStatus, estimatedValue: Double? = nil) {
        guard status != .pending else { return }

        if let estimatedValue, estimatedValue > 0 {
            record.value = estimatedValue
            record.hasEstimatedValue = true
        }
        record.status = status
        record.resolvedAt = .now
        record.cooldownUntil = nil
        cancel(recordId: record.id)
    }

    static func cancel(recordId: UUID) {
        cancelNotification(recordId: recordId)
    }

    private static func cancelNotification(recordId: UUID) {
        let identifier = recordId.uuidString
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
