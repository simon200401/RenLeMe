import AppIntents
import Foundation

/// What the app and its widgets agree on. This file is compiled into both.
enum WidgetShared {
    /// The app group both sides read and write. It has to be switched on for both targets under
    /// Signing & Capabilities; without it the widgets run but have nothing to show.
    static let groupId = "group.com.simonx.renleme"
    static let snapshotKey = "widgetSnapshot"
    static let urlScheme = "renleme"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: groupId)
    }

    static func pauseURL(_ kind: String) -> URL {
        URL(string: "\(urlScheme)://pause/\(kind)")!
    }

    static func cooldownURL(_ id: UUID) -> URL {
        URL(string: "\(urlScheme)://cooldown/\(id.uuidString)")!
    }

    static let homeURL = URL(string: "\(urlScheme)://home")!
}

/// The little the widgets need, written by the app whenever it changes. The widgets never open the
/// database themselves.
struct WidgetSnapshot: Codable, Equatable {
    struct Pending: Codable, Equatable, Identifiable {
        var id: UUID
        var title: String
        /// `ResistType` raw value.
        var type: String
        /// Built-in item id, when the record has one, for its picture.
        var templateId: String?
        var until: Date
    }

    /// The day `todayCount` belongs to; on any other day the widgets show zero.
    var day: Date
    var todayCount: Int
    /// Soonest first.
    var pending: [Pending]

    static let empty = WidgetSnapshot(day: .distantPast, todayCount: 0, pending: [])

    static func load() -> WidgetSnapshot {
        guard let data = WidgetShared.defaults?.data(forKey: WidgetShared.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        WidgetShared.defaults?.set(data, forKey: WidgetShared.snapshotKey)
    }

    func count(on date: Date, calendar: Calendar = .current) -> Int {
        calendar.isDate(date, inSameDayAs: day) ? todayCount : 0
    }
}

/// The three kinds of urge, as Siri, Shortcuts and widget settings name them.
enum UrgeKind: String, AppEnum {
    case money
    case food
    case time

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "哪一类"

    static var caseDisplayRepresentations: [UrgeKind: DisplayRepresentation] = [
        .money: "想买",
        .food: "想吃",
        .time: "想玩"
    ]

    var title: String {
        switch self {
        case .money: "想买"
        case .food: "想吃"
        case .time: "想玩"
        }
    }
}
