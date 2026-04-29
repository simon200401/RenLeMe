import SwiftUI

private enum WelcomeOnboardingStep: Int, CaseIterable {
    case welcome
    case record
    case decide
    case review

    var title: String {
        switch self {
        case .welcome:
            "欢迎来到忍了么"
        case .record:
            "先记下来"
        case .decide:
            "不急着决定"
        case .review:
            "把忍住变成资产"
        }
    }

    var message: String {
        switch self {
        case .welcome:
            "小忍会陪你看见冲动，不批评，也不催你。"
        case .record:
            "遇到想买、想吃、想刷的时候，先选类型和具体道具。"
        case .decide:
            "你可以选择忍住、放进冷静箱，或者温柔地记录这次观察。"
        case .review:
            "省下的钱、热量和时间都会被看见，慢慢长成你的忍耐资产。"
        }
    }

    var buttonTitle: String {
        self == .review ? "开始使用" : "下一步"
    }

    var mascotColor: Color {
        switch self {
        case .welcome:
            .punchGreen
        case .record:
            .punchPink
        case .decide:
            .punchYellow
        case .review:
            Color(red: 1.0, green: 0.949, blue: 0.839)
        }
    }

    var expression: DynamicMascotExpression {
        switch self {
        case .welcome:
            .hello
        case .record:
            .curious
        case .decide:
            .thinking
        case .review:
            .proud
        }
    }

    var accentText: String {
        switch self {
        case .welcome:
            "看见冲动"
        case .record:
            "记录一下"
        case .decide:
            "拿回选择权"
        case .review:
            "温柔复盘"
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
            VStack(spacing: 18) {
                AnimatedXiaoRenView(
                    color: selectedStep.mascotColor,
                    expression: selectedStep.expression,
                    size: 156,
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

                Text(selectedStep.accentText)
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(selectedStep == .decide ? Color.punchBlack : Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(selectedStep.mascotColor)
                    .clipShape(Capsule())
            }
        }
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
                    if selectedStep == .review {
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
            let bounce = sin(phase * 2.1) * 0.035
            let blink = reduceMotion ? 1 : blinkProgress(phase)
            let look = lookOffset(phase)

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
        }
        .frame(width: size, height: size * 0.96)
        .accessibilityLabel("动态小忍")
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
        case .hello: -8
        case .curious: -16
        case .thinking: 12
        case .proud: -6
        }
    }

    private var rightBrowRotation: CGFloat {
        switch expression {
        case .hello: 8
        case .curious: 16
        case .thinking: -12
        case .proud: 6
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
            case .hello:
                path.move(to: CGPoint(x: centerX - size * 0.16, y: centerY))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.16, y: centerY),
                    control: CGPoint(x: centerX, y: centerY + size * (0.18 + sin(phase * 2.2) * 0.018))
                )
            case .curious:
                path.addEllipse(in: CGRect(x: centerX - size * 0.055, y: centerY - size * 0.02, width: size * 0.11, height: size * 0.085))
            case .thinking:
                path.move(to: CGPoint(x: centerX - size * 0.13, y: centerY + size * 0.04))
                path.addQuadCurve(
                    to: CGPoint(x: centerX + size * 0.13, y: centerY + size * 0.04),
                    control: CGPoint(x: centerX - size * 0.02, y: centerY - size * 0.06)
                )
            case .proud:
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
        case .proud:
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.18, weight: .black))
                .foregroundStyle(Color.punchYellow)
                .rotationEffect(.degrees(sin(phase * 2.4) * 12))
                .offset(x: size * 0.39, y: -size * 0.31)
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
        case .hello, .proud:
            sin(phase * 1.1)
        case .curious:
            sin(phase * 1.8) * 1.4
        case .thinking:
            -0.8 + sin(phase * 0.9) * 0.35
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
        let lift = expression == .proud ? -h * 0.025 : 0

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
