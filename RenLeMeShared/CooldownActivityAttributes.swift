import ActivityKit
import Foundation

enum CooldownLiveStatus: String, Codable, Hashable {
    case cooling
    case almostReady
    case ready
}

struct CooldownActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var typeRaw: String
        var status: CooldownLiveStatus
        var endsAt: Date
        var propIconKeyRaw: String?
    }

    var recordId: String
}
