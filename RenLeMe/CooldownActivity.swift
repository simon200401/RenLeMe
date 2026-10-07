import ActivityKit
import AppIntents
import Foundation

// Compiled into both the app and the widget extension: the app starts and ends the Live Activity, the
// extension draws it, and the buttons on it are an intent both must know.

/// One thing waiting in the cooldown box, as shown on the Lock Screen and in the Dynamic Island.
struct CooldownActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var until: Date
    }

    var recordId: UUID
    var title: String
    /// `ResistType` raw value.
    var type: String
}

/// What a button on the Live Activity does. The system runs it in the app's process, starting the app
/// in the background if need be, so the app fills this in at launch; in the extension it stays empty.
enum CooldownDecisionHook {
    @MainActor static var resolve: ((UUID, Bool) async -> Void)?
}

/// "我忍住了" / "我还是做了", decided without opening the app.
struct CooldownDecisionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "决定冷静箱里的东西"
    static var isDiscoverable = false

    @Parameter(title: "记录")
    var recordId: String

    @Parameter(title: "忍住了")
    var resisted: Bool

    init() {}

    init(recordId: UUID, resisted: Bool) {
        self.recordId = recordId.uuidString
        self.resisted = resisted
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: recordId) {
            await CooldownDecisionHook.resolve?(id, resisted)
        }
        return .result()
    }
}
