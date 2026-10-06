import CoreMotion
import SwiftUI

/// Reads which way the phone is leaning and whether it was just shaken.
final class TiltSensor {
    static let shared = TiltSensor()

    private let manager = CMMotionManager()
    private var users = 0
    /// -1 (leaning left) ... 1 (leaning right).
    private(set) var tilt = 0.0
    private(set) var shookAt = Date.distantPast

    func start() {
        users += 1
        guard users == 1, manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            tilt = motion.gravity.x
            let push = motion.userAcceleration
            if sqrt(push.x * push.x + push.y * push.y + push.z * push.z) > 1.4 {
                shookAt = Date()
            }
        }
    }

    func stop() {
        users = max(users - 1, 0)
        guard users == 0 else { return }
        manager.stopDeviceMotionUpdates()
        tilt = 0
    }
}

/// One-dimensional sliding along the ground line: lean, friction, soft walls, and bumping into
/// each other. Kept outside SwiftUI state so stepping it every frame never triggers a redraw.
final class SlideWorld {
    struct Body {
        var x: CGFloat
        var velocity: CGFloat = 0
        /// Height above the ground; negative is up.
        var lift: CGFloat = 0
        var liftVelocity: CGFloat = 0
        var spin = 0.0
        var spinVelocity = 0.0
        var squash: CGFloat = 0
        var isHeld = false
    }

    private(set) var bodies: [UUID: Body] = [:]
    private var lastStep: Date?
    private var layoutWidth: CGFloat = 0
    private var handledShake = Date()

    func sync(ids: [UUID], width: CGFloat) {
        // Wait for a real width, or everyone would start piled up at the left edge.
        guard width > 1 else { return }
        // Layout can settle over a few passes; keep everyone at the same relative spot as it does.
        if layoutWidth > 1, abs(width - layoutWidth) > 1 {
            for id in bodies.keys {
                bodies[id]?.x *= width / layoutWidth
            }
        }
        layoutWidth = width
        for id in bodies.keys where !ids.contains(id) {
            bodies[id] = nil
        }
        for (index, id) in ids.enumerated() where bodies[id] == nil {
            bodies[id] = Body(x: width * CGFloat(index + 1) / CGFloat(ids.count + 1))
        }
    }

    func step(now: Date, tilt: Double, shookAt: Date, width: CGFloat, radius: CGFloat) {
        let elapsed = lastStep.map { now.timeIntervalSince($0) } ?? 0
        lastStep = now
        let dt = CGFloat(min(max(elapsed, 0), 1.0 / 20.0))
        guard dt > 0, width > radius * 2 else { return }

        let lean = abs(tilt) < 0.04 ? 0 : CGFloat(tilt)
        let shaken = shookAt > handledShake
        if shaken { handledShake = shookAt }

        for id in bodies.keys {
            guard var body = bodies[id] else { continue }

            if shaken, body.lift == 0 {
                body.liftVelocity = -620
                body.spinVelocity = 540
            }

            if !body.isHeld {
                body.velocity += lean * 1500 * dt
                body.velocity *= pow(0.22, dt)
                body.x += body.velocity * dt

                if body.x < radius {
                    body.x = radius
                    if body.velocity < -60 { body.squash = 1 }
                    body.velocity = -body.velocity * 0.38
                } else if body.x > width - radius {
                    body.x = width - radius
                    if body.velocity > 60 { body.squash = 1 }
                    body.velocity = -body.velocity * 0.38
                }
            }

            body.liftVelocity += 2100 * dt
            body.lift += body.liftVelocity * dt
            if body.lift >= 0 {
                if body.liftVelocity > 200 { body.squash = 1 }
                body.lift = 0
                body.liftVelocity = 0
                body.spin = 0
                body.spinVelocity = 0
            } else {
                body.spin += body.spinVelocity * Double(dt)
            }

            body.squash = max(body.squash - dt * 5, 0)
            bodies[id] = body
        }

        // Neighbours push each other apart and trade some speed.
        let ordered = bodies.keys.sorted { (bodies[$0]?.x ?? 0) < (bodies[$1]?.x ?? 0) }
        for (left, right) in zip(ordered, ordered.dropFirst()) {
            guard var a = bodies[left], var b = bodies[right] else { continue }
            let overlap = radius * 1.7 - (b.x - a.x)
            guard overlap > 0 else { continue }
            if !a.isHeld { a.x -= overlap / 2 }
            if !b.isHeld { b.x += overlap / 2 }
            let traded = a.velocity
            a.velocity = b.velocity * 0.7
            b.velocity = traded * 0.7
            bodies[left] = a
            bodies[right] = b
        }
    }

    func hop(_ id: UUID) {
        guard var body = bodies[id], body.lift == 0 else { return }
        body.liftVelocity = -560
        bodies[id] = body
    }

    func hold(_ id: UUID, at x: CGFloat, width: CGFloat, radius: CGFloat) {
        guard var body = bodies[id] else { return }
        body.isHeld = true
        body.x = min(max(x, radius), width - radius)
        body.velocity = 0
        bodies[id] = body
    }

    func release(_ id: UUID, velocity: CGFloat) {
        guard var body = bodies[id] else { return }
        body.isHeld = false
        body.velocity = min(max(velocity, -1400), 1400)
        bodies[id] = body
    }
}

