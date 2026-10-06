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
            "首页先看成果"
        case .record:
            "冲动来了先记下"
        case .decide:
            "给自己一个暂停"
        case .goals:
            "把忍住投向目标"
        case .profile:
            "复盘不审判"
        }
    }

    var message: String {
        switch self {
        case .welcome:
            "不批评，不催促。"
        case .home:
            "钱、热量、时间。"
        case .record:
            "类型、道具、数值。"
        case .decide:
            "忍住、冷静箱、观察。"
        case .goals:
            "进度和去向。"
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
            "首页"
        case .record:
            "记录页"
        case .decide:
            "冷静箱"
        case .goals:
            "目标页"
        case .profile:
            "我的页"
        }
    }

    var systemImage: String {
        switch self {
        case .welcome:
            "sparkles"
        case .home:
            "house.fill"
        case .record:
            "plus.circle.fill"
        case .decide:
            "archivebox.fill"
        case .goals:
            "target"
        case .profile:
            "person.crop.circle.fill"
        }
    }

    var featureTags: [String] {
        switch self {
        case .welcome:
            ["不羞辱", "有陪伴"]
        case .home:
            ["忍耐资产", "点击反馈"]
        case .record:
            ["类型", "道具", "数值"]
        case .decide:
            ["忍住", "冷静箱", "观察"]
        case .goals:
            ["进度", "去向"]
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

    init(moment: MascotMoment) {
        switch moment {
        case .idle:
            self = .hello
        case .choosing:
            self = .thinking
        case .resistedSuccess:
            self = .celebrate
        case .coolingSaved, .coolingRecord:
            self = .cooling
        case .gaveInSaved, .observingRecord:
            self = .observe
        case .assetPositive(let type):
            self = type == .food ? .relieved : .sparkle
        case .goalProgress(let progress, _):
            self = progress > 0 ? .proud : .curious
        case .goalCompleted:
            self = .celebrate
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
    var allowsIdleMotion = false
    var isPaused = false
    var heldType: ResistType?
    @State private var isVisible = false
    @State private var isPlaying = false
    @State private var motionStartedAt: Date?

    private var isActive: Bool {
        isVisible && motionEnabled && scenePhase == .active && !reduceMotion && !isPaused
    }

    private var playbackKey: MascotPlaybackKey {
        MascotPlaybackKey(reaction: reaction, token: reactionToken, isActive: isActive)
    }

    var body: some View {
        TimelineView(.animation(
            minimumInterval: isPlaying ? 1.0 / 30.0 : 0.1,
            paused: !isActive || (!isPlaying && !allowsIdleMotion)
        )) { context in
            let elapsed = motionStartedAt.map { context.date.timeIntervalSince($0) } ?? 0
            let pose = isActive && isPlaying ? reaction?.sample(at: elapsed) ?? .rest : .rest
            let blink = isActive && allowsIdleMotion && !isPlaying
                ? CGFloat(MascotMotionSample.blinkOpenness(at: context.date.timeIntervalSinceReferenceDate)) : 1

            ZStack {
                hands(pose: pose)

                DynamicMascotBody(wobble: CGFloat((1 - pose.scaleY) * 0.2), expression: expression)
                    .fill(color)
                    .overlay {
                        DynamicMascotBody(wobble: CGFloat((1 - pose.scaleY) * 0.2), expression: expression)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.07, lineJoin: .round))
                    }
                    .shadow(color: .punchBlack.opacity(0.18), radius: 0, x: 0, y: size * 0.05)

                eyes(blink: blink, pose: pose)
                brows(pose: pose)
                mouth(pose: pose)
                accessory(pose: pose)
                if let heldType {
                    TypeMascotPoseAccessory(
                        type: heldType, lift: CGFloat(pose.propLift),
                        squeeze: CGFloat(pose.propSqueeze), tilt: pose.propTilt
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
            .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(pose.tilt))
            .offset(y: size * pose.vertical)
        }
        .frame(width: size, height: size * 0.96)
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

    private func eyes(blink: CGFloat, pose: MascotMotionSample) -> some View {
        let restingClosure: Double = expression == .relieved ? 1 : 0
        return ZStack {
            eye(x: -size * 0.17, openness: min(blink, 1 - max(restingClosure, pose.leftClosure)), look: pose.gaze, lookY: pose.gazeY)
            eye(x: size * 0.17, openness: min(blink, 1 - max(restingClosure, pose.rightClosure)), look: pose.gaze, lookY: pose.gazeY)
        }
    }

    private func eye(x: CGFloat, openness: CGFloat, look: Double, lookY: Double) -> some View {
        Group {
            if openness < 0.2 {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: size * 0.025))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.17, y: size * 0.025),
                        control: CGPoint(x: size * 0.085, y: size * 0.09)
                    )
                }
                .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: size * 0.032, lineCap: .round))
                .frame(width: size * 0.17, height: size * 0.07)
            } else {
                ZStack {
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.17, height: size * 0.25 * openness)

                    Circle()
                        .fill(Color.punchBlack)
                        .frame(width: size * 0.055)
                        .offset(x: CGFloat(look) * size * 0.034, y: size * 0.03 * (openness + CGFloat(lookY)))
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
        case .hello, .relieved, .cooling, .observe: -8
        case .curious, .sparkle: -16
        case .thinking: 12
        case .proud, .celebrate: -6
        }
    }

    private var rightBrowRotation: CGFloat {
        switch expression {
        case .hello, .relieved, .cooling, .observe: 8
        case .curious, .sparkle: 16
        case .thinking: -12
        case .proud, .celebrate: 6
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
