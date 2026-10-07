import Foundation
import WidgetKit

/// Keeps the widgets' copy of the facts up to date.
enum WidgetBridge {
    private static let pendingLimit = 4

    static func snapshot(from records: [ResistRecord], now: Date = .now) -> WidgetSnapshot {
        let pending = records
            .filter { $0.status == .pending }
            .compactMap { record -> WidgetSnapshot.Pending? in
                guard let until = record.cooldownUntil else { return nil }
                // A photo of the user's own stays in the app; the widget falls back to the kind's picture.
                let templateId = record.customImagePath == nil ? PropTemplate.matching(record: record)?.id : nil
                return .init(id: record.id, title: record.title, type: record.type.rawValue, templateId: templateId, until: until)
            }
            .sorted { $0.until < $1.until }

        return WidgetSnapshot(
            day: Calendar.current.startOfDay(for: now),
            todayCount: StatsCalculator.resistedToday(in: records),
            pending: Array(pending.prefix(pendingLimit))
        )
    }

    /// Writes only when something the widgets show has changed, since reloading them is rationed.
    static func publish(_ snapshot: WidgetSnapshot) {
        guard snapshot != WidgetSnapshot.load() else { return }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