/// 小忍 half-hidden behind a ground line at the bottom of the home screen. It slides whichever way
/// the phone leans (or is dragged), ducks lower the faster it goes, pops right out when tapped and
/// flips when the phone is shaken. The results page has a peeker that hides when tapped; this one
/// does the opposite.
struct SlidingPeekMascot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mascotMotionEnabled) private var motionEnabled
    @Environment(\.scenePhase) private var scenePhase

    /// Every record, used for what 小忍 holds up when tapped.
    let records: [ResistRecord]

    @State private var world = SlideWorld()
    @State private var id = UUID()
    @State private var face: DynamicMascotExpression = .curious
    @State private var caption: String?
    @State private var captionToken = 0
    @State private var tapIndex = 0

    private static let mascotSize: CGFloat = 92
    /// How much of the strip is reserved in layout; 小忍 may rise above it while jumping.
    private static let visibleHeight: CGFloat = 50
    private static let faces: [DynamicMascotExpression] = [.curious, .hello, .settled, .sparkle, .heartEyes, .proud]

    private var isActive: Bool {
        motionEnabled && scenePhase == .active && !reduceMotion
    }

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isActive)) { timeline in
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let radius = Self.mascotSize * 0.42
                    let _ = advance(to: timeline.date, width: width, radius: radius)
                    let body = world.bodies[id] ?? SlideWorld.Body(x: width / 2)

                    mascot(body: body, width: width, radius: radius)

                    if let caption {
                        Text(caption)
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .punchBlack.opacity(0.16), radius: 0, x: 0, y: 3)
                            .fixedSize()
                            // Follows 小忍 but never runs off either edge.
                            .position(x: min(max(body.x, 100), max(width - 100, 100)), y: -34)
                            .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
                            .accessibilityIdentifier("slidingPeekCaption")
                    }
                }
            }
            .frame(height: Self.visibleHeight)
            // Hidden below the line, free to rise above it.
            .mask(alignment: .bottom) {
                Rectangle().frame(height: Self.visibleHeight + 200)
            }

            Capsule()
                .fill(Color.punchBlack.opacity(0.14))
                .frame(height: 6)
        }
        .onAppear { TiltSensor.shared.start() }
        .onDisappear { TiltSensor.shared.stop() }
        .task(id: captionToken) {
            guard caption != nil else { return }
            do {
                try await Task.sleep(for: .seconds(2.2))
            } catch {
                return
            }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                caption = nil
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("slidingPeekMascot")
    }

    private func advance(to date: Date, width: CGFloat, radius: CGFloat) {
        world.sync(ids: [id], width: width)
        guard isActive else { return }
        world.step(
            now: date, tilt: TiltSensor.shared.tilt, shookAt: TiltSensor.shared.shookAt,
            width: width, radius: radius
        )
    }

    private func mascot(body: SlideWorld.Body, width: CGFloat, radius: CGFloat) -> some View {
        let speed = abs(body.velocity)
        let lean = Double(min(max(body.velocity / 70, -10), 10))
        // The faster it slides, the lower it keeps its head.
        let duck = min(speed / 700, 1) * 20

        return AnimatedXiaoRenView(
            color: .punchGreen,
            expression: expression(speed: speed, body: body),
            size: Self.mascotSize,
            reduceMotion: reduceMotion
        )
        .scaleEffect(x: 1 + body.squash * 0.14, y: 1 - body.squash * 0.16, anchor: .bottom)
        .rotationEffect(.degrees(lean + body.spin))
        .contentShape(Rectangle())
        .onTapGesture {
            AppHaptics.lightTap()
            world.hop(id)
            face = MascotVariety.next(from: Self.faces, avoiding: [face])
            showNextCaption()
        }
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .named("slidingPeek"))
                .onChanged { value in
                    world.hold(id, at: value.location.x, width: width, radius: radius)
                }
                .onEnded { value in
                    world.release(id, velocity: (value.predictedEndLocation.x - value.location.x) * 4)
                }
        )
        .position(x: body.x, y: Self.visibleHeight + 2 + duck + body.lift)
        .coordinateSpace(name: "slidingPeek")
        .accessibilityLabel("小忍探出半个身子")
        .accessibilityHint("轻点让它跳出来，左右拖动或倾斜手机让它滑动")
        .accessibilityAddTraits(.isButton)
    }

    /// Each tap holds up one thing: first something waiting in the cooldown box (a random one when
    /// there are several), then everything resisted, most recent first, then round again.
    private func showNextCaption() {
        let pending = records.filter { $0.status == .pending }
        let resisted = records
            .filter { $0.status == .resisted }
            .sorted { ($0.resolvedAt ?? $0.createdAt) > ($1.resolvedAt ?? $1.createdAt) }
        let length = (pending.isEmpty ? 0 : 1) + resisted.count

        let text: String
        if length == 0 {
            text = "还什么都没有呢"
        } else {
            let position = tapIndex % length
            if !pending.isEmpty, position == 0, let record = pending.randomElement() {
                text = "冷静箱 · " + Self.describe(record)
            } else {
                text = "忍住 · " + Self.describe(resisted[position - (pending.isEmpty ? 0 : 1)])
            }
            tapIndex += 1
        }

        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.65)) {
            caption = text
        }
        captionToken += 1
    }

    private static func describe(_ record: ResistRecord) -> String {
        record.hasEstimatedValue ? "\(record.title) \(record.displayValueText)" : record.title
    }

    private func expression(speed: CGFloat, body: SlideWorld.Body) -> DynamicMascotExpression {
        if body.lift < 0 { return .celebrate }
        if body.squash > 0.3 { return .startled }
        if speed > 420 { return .surprised }
        return face
    }
}
