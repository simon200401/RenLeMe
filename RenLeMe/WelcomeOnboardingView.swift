import SwiftUI

/// Where a new user is in the welcome walk-through. Rather than describe the app, it has them do the
/// things the app is for, once: stop on an urge and decide (for practice), see where what they held
/// back shows up, and give it somewhere to go.
@MainActor
final class OnboardingGuide: ObservableObject {
    static let shared = OnboardingGuide()

    enum Step {
        /// One card saying what the app is for.
        case welcome
        /// The home screen with only the three ways in lit; tapping one starts the practice run.
        case pickType
        /// The practice run is on screen.
        case practice
        /// Back on the home screen: the count and the pictures under it, shown with a stand-in.
        case today
        /// The goal section, with the offer to make one.
        case goal
        /// The new-goal sheet is on screen.
        case goalForm
        /// A look at the results tab.
        case results
        /// A look at the profile tab.
        case profile
        /// The three ways in once more.
        case done
    }

    @Published var step: Step?
    /// Where things sit on screen, reported by the home screen.
    @Published var entryFrame: CGRect = .zero
    @Published var statusFrame: CGRect = .zero
    @Published var goalFrame: CGRect = .zero

    /// What the practice run was about, for the stand-in on the home screen and the goal's kind.
    @Published var practicedType: ResistType = .money
    @Published var practicedTemplate: PropTemplate?

    var isActive: Bool { step != nil }

    /// The picture shown as an example under "Today" while that step is up.
    var exampleTemplate: PropTemplate {
        practicedTemplate ?? PropTemplate.defaultTemplate(for: practicedType)
    }
}

