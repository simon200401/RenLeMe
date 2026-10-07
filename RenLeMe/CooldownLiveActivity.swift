import ActivityKit
import Foundation
import SwiftData

/// The app's one database, shared by the screens and by whatever runs without them (a button on the
/// Live Activity can wake the app in the background).
enum AppStore {
    private static let schema = Schema([ResistRecord.self, Goal.self, FoodNutritionItem.self])

    /// Where the database has always been: the app's own Application Support folder.
    private static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }

    /// The location and the kind of store are spelled out, because left to its defaults SwiftData
    /// changes both behind the app's back as soon as the app gains certain entitlements: with an app
    /// group it moves the database into the group's folder (an update would open onto an empty app),
    /// and with iCloud it tries to sync through CloudKit, which these models are not built for.
    static let container: ModelContainer = {
        // On a brand-new install the folder does not exist yet.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        do {
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the database: \(error)")
        }
    }()

    private static let adoptedKey = "didAdoptGroupContainerStore"

    /// Builds made between the widget being added and the location being pinned kept their data in the
    /// app group's folder. Anything saved there is brought over once; the stray file is left alone.
    @MainActor
    static func adoptStrayStoreIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: adoptedKey) else { return }
        defer { UserDefaults.standard.set(true, forKey: adoptedKey) }

        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetShared.groupId)
        else { return }
        let strayURL = group.appending(path: "Library/Application Support/default.store")
        guard FileManager.default.fileExists(atPath: strayURL.path) else { return }

        let configuration = ModelConfiguration("stray", schema: schema, url: strayURL, allowsSave: false, cloudKitDatabase: .none)
        guard let stray = try? ModelContainer(for: schema, configurations: configuration),
              let records = try? stray.mainContext.fetch(FetchDescriptor<ResistRecord>()),
              let goals = try? stray.mainContext.fetch(FetchDescriptor<Goal>())
        else { return }

        let archive = BackupArchive(records: records, goals: goals, settings: .current(), deviceName: "")
        guard !archive.isEmpty else { return }
        _ = try? archive.merge(into: container.mainContext)
    }
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
