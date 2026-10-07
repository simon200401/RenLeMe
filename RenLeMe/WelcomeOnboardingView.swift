import SwiftUI

private enum WelcomeOnboardingStep: Int, CaseIterable {
    case welcome
    case home
    case record
    case decide
    case goals
    case profile

    var title: String {
        switch self {
        case .welcome:
            "欢迎来到忍了么"
        case .home:
            "冲动来了点忍一下"
        case .record:
            "小忍陪你停 15 秒"
        case .decide:
            "到点再决定"
        case .goals:
            "成果都在这里"
        case .profile:
            "复盘不审判"
        }
    }

    var message: String {
        switch self {
        case .welcome:
            "不批评，不催促。"
        case .home:
            "选一个类型就开始。"
        case .record:
            "点点小忍，等它数完。"
        case .decide:
            "忍住、再等等、还是做了。"
        case .goals:
            "钱、热量、时间和目标。"
        case .profile:
            "统计、成就、冷静箱。"
        }
    }

    var buttonTitle: String {
        self == .profile ? "开始使用" : "下一步"
    }

    var mascotColor: Color {
        switch self {
        case .welcome:
            .punchGreen
        case .home:
            Color(red: 1.0, green: 0.949, blue: 0.839)
        case .record:
            .punchPink
        case .decide:
            .punchYellow
        case .goals:
            .punchGreen
        case .profile:
            Color(red: 1.0, green: 0.949, blue: 0.839)
        }
    }

    var expression: DynamicMascotExpression {
        switch self {
        case .welcome:
            .hello
        case .home:
            .celebrate
        case .record:
            .sparkle
        case .decide:
            .thinking
        case .goals:
            .proud
        case .profile:
            .relieved
        }
    }

    var accentText: String {
        switch self {
        case .welcome:
            "看见冲动"
        case .home:
            "今天"
        case .record:
            "暂停"
        case .decide:
            "冷静箱"
        case .goals:
            "成果页"
        case .profile:
            "我的页"
        }
    }

    var systemImage: String {
        switch self {
        case .welcome:
            "sparkles"
        case .home:
            "pause.circle.fill"
        case .record:
            "timer"
        case .decide:
            "archivebox.fill"
        case .goals:
            "chart.bar.fill"
        case .profile:
            "person.crop.circle.fill"
        }
    }

    var featureTags: [String] {
        switch self {
        case .welcome:
            ["不羞辱", "有陪伴"]
        case .home:
            ["一键开始", "待决定"]
        case .record:
            ["15 秒", "可互动"]
        case .decide:
            ["忍住", "冷静箱", "没忍住"]
        case .goals:
            ["资产", "目标", "记录"]
        case .profile:
            ["统计", "成就", "复盘"]
        }
    }

    var accentUsesDarkText: Bool {
        switch self {
        case .decide, .home, .profile:
            true
        default:
            false
        }
    }
}

struct WelcomeOnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedStep: WelcomeOnboardingStep = .welcome

    var onFinish: () -> Void

    private var steps: [WelcomeOnboardingStep] {
        WelcomeOnboardingStep.allCases
    }

    var body: some View {
        ZStack {
            Color.punchBlack.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                header
                contentCard
                controls
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .frame(maxWidth: 390)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }

    private var header: some View {
        HStack {
            Text("新手引导")
                .font(.rounded(18, weight: .black))
                .foregroundStyle(Color.white)

            Spacer()

            Button {
                onFinish()
            } label: {
                Image(systemName: "xmark")
                    .font(.rounded(13, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                    .frame(width: 34, height: 34)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityLabel("关闭新手引导")
        }
    }

    private var contentCard: some View {
        PunchyCard(fill: .cream, cornerRadius: 36, padding: 20) {
            VStack(spacing: 16) {
                AnimatedXiaoRenView(
                    color: selectedStep.mascotColor,
                    expression: selectedStep.expression,
                    size: 142,
                    reduceMotion: reduceMotion,
                    reaction: selectedStep == .welcome ? .greeting : (selectedStep == .home ? .celebrate : .acknowledge),
                    allowsIdleMotion: true
                )
                .id(selectedStep)
                .transition(.scale(scale: 0.86).combined(with: .opacity))

                VStack(spacing: 10) {
                    Text(selectedStep.title)
                        .font(.rounded(30, weight: .black))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(selectedStep.message)
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                pageCue

                Text(selectedStep.accentText)
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(selectedStep.accentUsesDarkText ? Color.punchBlack : Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(selectedStep.mascotColor)
                    .clipShape(Capsule())
            }
        }
    }

    private var pageCue: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: selectedStep.systemImage)
                    .font(.rounded(17, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                    .frame(width: 38, height: 38)
                    .background(selectedStep.mascotColor.opacity(0.28))
                    .clipShape(Circle())

                Text(selectedStep.accentText)
                    .font(.rounded(17, weight: .black))
                    .foregroundStyle(Color.ink)

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ForEach(selectedStep.featureTags, id: \.self) { tag in
                    Text(tag)
                        .font(.rounded(12, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(Color.softCream)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(steps, id: \.self) { step in
                    Capsule()
                        .fill(step == selectedStep ? Color.white : Color.white.opacity(0.36))
                        .frame(width: step == selectedStep ? 24 : 8, height: 8)
                }
            }

            HStack(spacing: 10) {
                if selectedStep != .welcome {
                    Button {
                        moveStep(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .frame(width: 52, height: 52)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityLabel("上一步")
                }

                Button {
                    if selectedStep == .profile {
                        onFinish()
                    } else {
                        moveStep(1)
                    }
                } label: {
                    Text(selectedStep.buttonTitle)
                        .font(.rounded(18, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.punchBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
    }

    private func moveStep(_ offset: Int) {
        guard let index = steps.firstIndex(of: selectedStep) else { return }
        let newIndex = min(max(index + offset, 0), steps.count - 1)

        if reduceMotion {
            selectedStep = steps[newIndex]
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                selectedStep = steps[newIndex]
            }
        }
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
        case .choosing:
            self = .thinking
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
        case .assetPositive(let type):
            self = type == .food ? .relieved : .sparkle
        case .goalProgress(let progress, _):
            self = progress > 0 ? .proud : .curious
        case .reviewCalm:
            self = .relieved
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
    WelcomeOnboardingView {}
}