/// What sits over the app during the walk-through.
struct WelcomeOnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var guide = OnboardingGuide.shared

    /// The walk-through visits the other two tabs and comes back.
    @Binding var selectedTab: AppTab
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            switch guide.step {
            case .welcome:
                welcome
            case .pickType:
                spotlight(
                    on: guide.entryFrame,
                    title: "现在最想忍住哪一类？",
                    detail: "点一个，我们试一遍。",
                    secondary: ("跳过", onFinish),
                    letsTapsThrough: true
                )
            case .today:
                spotlight(
                    on: guide.statusFrame,
                    title: "忍住的都在这里",
                    detail: "今天忍住几次，是哪几件。点图标可以看那条记录。",
                    primary: ("下一步", { advance(to: .goal) }),
                    secondary: ("跳过", onFinish)
                )
            case .goal:
                spotlight(
                    on: guide.goalFrame,
                    title: "给省下的定个去处",
                    detail: "比如一次旅行、一台相机。以后每忍住一次，进度就往前走一点。",
                    primary: ("建一个目标", { advance(to: .goalForm) }),
                    secondary: ("以后再说", { advance(to: .results) })
                )
            case .results:
                pageIntro(
                    title: "成果",
                    detail: "省下的钱、守住的热量、拿回的时间，还有目标的进度，都在这一页。",
                    next: .profile
                )
            case .profile:
                pageIntro(
                    title: "我的",
                    detail: "冷静箱、什么时候最容易心动、提醒和备份，在这一页。",
                    next: .done
                )
            case .done:
                spotlight(
                    on: guide.entryFrame,
                    title: "就是这样",
                    detail: "冲动来了，先点这里。",
                    primary: ("开始使用", onFinish)
                )
            case .practice, .goalForm, .none:
                EmptyView()
            }
        }
        .transition(.opacity)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: guide.step)
        .onChange(of: guide.step) { _, step in
            switch step {
            case .results: selectedTab = .results
            case .profile: selectedTab = .profile
            case .done: selectedTab = .home
            default: break
            }
        }
    }

    private func advance(to step: OnboardingGuide.Step) {
        AppHaptics.lightTap()
        guide.step = step
    }

    // MARK: One card

    private var welcome: some View {
        ZStack {
            Color.punchBlack.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                PunchyCard(fill: .cream, cornerRadius: 36, padding: 24) {
                    VStack(spacing: 16) {
                        AnimatedXiaoRenView(
                            color: Color(red: 1.0, green: 0.949, blue: 0.839),
                            expression: .hello,
                            size: 150,
                            reduceMotion: reduceMotion,
                            reaction: .greeting,
                            allowsIdleMotion: true
                        )

                        Text("想要的时候，\n先停 15 秒")
                            .font(.rounded(30, weight: .black))
                            .foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center)

                        Text("想买、想吃、想玩，都可以。\n不批评，不催促，小忍陪你等。")
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }

                Button {
                    advance(to: .pickType)
                } label: {
                    Text("试一次（1 分钟）")
                        .font(.rounded(18, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.punchBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
                .accessibilityIdentifier("onboardingTryButton")

                Button("跳过，直接开始", action: onFinish)
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.white)
                    .padding(.vertical, 6)
                    .accessibilityIdentifier("onboardingSkipButton")
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 420)
        }
    }

    // MARK: A look at another tab

    /// The page itself stays in view, only lightly dimmed; the card sits low, above the tab bar.
    private func pageIntro(title: String, detail: String, next: OnboardingGuide.Step) -> some View {
        ZStack(alignment: .bottom) {
            Color.punchBlack.opacity(0.28)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.rounded(18, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                Text(detail)
                    .font(.rounded(14, weight: .bold))
                    .foregroundStyle(Color.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 16) {
                    Button {
                        advance(to: next)
                    } label: {
                        Text("下一步")
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Color.punchBlack)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityIdentifier("onboardingPrimaryButton")

                    Button("跳过", action: onFinish)
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .accessibilityIdentifier("onboardingSecondaryButton")
                }
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: 340, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .punchBlack.opacity(0.2), radius: 0, x: 0, y: 5)
            .padding(.horizontal, 22)
            .padding(.bottom, 96)
        }
    }

    // MARK: The home screen, with one thing lit

    private typealias Choice = (title: String, action: () -> Void)

    private func spotlight(
        on frame: CGRect,
        title: String,
        detail: String,
        primary: Choice? = nil,
        secondary: Choice? = nil,
        letsTapsThrough: Bool = false
    ) -> some View {
        GeometryReader { geometry in
            // The frame comes in screen coordinates; this layer may start below the top of the screen.
            let origin = geometry.frame(in: .global).origin
            let lit = frame
                .offsetBy(dx: -origin.x, dy: -origin.y)
                .insetBy(dx: -10, dy: -10)
            // Something scrolled out of view, or not on this screen at all, cannot be pointed at;
            // the card then stands on its own in the middle.
            let canPoint = frame.width > 0 && lit.minY > 0 && lit.maxY < geometry.size.height - 230
            let hole = canPoint ? lit : .zero
            let shape = SpotlightShape(hole: hole, cornerRadius: 30)
            let cardWidth = min(geometry.size.width - 44, 340)

            ZStack(alignment: .topLeading) {
                shape
                    .fill(Color.punchBlack.opacity(0.55), style: FillStyle(eoFill: true))
                    // Outside the hole swallows taps; inside, they reach the buttons underneath when
                    // that is the point of the step.
                    .contentShape(letsTapsThrough && canPoint ? AnyShape(shape) : AnyShape(Rectangle()), eoFill: true)
                    .onTapGesture {}

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.rounded(18, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                    Text(detail)
                        .font(.rounded(14, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 16) {
                        if let primary {
                            Button(action: primary.action) {
                                Text(primary.title)
                                    .font(.rounded(16, weight: .black))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 12)
                                    .background(Color.punchBlack)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(PressableScaleStyle())
                            .accessibilityIdentifier("onboardingPrimaryButton")
                        }

                        if let secondary {
                            Button(secondary.title, action: secondary.action)
                                .font(.rounded(14, weight: .black))
                                .foregroundStyle(Color.secondaryInk)
                                .accessibilityIdentifier("onboardingSecondaryButton")
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .frame(width: cardWidth, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .punchBlack.opacity(0.2), radius: 0, x: 0, y: 5)
                .offset(
                    x: (geometry.size.width - cardWidth) / 2,
                    y: canPoint ? hole.maxY + 14 : geometry.size.height * 0.38
                )
            }
        }
        .ignoresSafeArea()
    }
}

/// The whole area with a rounded window cut out of it.
private struct SpotlightShape: Shape {
    var hole: CGRect
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: cornerRadius, height: cornerRadius), style: .continuous)
        return path
    }
}

enum DynamicMascotExpression: Equatable {
    case hello
    case curious
    case thinking
    case proud
    case sparkle
    case celebrate
    case cooling
    case observe
    case relieved
    /// Pause scene: eyeing the thing it wants, before the countdown starts.
    case craving
    /// Pause scene: cheeks full on the in-breath.
    case inhale
    /// Pause scene: blowing the breath out.
    case exhale
    /// Pause scene: the urge has passed.
    case settled
    /// Poked too many times.
    case dizzy
    /// Poked far too many times: turned away, face hidden.
    case sulk
    case asleep
    case yawn
    /// Woken with a jolt.
    case startled
    /// A big number, or a level-up.
    case surprised
    /// Moved to tears: a goal reached, or a return after a long while.
    case touched
    /// Pretending not to have noticed.
    case lookAway
    /// Fist up, rooting for you.
    case cheer
    case heartEyes

    var restsWithEyesClosed: Bool {
        switch self {
        case .relieved, .inhale, .exhale, .settled, .asleep, .yawn: true
        default: false
        }
    }

    init(moment: MascotMoment) {
        switch moment {
        case .idle:
            self = .hello
        case .resistedSuccess:
            self = .celebrate
        case .coolingSaved:
            self = .cheer
        case .coolingRecord:
            self = .cooling
        case .gaveInSaved:
            self = .lookAway
        case .observingRecord:
            self = .observe
        }
    }
}

struct AnimatedXiaoRenView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.mascotMotionEnabled) private var motionEnabled
    let color: Color
    let expression: DynamicMascotExpression
    var size: CGFloat = 150
    var reduceMotion = false
    var reaction: MascotReaction?
    var reactionToken = 0
    var allowsIdleMotion = true
    var isPaused = false
    var heldType: ResistType?
    @State private var isVisible = false
    @State private var isPlaying = false
    @State private var motionStartedAt: Date?
    @State private var breathPhase = Double.random(in: 0..<6)
    @State private var globalFrame = CGRect.zero

    private var isActive: Bool {
        isVisible && motionEnabled && scenePhase == .active && !reduceMotion && !isPaused
    }

    private var playbackKey: MascotPlaybackKey {
        MascotPlaybackKey(reaction: reaction, token: reactionToken, isActive: isActive)
    }

    var body: some View {
        TimelineView(.animation(
            minimumInterval: isPlaying ? 1.0 / 30.0 : 1.0 / 20.0,
            paused: !isActive || (!isPlaying && !allowsIdleMotion)
        )) { context in
            let elapsed = motionStartedAt.map { context.date.timeIntervalSince($0) } ?? 0
            let isIdle = isActive && allowsIdleMotion && !isPlaying
            let now = context.date.timeIntervalSinceReferenceDate
            let pose = lookingPose(
                from: isActive && isPlaying ? reaction?.sample(at: elapsed) ?? .rest : .rest,
                at: context.date
            )
            let blink = isIdle ? CGFloat(MascotMotionSample.blinkOpenness(at: now)) : 1
            // A slow breath through the whole body whenever nothing else is playing.
            let breath = isIdle ? sin(now * 1.9 + breathPhase) : 0

            ZStack {
                hands(pose: pose)

                DynamicMascotBody(wobble: CGFloat((1 - pose.scaleY) * 0.2), expression: expression)
                    .fill(color)
                    .overlay {
                        DynamicMascotBody(wobble: CGFloat((1 - pose.scaleY) * 0.2), expression: expression)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.07, lineJoin: .round))
                    }
                    .shadow(color: .punchBlack.opacity(0.18), radius: 0, x: 0, y: size * 0.05)

                if expression != .sulk {
                    eyes(blink: blink, pose: pose)
                    brows(pose: pose)
                    mouth(pose: pose)
                }
                accessory(pose: pose)
                if let heldType {
                    TypeMascotPoseAccessory(
                        type: heldType, lift: CGFloat(pose.propLift),
                        squeeze: CGFloat(pose.propSqueeze), tilt: pose.propTilt,
                        push: CGFloat(pose.propPush)
                    )
                    .frame(width: size, height: size * 0.96)
                }
                if pose.blush > 0 && expression != .observe {
                    ForEach([-1.0, 1.0], id: \.self) { side in
                        Circle()
                            .fill(Color.punchPink.opacity(pose.blush * 0.55))
                            .frame(width: size * 0.09)
                            .offset(x: size * 0.34 * side, y: size * 0.09)
                    }
                }
            }
            .frame(width: size, height: size * 0.96)
            .scaleEffect(x: pose.scaleX * (1 - 0.012 * breath), y: pose.scaleY * (1 + 0.02 * breath), anchor: .bottom)
            .rotationEffect(.degrees(pose.tilt + pose.spin + (isActive ? MascotAttention.shared.lean(at: context.date) : 0)))
            .offset(x: size * pose.shiftX, y: size * pose.vertical)
        }
        .frame(width: size, height: size * 0.96)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            globalFrame = frame
        }
        .accessibilityHidden(true)
        .onAppear { isVisible = true }
        .onDisappear {
            isVisible = false
            isPlaying = false
            motionStartedAt = nil
        }
        .task(id: playbackKey) {
            isPlaying = false
            motionStartedAt = nil
            guard isActive, let reaction else { return }
            motionStartedAt = Date()
            isPlaying = true
            do {
                try await Task.sleep(for: .seconds(reaction.duration))
            } catch {
                return
            }
            isPlaying = false
            motionStartedAt = nil
        }
    }

    /// Turns the eyes toward the user's finger on top of whatever the current motion is doing.
    private func lookingPose(from pose: MascotMotionSample, at date: Date) -> MascotMotionSample {
        guard isActive else { return pose }
        let look = MascotAttention.shared.look(from: globalFrame, at: date)
        guard look != .zero else { return pose }
        var pose = pose
        pose.gaze = min(max(pose.gaze + Double(look.dx) * 1.1, -1.2), 1.2)
        pose.gazeY = min(max(pose.gazeY + Double(look.dy) * 0.9, -1.2), 1.2)
        return pose
    }

    private func eyes(blink: CGFloat, pose: MascotMotionSample) -> some View {
        let restingClosure: Double = expression.restsWithEyesClosed ? 1 : 0
        // Craving looks down at whatever it is holding.
        let lookY = pose.gazeY + (expression == .craving ? 1.1 : expression == .lookAway ? -0.5 : 0)
        // Looking away keeps its eyes firmly off to one side.
        let look = pose.gaze + (expression == .lookAway ? 1.3 : 0)
        return ZStack {
            eye(x: -size * 0.17, openness: min(blink, 1 - max(restingClosure, pose.leftClosure)), look: look, lookY: lookY)
            eye(x: size * 0.17, openness: min(blink, 1 - max(restingClosure, pose.rightClosure)), look: look, lookY: lookY)
        }
    }

    private func eye(x: CGFloat, openness: CGFloat, look: Double, lookY: Double) -> some View {
        Group {
            if openness < 0.2 {
                Path { path in
                    // Settled eyes arch upward into a smile; every other closed eye droops.
                    let isHappy = expression == .settled
                    let edgeY = size * (isHappy ? 0.06 : 0.025)
                    path.move(to: CGPoint(x: 0, y: edgeY))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.17, y: edgeY),
                        control: CGPoint(x: size * 0.085, y: size * (isHappy ? -0.03 : 0.09))
                    )
                }
                .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: size * 0.032, lineCap: .round))
                .frame(width: size * 0.17, height: size * 0.07)
            } else {
                if expression == .heartEyes {
                    Image(systemName: "heart.fill")
                        .font(.system(size: size * 0.17, weight: .black))
                        .foregroundStyle(Color.punchPink)
                } else {
                    let isWide = expression == .startled || expression == .surprised
                    let pupil: CGFloat = isWide ? 0.04 : expression == .touched ? 0.09 : 0.055
                    ZStack {
                        Capsule()
                            .fill(Color.white)
                            .frame(width: size * 0.17, height: size * 0.25 * openness * (isWide ? 1.14 : 1))

                        if expression == .dizzy {
                            // Swirling eyes.
                            Circle()
                                .stroke(Color.punchBlack, lineWidth: size * 0.022)
                                .frame(width: size * 0.11)
                            Circle()
                                .fill(Color.punchBlack)
                                .frame(width: size * 0.035)
                                .offset(x: CGFloat(look) * size * 0.03)
                        } else {
                            Circle()
                                .fill(Color.punchBlack)
                                .frame(width: size * pupil)
                                .overlay(alignment: .topLeading) {
                                    if expression == .touched {
                                        // A glint of welling tears.
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: size * 0.032)
                                            .offset(x: size * 0.012, y: size * 0.012)
                                    }
                                }
                                .offset(x: CGFloat(look) * size * 0.034, y: size * 0.03 * (openness + CGFloat(lookY)))
                        }
                    }
                }
            }
        }
        .frame(width: size * 0.17, height: size * 0.25)
        .offset(x: x, y: -size * 0.12)
    }

    private func brows(pose: MascotMotionSample) -> some View {
        ZStack {
            brow(x: -size * 0.18, rotation: leftBrowRotation - CGFloat(pose.smile * 3))
            brow(x: size * 0.18, rotation: rightBrowRotation + CGFloat(pose.smile * 3))
        }
    }

    private var leftBrowRotation: CGFloat {
        switch expression {
        case .hello, .relieved, .cooling, .observe, .settled, .heartEyes: -8
        case .curious, .sparkle, .surprised, .startled, .touched: -16
        case .thinking, .craving, .dizzy: 12
        case .cheer: 17
        case .inhale: 5
        case .exhale, .yawn: -12
        case .proud, .celebrate, .sulk, .lookAway: -6
        case .asleep: -3
        }
    }

    private var rightBrowRotation: CGFloat {
        switch expression {
        case .hello, .relieved, .cooling, .observe, .settled, .heartEyes: 8
        case .curious, .sparkle, .surprised, .startled, .touched: 16
        case .thinking, .craving, .dizzy: -12
        case .cheer: -17
        case .inhale: -5
        case .exhale, .yawn: 12
        case .proud, .celebrate, .sulk: 6
        case .lookAway: 12
        case .asleep: 3
        }
    }

    private func brow(x: CGFloat, rotation: CGFloat) -> some View {
        Capsule()
            .fill(Color.punchBlack)
            .frame(width: size * 0.19, height: size * 0.045)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: -size * 0.285)
    }

    private func mouth(pose: MascotMotionSample) -> some View {
        Path { path in
            let centerX = size * 0.5
            let centerY = size * 0.52
            if pose.openMouth > 0.15 {
                path.addEllipse(in: CGRect(x: centerX - size * 0.045, y: centerY,
                                          width: size * 0.09, height: size * 0.10 * pose.openMouth))
                return
            }
            switch expression {
            case .hello, .relieved, .cooling, .observe:
                path.move(to: CGPoint(x: centerX - size * 0.16, y: centerY))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.16, y: centerY),
                    control: CGPoint(x: centerX, y: centerY + size * (0.13 + pose.smile * 0.035))
                )
            case .dizzy:
                // A wobbly line.
                path.move(to: CGPoint(x: centerX - size * 0.12, y: centerY + size * 0.03))
                path.addCurve(
                    to: CGPoint(x: centerX + size * 0.12, y: centerY + size * 0.03),
                    control1: CGPoint(x: centerX - size * 0.04, y: centerY - size * 0.05),
                    control2: CGPoint(x: centerX + size * 0.04, y: centerY + size * 0.11)
                )
            case .sulk:
                break
            case .asleep:
                path.addEllipse(in: CGRect(x: centerX - size * 0.03, y: centerY, width: size * 0.06, height: size * 0.065))
            case .yawn:
                path.addEllipse(in: CGRect(x: centerX - size * 0.075, y: centerY - size * 0.03, width: size * 0.15, height: size * 0.17))
            case .startled:
                path.addEllipse(in: CGRect(x: centerX - size * 0.07, y: centerY - size * 0.01, width: size * 0.14, height: size * 0.1))
            case .surprised:
                path.addEllipse(in: CGRect(x: centerX - size * 0.045, y: centerY - size * 0.015, width: size * 0.09, height: size * 0.11))
            case .touched:
                // A smile that trembles a little.
                path.move(to: CGPoint(x: centerX - size * 0.13, y: centerY + size * 0.01))
                path.addCurve(
                    to: CGPoint(x: centerX + size * 0.13, y: centerY + size * 0.01),
                    control1: CGPoint(x: centerX - size * 0.05, y: centerY + size * 0.15),
                    control2: CGPoint(x: centerX + size * 0.04, y: centerY + size * 0.04)
                )
            case .lookAway:
                // Whistling off to one side.
                path.addEllipse(in: CGRect(x: centerX + size * 0.03, y: centerY, width: size * 0.06, height: size * 0.065))
            case .cheer:
                path.move(to: CGPoint(x: centerX - size * 0.09, y: centerY + size * 0.04))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.09, y: centerY + size * 0.04),
                    control: CGPoint(x: centerX, y: centerY + size * 0.075)
                )
            case .heartEyes:
                path.move(to: CGPoint(x: centerX - size * 0.16, y: centerY - size * 0.01))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.16, y: centerY - size * 0.01),
                    control: CGPoint(x: centerX, y: centerY + size * 0.19)
                )
            case .settled:
                path.move(to: CGPoint(x: centerX - size * 0.12, y: centerY))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.12, y: centerY),
                    control: CGPoint(x: centerX, y: centerY + size * 0.16)
                )
            case .craving:
                path.addEllipse(in: CGRect(x: centerX - size * 0.065, y: centerY - size * 0.01, width: size * 0.13, height: size * 0.06))
            case .inhale:
                path.move(to: CGPoint(x: centerX - size * 0.035, y: centerY + size * 0.03))
                path.addLine(to: CGPoint(x: centerX + size * 0.035, y: centerY + size * 0.03))
            case .exhale:
                path.addEllipse(in: CGRect(x: centerX - size * 0.035, y: centerY - size * 0.005, width: size * 0.07, height: size * 0.075))
            case .curious, .sparkle:
                path.addEllipse(in: CGRect(x: centerX - size * 0.055, y: centerY - size * 0.02, width: size * 0.11, height: size * 0.085))
            case .thinking:
                path.move(to: CGPoint(x: centerX - size * 0.13, y: centerY + size * 0.04))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.13, y: centerY + size * 0.04),
                    control: CGPoint(x: centerX - size * 0.02, y: centerY - size * 0.06)
                )
            case .proud, .celebrate:
                path.move(to: CGPoint(x: centerX - size * 0.18, y: centerY - size * 0.01))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.18, y: centerY - size * 0.01),
                    control: CGPoint(x: centerX, y: centerY + size * 0.21)
                )
            }
        }
        .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: size * 0.052, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size * 0.96)
    }

    @ViewBuilder
    private func accessory(pose: MascotMotionSample) -> some View {
        switch expression {
        case .hello:
            EmptyView()
        case .curious:
            Circle()
                .fill(Color.punchPink.opacity(0.45))
                .frame(width: size * 0.09)
                .offset(x: -size * 0.36, y: size * 0.12)
            Circle()
                .fill(Color.punchPink.opacity(0.45))
                .frame(width: size * 0.075)
                .offset(x: size * 0.36, y: size * 0.11)
        case .thinking:
            Path { path in
                path.move(to: CGPoint(x: size * 0.76, y: size * 0.23))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.79, y: size * 0.50),
                    control: CGPoint(x: size * 0.94, y: size * 0.35)
                )
            }
            .stroke(Color.punchBlue, style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
            .frame(width: size, height: size)
        case .cooling:
            Image(systemName: "clock.fill")
                .font(.system(size: size * 0.24, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.punchBlack, Color.softCream)
                .rotationEffect(.degrees(-8 + pose.gaze * 8))
                .offset(x: size * 0.29, y: size * 0.25)
                .overlay {
                    Capsule()
                        .fill(color)
                        .overlay { Capsule().stroke(Color.white, lineWidth: size * 0.025) }
                        .frame(width: size * 0.16, height: size * 0.065)
                        .rotationEffect(.degrees(-20))
                        .offset(x: size * 0.23, y: size * 0.28)
                }
        case .proud:
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.18, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .rotationEffect(.degrees(pose.tilt))
                .offset(x: size * 0.39, y: -size * 0.31)
        case .sparkle:
            Image(systemName: "questionmark")
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .rotationEffect(.degrees(pose.tilt))
                .offset(x: size * 0.38, y: -size * 0.30)
            Circle()
                .fill(Color.punchBlue.opacity(0.75))
                .frame(width: size * 0.08)
                .offset(x: -size * 0.39, y: -size * 0.24)
        case .celebrate:
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.23, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .scaleEffect(1 + pose.arms * 0.12)
                .rotationEffect(.degrees(pose.tilt))
                .offset(x: size * 0.40, y: -size * 0.32)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.15, weight: .black))
                .foregroundStyle(Color.white)
                .offset(x: -size * 0.38, y: -size * 0.26)
        case .observe:
            Circle()
                .fill(Color.punchPink.opacity(0.38 + pose.blush * 0.22))
                .frame(width: size * 0.08)
                .offset(x: -size * 0.34, y: size * 0.10)
            Circle()
                .fill(Color.punchPink.opacity(0.38 + pose.blush * 0.22))
                .frame(width: size * 0.08)
                .offset(x: size * 0.34, y: size * 0.10)
        case .relieved:
            EmptyView()
        case .craving:
            // A drop of drool at the corner of the mouth.
            Capsule()
                .fill(Color.punchBlue)
                .frame(width: size * 0.045, height: size * 0.085)
                .offset(x: size * 0.085, y: size * 0.125)
        case .inhale:
            ForEach([-1.0, 1.0], id: \.self) { side in
                Circle()
                    .fill(Color.punchPink.opacity(0.62))
                    .frame(width: size * 0.14)
                    .offset(x: size * 0.31 * side, y: size * 0.07)
            }
        case .exhale:
            // Breath lines drifting away from the mouth.
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.punchBlue.opacity(0.85 - Double(index) * 0.2))
                    .frame(width: size * (0.10 - CGFloat(index) * 0.02), height: size * 0.03)
                    .rotationEffect(.degrees(12))
                    .offset(
                        x: size * (0.19 + CGFloat(index) * 0.09),
                        y: size * (0.075 + CGFloat(index) * 0.035)
                    )
            }
        case .dizzy:
            // Stars circling overhead.
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size * (0.12 - CGFloat(index) * 0.015), weight: .black))
                    .foregroundStyle(Color.punchYellow)
                    .offset(
                        x: size * (CGFloat(index) - 1) * 0.24 + CGFloat(pose.gaze) * size * 0.06,
                        y: -size * (0.44 - (index == 1 ? 0.06 : 0))
                    )
            }
        case .asleep:
            ForEach(0..<2, id: \.self) { index in
                Text("z")
                    .font(.system(size: size * (0.16 + CGFloat(index) * 0.07), weight: .black, design: .rounded))
                    .foregroundStyle(Color.punchBlue)
                    .offset(x: size * (0.36 + CGFloat(index) * 0.1), y: -size * (0.3 + CGFloat(index) * 0.13))
            }
        case .yawn:
            // A sleepy tear.
            Circle()
                .fill(Color.punchBlue)
                .frame(width: size * 0.05)
                .offset(x: size * 0.29, y: -size * 0.06)
        case .startled:
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.punchBlack)
                    .frame(width: size * 0.03, height: size * 0.1)
                    .rotationEffect(.degrees(Double(index - 1) * 28))
                    .offset(x: size * CGFloat(index - 1) * 0.13, y: -size * (index == 1 ? 0.52 : 0.48))
            }
        case .surprised:
            Image(systemName: "exclamationmark")
                .font(.system(size: size * 0.22, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .rotationEffect(.degrees(12))
                .offset(x: size * 0.4, y: -size * 0.32)
        case .touched:
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule()
                    .fill(Color.punchBlue)
                    .frame(width: size * 0.045, height: size * 0.075)
                    .offset(x: size * 0.25 * side, y: size * 0.04)
                Circle()
                    .fill(Color.punchPink.opacity(0.5))
                    .frame(width: size * 0.09)
                    .offset(x: size * 0.34 * side, y: size * 0.11)
            }
        case .lookAway:
            Image(systemName: "music.note")
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(Color.punchBlack)
                .rotationEffect(.degrees(10))
                .offset(x: size * 0.36, y: -size * 0.06)
        case .cheer:
            // A raised fist, with two lines of effort beside it.
            Circle()
                .fill(color)
                .overlay { Circle().stroke(Color.white, lineWidth: size * 0.04) }
                .frame(width: size * 0.2)
                .offset(x: size * 0.4, y: -size * 0.14)
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(Color.punchYellow)
                    .frame(width: size * 0.03, height: size * 0.09)
                    .rotationEffect(.degrees(index == 0 ? 20 : 55))
                    .offset(x: size * (0.44 + CGFloat(index) * 0.08), y: -size * (0.32 - CGFloat(index) * 0.07))
            }
        case .heartEyes:
            ForEach(0..<2, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: size * (0.12 - CGFloat(index) * 0.03), weight: .black))
                    .foregroundStyle(Color.punchPink)
                    .offset(x: size * (0.38 + CGFloat(index) * 0.08), y: -size * (0.28 + CGFloat(index) * 0.13))
            }
        case .sulk:
            // A puff of annoyance where the face would be.
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(Color.punchPink)
                    .frame(width: size * 0.035, height: size * 0.1)
                    .offset(y: -size * 0.075)
                    .rotationEffect(.degrees(Double(index) * 90 + 45))
                    .offset(x: size * 0.3, y: -size * 0.3)
            }
        case .settled:
            ForEach([-1.0, 1.0], id: \.self) { side in
                Circle()
                    .fill(Color.punchPink.opacity(0.5))
                    .frame(width: size * 0.09)
                    .offset(x: size * 0.33 * side, y: size * 0.09)
            }
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.15, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .offset(x: size * 0.39, y: -size * 0.30)
        }
    }

    @ViewBuilder
    private func hands(pose: MascotMotionSample) -> some View {
        if pose.wave > 0 || pose.arms > 0 {
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule()
                    .fill(color)
                    .overlay { Capsule().stroke(Color.white, lineWidth: size * 0.04) }
                    .frame(width: size * 0.12, height: size * 0.25)
                    .rotationEffect(.degrees(side * (45 + pose.arms * 30 + (side > 0 ? pose.wave * 25 : 0))))
                    .offset(x: size * 0.37 * side, y: -size * (0.02 + pose.arms * 0.14))
                    .opacity(pose.arms > 0 ? pose.arms : (side > 0 ? pose.wave : 0))
            }
        }
    }

}

