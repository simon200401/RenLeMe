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
                    reduceMotion: reduceMotion
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

enum DynamicMascotExpression {
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
    let color: Color
    let expression: DynamicMascotExpression
    var size: CGFloat = 150
    var reduceMotion = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30.0)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            let phase = CGFloat(time.remainder(dividingBy: 10))
            let bounce = sin(phase * bodyTempo) * bodyBounce
            let blink = reduceMotion ? 1 : blinkProgress(phase)
            let look = lookOffset(phase)
            let tilt = reduceMotion ? 0 : sin(phase * tiltTempo) * tiltAmount

            ZStack {
                DynamicMascotBody(wobble: reduceMotion ? 0 : bounce, expression: expression)
                    .fill(color)
                    .overlay {
                        DynamicMascotBody(wobble: reduceMotion ? 0 : bounce, expression: expression)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.07, lineJoin: .round))
                    }
                    .shadow(color: .punchBlack.opacity(0.18), radius: 0, x: 0, y: size * 0.05)

                eyes(blink: blink, look: look)
                brows(phase: phase)
                mouth(phase: phase)
                accessory(phase: phase)
            }
            .frame(width: size, height: size * 0.96)
            .scaleEffect(y: 1 + (reduceMotion ? 0 : bounce * 0.5), anchor: .bottom)
            .rotationEffect(.degrees(tilt))
        }
        .frame(width: size, height: size * 0.96)
        .accessibilityLabel("动态小忍")
    }

    private var bodyTempo: CGFloat {
        switch expression {
        case .celebrate, .sparkle:
            3.4
        case .cooling, .relieved:
            1.35
        case .observe:
            1.7
        default:
            2.1
        }
    }

    private var bodyBounce: CGFloat {
        switch expression {
        case .celebrate:
            0.055
        case .sparkle:
            0.046
        case .cooling, .relieved:
            0.024
        default:
            0.035
        }
    }

    private var tiltTempo: CGFloat {
        switch expression {
        case .curious, .sparkle:
            1.7
        case .celebrate:
            2.8
        case .observe:
            1.1
        default:
            0
        }
    }

    private var tiltAmount: CGFloat {
        switch expression {
        case .curious, .sparkle:
            3
        case .celebrate:
            4.5
        case .observe:
            1.8
        default:
            0
        }
    }

    private func eyes(blink: CGFloat, look: CGFloat) -> some View {
        ZStack {
            eye(x: -size * 0.17, blink: blink, look: look)
            eye(x: size * 0.17, blink: blink, look: look)
        }
    }

    private func eye(x: CGFloat, blink: CGFloat, look: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.17, height: max(size * 0.035, size * 0.25 * blink))

            Circle()
                .fill(Color.punchBlack)
                .frame(width: size * 0.055)
                .offset(x: look * size * 0.034, y: size * 0.03 * blink)
                .opacity(blink < 0.25 ? 0 : 1)
        }
        .offset(x: x, y: -size * 0.12)
    }

    private func brows(phase: CGFloat) -> some View {
        ZStack {
            brow(x: -size * 0.18, rotation: leftBrowRotation + sin(phase * 1.7) * 2)
            brow(x: size * 0.18, rotation: rightBrowRotation - sin(phase * 1.4) * 2)
        }
    }

    private var leftBrowRotation: CGFloat {
        switch expression {
        case .hello, .relieved: -8
        case .curious, .sparkle: -16
        case .thinking, .cooling: 12
        case .proud, .celebrate: -6
        case .observe: 8
        }
    }

    private var rightBrowRotation: CGFloat {
        switch expression {
        case .hello, .relieved: 8
        case .curious, .sparkle: 16
        case .thinking, .cooling: -12
        case .proud, .celebrate: 6
        case .observe: -8
        }
    }

    private func brow(x: CGFloat, rotation: CGFloat) -> some View {
        Capsule()
            .fill(Color.punchBlack)
            .frame(width: size * 0.19, height: size * 0.045)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: -size * 0.285)
    }

    private func mouth(phase: CGFloat) -> some View {
        Path { path in
            let centerX = size * 0.5
            let centerY = size * 0.52
            switch expression {
            case .hello, .relieved:
                path.move(to: CGPoint(x: centerX - size * 0.16, y: centerY))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.16, y: centerY),
                    control: CGPoint(x: centerX, y: centerY + size * (0.18 + sin(phase * 2.2) * 0.018))
                )
            case .curious, .sparkle:
                path.addEllipse(in: CGRect(x: centerX - size * 0.055, y: centerY - size * 0.02, width: size * 0.11, height: size * 0.085))
            case .thinking, .cooling:
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
            case .observe:
                path.move(to: CGPoint(x: centerX - size * 0.13, y: centerY + size * 0.03))
                path.addLine(to: CGPoint(x: centerX + size * 0.13, y: centerY + size * 0.03))
            }
        }
        .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: size * 0.052, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size * 0.96)
    }

    @ViewBuilder
    private func accessory(phase: CGFloat) -> some View {
        switch expression {
        case .hello:
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.07, height: size * 0.24)
                .rotationEffect(.degrees(-28 + sin(phase * 4) * 12))
                .offset(x: size * 0.43, y: -size * 0.08)
        case .curious:
            Circle()
                .fill(Color.punchPink.opacity(0.45))
                .frame(width: size * 0.09)
                .offset(x: -size * 0.36, y: size * 0.12)
            Circle()
                .fill(Color.punchPink.opacity(0.45))
                .frame(width: size * 0.075)
                .offset(x: size * 0.36, y: size * 0.11)
        case .thinking, .cooling:
            Path { path in
                path.move(to: CGPoint(x: size * 0.76, y: size * 0.23))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.79, y: size * 0.50),
                    control: CGPoint(x: size * 0.94, y: size * 0.35)
                )
            }
            .stroke(Color.punchBlue, style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
            .frame(width: size, height: size)
        case .proud:
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.18, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .rotationEffect(.degrees(sin(phase * 2.4) * 12))
                .offset(x: size * 0.39, y: -size * 0.31)
        case .sparkle:
            Image(systemName: "questionmark")
                .font(.system(size: size * 0.17, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .rotationEffect(.degrees(sin(phase * 2.6) * 10))
                .offset(x: size * 0.38, y: -size * 0.30)
            Circle()
                .fill(Color.punchBlue.opacity(0.75))
                .frame(width: size * 0.08)
                .offset(x: -size * 0.39, y: -size * 0.24)
        case .celebrate:
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.23, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .scaleEffect(1 + sin(phase * 3) * 0.12)
                .rotationEffect(.degrees(sin(phase * 3.2) * 14))
                .offset(x: size * 0.40, y: -size * 0.32)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.15, weight: .black))
                .foregroundStyle(Color.white)
                .offset(x: -size * 0.38, y: -size * 0.26)
        case .observe:
            Circle()
                .fill(Color.punchPink.opacity(0.38))
                .frame(width: size * 0.08)
                .offset(x: -size * 0.34, y: size * 0.10)
            Circle()
                .fill(Color.punchPink.opacity(0.38))
                .frame(width: size * 0.08)
                .offset(x: size * 0.34, y: size * 0.10)
        case .relieved:
            Path { path in
                path.move(to: CGPoint(x: size * 0.25, y: size * 0.56))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.43, y: size * 0.56),
                    control: CGPoint(x: size * 0.34, y: size * 0.64)
                )
                path.move(to: CGPoint(x: size * 0.57, y: size * 0.56))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.75, y: size * 0.56),
                    control: CGPoint(x: size * 0.66, y: size * 0.64)
                )
            }
            .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
            .frame(width: size, height: size)
        }
    }

    private func blinkProgress(_ phase: CGFloat) -> CGFloat {
        let cycle = phase.truncatingRemainder(dividingBy: 3.2)
        if cycle < 0.08 {
            return max(0.12, cycle / 0.08)
        }
        if cycle < 0.16 {
            return max(0.12, (0.16 - cycle) / 0.08)
        }
        return 1
    }

    private func lookOffset(_ phase: CGFloat) -> CGFloat {
        switch expression {
        case .hello, .proud, .celebrate, .relieved:
            sin(phase * 1.1)
        case .curious, .sparkle:
            sin(phase * 1.8) * 1.4
        case .thinking, .cooling:
            -0.8 + sin(phase * 0.9) * 0.35
        case .observe:
            sin(phase * 0.7) * 0.45
        }
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
