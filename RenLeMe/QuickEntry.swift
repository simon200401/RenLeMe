import AppIntents
import SwiftUI
import UIKit

extension Notification.Name {
    static let openPause = Notification.Name("renleme.openPause")
    static let openHome = Notification.Name("renleme.openHome")
}

/// Ways into a pause from outside the app — the home-screen icon's menu, Siri, Spotlight, the Action
/// button, a link — so the moment an urge hits is not spent finding the right screen. They all end
/// in the same place: which kind of urge, handed to the root view.
enum QuickEntry {
    private static let pendingKey = "renleme.pendingPauseType"
    private static let shortcutPrefix = "com.simonx.renleme.pause."

    /// Kept until the root view picks it up, so it survives the app still starting.
    static func open(_ type: ResistType) {
        UserDefaults.standard.set(type.rawValue, forKey: pendingKey)
        NotificationCenter.default.post(name: .openPause, object: nil)
    }

    static func takePending() -> ResistType? {
        defer { UserDefaults.standard.removeObject(forKey: pendingKey) }
        return UserDefaults.standard.string(forKey: pendingKey).flatMap(ResistType.init(rawValue:))
    }

    // MARK: Home-screen icon menu

    static func installShortcutItems() {
        UIApplication.shared.shortcutItems = ResistType.allCases.map { type in
            UIApplicationShortcutItem(
                type: shortcutPrefix + type.rawValue,
                localizedTitle: type.urgeTitle,
                localizedSubtitle: "先停 15 秒",
                icon: UIApplicationShortcutIcon(systemImageName: type.shortcutSymbol),
                userInfo: nil
            )
        }
    }

    @discardableResult
    static func handle(_ item: UIApplicationShortcutItem) -> Bool {
        guard item.type.hasPrefix(shortcutPrefix),
              let type = ResistType(rawValue: String(item.type.dropFirst(shortcutPrefix.count)))
        else { return false }
        open(type)
        return true
    }

    // MARK: Links, which is how the widgets get in

    /// `renleme://pause/money`, `renleme://cooldown/<record id>`, `renleme://home`.
    @discardableResult
    static func handle(url: URL) -> Bool {
        guard url.scheme == WidgetShared.urlScheme else { return false }
        switch url.host {
        case "pause":
            guard let type = ResistType(rawValue: url.lastPathComponent) else { return false }
            open(type)
        case "cooldown":
            guard UUID(uuidString: url.lastPathComponent) != nil else { return false }
            // The same path a cooldown notification takes.
            UserDefaults.standard.set(url.lastPathComponent, forKey: "renleme.pendingCooldownRoute")
            NotificationCenter.default.post(name: .openCooldownRecord, object: url.lastPathComponent)
        case "home":
            NotificationCenter.default.post(name: .openHome, object: nil)
        default:
            return false
        }
        return true
    }
}

private extension ResistType {
    var shortcutSymbol: String {
        switch self {
        case .money: "bag.fill"
        case .food: "fork.knife"
        case .time: "gamecontroller.fill"
        }
    }
}

/// Receives the icon-menu choice, both when it launches the app and when the app is already running.
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let item = connectionOptions.shortcutItem {
            QuickEntry.handle(item)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(QuickEntry.handle(shortcutItem))
    }
}

// MARK: - Siri, Spotlight, Shortcuts, the Action button

struct PauseIntent: AppIntent {
    static var title: LocalizedStringResource = "忍一下"
    static var description = IntentDescription("打开忍了么，先停 15 秒再决定。")
    static var openAppWhenRun = true

    @Parameter(title: "哪一类", default: .money)
    var kind: UrgeKind

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickEntry.open(ResistType(rawValue: kind.rawValue) ?? .money)
        return .result()
    }
}

struct RenLeMeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PauseIntent(),
            phrases: [
                "用\(.applicationName)忍一下",
                "\(.applicationName)忍一下",
                "\(.applicationName)\(\.$kind)"
            ],
            shortTitle: "忍一下",
            systemImageName: "pause.circle.fill"
        )
    }
}
