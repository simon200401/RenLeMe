import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Where the user's finger is, so every 小忍 on screen can look toward it. Read by each mascot on
/// its own animation tick rather than observed, so a fast scroll never forces extra redraws.
final class MascotAttention {
    static let shared = MascotAttention()

    private(set) var location: CGPoint?
    private(set) var releasedAt: Date?
    private var verticalSpeed = 0.0
    private var movedAt = Date.distantPast
    private var observedWindows = NSHashTable<UIWindow>.weakObjects()

    /// How long the eyes take to drift back to centre after the finger lifts.
    private let lingerSeconds = 0.8

    /// A unit-bounded direction from `frame` toward the finger, fading out after release.
    func look(from frame: CGRect, at now: Date) -> CGVector {
        guard let location, !frame.isEmpty else { return .zero }

        var strength = 1.0
        if let releasedAt {
            let elapsed = now.timeIntervalSince(releasedAt)
            guard elapsed < lingerSeconds else { return .zero }
            strength = 1 - elapsed / lingerSeconds
        }

        let dx = location.x - frame.midX
        let dy = location.y - frame.midY
        let distance = max(hypot(dx, dy), 1)
        let reach = min(distance / 140, 1) * strength
        return CGVector(dx: dx / distance * reach, dy: dy / distance * reach)
    }

    /// Degrees to lean while the page is being flung, fading quickly once the finger slows.
    func lean(at now: Date) -> Double {
        let age = now.timeIntervalSince(movedAt)
        guard age < 0.3 else { return 0 }
        return min(max(-verticalSpeed / 220, -5), 5) * (1 - age / 0.3)
    }

    /// Attaches a passive observer to every window; safe to call repeatedly.
    func install() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows where !observedWindows.contains(window) {
            observedWindows.add(window)
            window.addGestureRecognizer(TouchObserver(attention: self))
        }
    }

    fileprivate func touchMoved(to point: CGPoint) {
        let now = Date()
        if let location, releasedAt == nil {
            let interval = max(now.timeIntervalSince(movedAt), 1.0 / 240)
            let speed = Double(point.y - location.y) / interval
            verticalSpeed = verticalSpeed * 0.6 + speed * 0.4
        } else {
            verticalSpeed = 0
        }
        movedAt = now
        location = point
        releasedAt = nil
    }

    fileprivate func touchEnded() {
        releasedAt = Date()
    }
}

/// Watches touches without ever recognizing, so it cannot delay or cancel anything else.
private final class TouchObserver: UIGestureRecognizer, UIGestureRecognizerDelegate {
    private unowned let attention: MascotAttention

    init(attention: MascotAttention) {
        self.attention = attention
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        report(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        report(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        attention.touchEnded()
        state = .failed
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        attention.touchEnded()
        state = .failed
    }

    private func report(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        attention.touchMoved(to: touch.location(in: nil))
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
