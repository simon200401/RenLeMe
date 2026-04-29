import SwiftUI

struct LaunchSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onFinish: () -> Void

    @State private var mascotScale: CGFloat = 0.84
    @State private var titleLift: CGFloat = 16
    @State private var dotsPhase = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 58, style: .continuous)
                        .fill(Color.cream)
                        .frame(width: 218, height: 218)
                        .shadow(color: .punchBlack.opacity(0.14), radius: 0, x: 0, y: 10)

                    AnimatedXiaoRenView(
                        color: .punchGreen,
                        expression: .hello,
                        size: 152,
                        reduceMotion: reduceMotion
                    )
                    .scaleEffect(mascotScale)
                }

                VStack(spacing: 8) {
                    Text("忍了么")
                        .font(.rounded(44, weight: .black))
                        .foregroundStyle(Color.punchBlack)

                    Text("忍一下")
                        .font(.rounded(18, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                }
                .offset(y: titleLift)
                .opacity(titleLift == 0 ? 1 : 0)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(dotColor(index))
                            .frame(width: 10, height: 10)
                            .scaleEffect(dotsPhase == index && !reduceMotion ? 1.35 : 1)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("忍了么，先暂停一下")
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        if reduceMotion {
            mascotScale = 1
            titleLift = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                onFinish()
            }
            return
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
            mascotScale = 1
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(0.12)) {
            titleLift = 0
        }

        let dotTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { _ in
            dotsPhase = (dotsPhase + 1) % 3
        }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            dotTimer.invalidate()
            onFinish()
        }
    }

    private func dotColor(_ index: Int) -> Color {
        switch index {
        case 0: return .punchYellow
        case 1: return .punchGreen
        default: return .punchPink
        }
    }
}

#Preview {
    LaunchSplashView {}
}