private struct MascotPlaybackKey: Equatable {
    let reaction: MascotReaction?
    let token: Int
    let isActive: Bool
}

private struct MascotMotionEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var mascotMotionEnabled: Bool {
        get { self[MascotMotionEnabledKey.self] }
        set { self[MascotMotionEnabledKey.self] = newValue }
    }
}

private struct DynamicMascotBody: Shape {
    var wobble: CGFloat
    var expression: DynamicMascotExpression

    var animatableData: CGFloat {
        get { wobble }
        set { wobble = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let lift = (expression == .proud || expression == .celebrate) ? -h * 0.025 : 0

        var path = Path()
        path.move(to: CGPoint(x: w * (0.50 + wobble * 0.45), y: h * 0.08 + lift))
        path.addCurve(
            to: CGPoint(x: w * (0.88 - wobble * 0.2), y: h * 0.30),
            control1: CGPoint(x: w * 0.65, y: h * 0.08),
            control2: CGPoint(x: w * 0.78, y: h * 0.16)
        )
        path.addCurve(
            to: CGPoint(x: w * (0.78 + wobble * 0.32), y: h * 0.84),
            control1: CGPoint(x: w * 0.98, y: h * 0.49),
            control2: CGPoint(x: w * 0.80, y: h * 0.64)
        )
        path.addCurve(
            to: CGPoint(x: w * (0.50 - wobble * 0.25), y: h * 0.78),
            control1: CGPoint(x: w * 0.68, y: h * 0.98),
            control2: CGPoint(x: w * 0.58, y: h * 0.77)
        )
        path.addCurve(
            to: CGPoint(x: w * (0.20 + wobble * 0.2), y: h * 0.86),
            control1: CGPoint(x: w * 0.38, y: h * 0.78),
            control2: CGPoint(x: w * 0.28, y: h * 0.96)
        )
        path.addCurve(
            to: CGPoint(x: w * (0.14 - wobble * 0.32), y: h * 0.40),
            control1: CGPoint(x: w * 0.08, y: h * 0.72),
            control2: CGPoint(x: w * 0.23, y: h * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: w * (0.50 + wobble * 0.45), y: h * 0.08 + lift),
            control1: CGPoint(x: w * 0.02, y: h * 0.21),
            control2: CGPoint(x: w * 0.34, y: h * 0.15)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    WelcomeOnboardingView(selectedTab: .constant(.home)) {}
}
