import ActivityKit
import Foundation
import SwiftData

/// The app's one database, shared by the screens and by whatever runs without them (a button on the
/// Live Activity can wake the app in the background).
enum AppStore {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: ResistRecord.self, Goal.self, FoodNutritionItem.self)
        } catch {
            fatalError("Could not open the database: \(error)")
        }
    }()
}

/// Keeps a Live Activity going for the most recent short cooldown: 小忍 and a countdown in the Dynamic
/// Island, and the two decisions one long-press away.
@MainActor
enum CooldownLiveActivity {
    /// The system ends a Live Activity after eight hours, so longer cooldowns do not get one.
    static let longestCooldown: TimeInterval = 8 * 60 * 60

    private static var isAllowed: Bool {
        AppSettings.liveActivityEnabled && ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Called at launch, including a background launch by one of the buttons.
    static func install() {
        CooldownDecisionHook.resolve = { recordId, resisted in
            await decide(recordId: recordId, resisted: resisted)
        }
    }

    /// Brings what is on screen in line with the cooldown box. Starting one only works while the app
    /// is in front, which is when this is called.
    static func reconcile(with records: [ResistRecord], now: Date = .now) async {
        let pending = Dictionary(
            records.filter { $0.status == .pending }.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // The one to show: the most recently added that will be over within the limit.
        let wanted = isAllowed
            ? pending.values
                .filter { record in
                    guard let until = record.cooldownUntil else { return false }
                    return until > now && until.timeIntervalSince(now) <= longestCooldown
                }
                .max { $0.createdAt < $1.createdAt }
            : nil

        var isShowingWanted = false
        for activity in Activity<CooldownActivityAttributes>.activities {
            let record = pending[activity.attributes.recordId]
            // One that has run out stays up, asking, until it is decided or something newer takes over.
            let keeps = isAllowed && record != nil
                && (record?.id == wanted?.id || (wanted == nil && (record?.cooldownUntil ?? .distantFuture) <= now))
            guard keeps, let record, let until = record.cooldownUntil else {
                await activity.end(nil, dismissalPolicy: .immediate)
                continue
            }
            if record.id == wanted?.id { isShowingWanted = true }
            if activity.content.state.until != until {
                await activity.update(ActivityContent(state: .init(until: until), staleDate: until))
            }
        }

        if let wanted, !isShowingWanted, let until = wanted.cooldownUntil {
            let attributes = CooldownActivityAttributes(recordId: wanted.id, title: wanted.title, type: wanted.type.rawValue)
            _ = try? Activity.request(
                attributes: attributes,
                content: ActivityContent(state: .init(until: until), staleDate: until)
            )
        }
    }

    private static func decide(recordId: UUID, resisted: Bool) async {
        let context = AppStore.container.mainContext
        let all = (try? context.fetch(FetchDescriptor<ResistRecord>())) ?? []
        if let record = all.first(where: { $0.id == recordId }), record.status == .pending {
            CooldownCoordinator.resolve(record, as: resisted ? .resisted : .gaveIn)
            try? context.save()
        }
        for activity in Activity<CooldownActivityAttributes>.activities where activity.attributes.recordId == recordId {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        WidgetBridge.publish(WidgetBridge.snapshot(from: all))
    }
}
