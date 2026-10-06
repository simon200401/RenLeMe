import SwiftUI

/// The level ladder shown from the home screen. Stages beyond the next one keep their name hidden,
/// but every threshold is visible so the length of the road is never a secret.
struct GrowthLadderView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let growth: MascotGrowth

    @State private var reaction: MascotReaction?
    @State private var reactionToken = 0
    @State private var tapCount = 0

    private enum StageState {
        case reached
        case current
        case next
        case locked
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header
                    .padding(.bottom, 6)

                ForEach(Array(MascotGrowth.stages.enumerated()), id: \.offset) { index, stage in
                    row(index: index, stage: stage)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.appBackground.ignoresSafeArea())
        .task(id: reactionToken) {
            guard let reaction else { return }
            do {
                try await Task.sleep(for: .seconds(reaction.duration))
            } catch {
                return
            }
            self.reaction = nil
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                guard reaction == nil, !reduceMotion else { return }
                let reactions: [MascotReaction] = [.celebrate, .wink, .shy]
                reaction = reactions[tapCount % reactions.count]
                tapCount += 1
                reactionToken += 1
                AppHaptics.lightTap()
            } label: {
                AnimatedXiaoRenView(
                    color: .punchGreen,
                    expression: .proud,
                    size: 70,
                    reduceMotion: reduceMotion,
                    reaction: reaction,
                    reactionToken: reactionToken,
                    allowsIdleMotion: true
                )
                .frame(width: 80, height: 76)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("小忍")

            VStack(alignment: .leading, spacing: 4) {
                Text("小忍的成长")
                    .font(.rounded(28, weight: .black))
                    .foregroundStyle(Color.ink)

                Text("已忍住 \(growth.resistedCount) 次")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.secondaryInk)
            }

            Spacer(minLength: 0)
        }
    }

    private func state(for index: Int) -> StageState {
        let currentIndex = growth.level - 1
        if index < currentIndex { return .reached }
        if index == currentIndex { return .current }
        return index == currentIndex + 1 ? .next : .locked
    }

    private func row(index: Int, stage: MascotGrowth.Stage) -> some View {
        let state = state(for: index)
        let isCurrent = state == .current
        let isLocked = state == .locked

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: iconName(for: stage, state: state))
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(isLocked ? Color.secondaryInk : .punchBlack)
                    .frame(width: 36, height: 36)
                    .background(iconFill(for: state))
                    .clipShape(Circle())

                Text(isLocked ? "Lv.\(index + 1) ？？" : "Lv.\(index + 1) \(stage.title)")
                    .font(.rounded(17, weight: .black))
                    .foregroundStyle(isCurrent ? Color.white : (isLocked ? .secondaryInk : .ink))

                Spacer(minLength: 8)

                Text(trailingText(for: stage, state: state))
                    .font(.rounded(13, weight: .black))
                    .foregroundStyle(isCurrent ? Color.white : .secondaryInk)
            }

            if isCurrent, growth.nextStage != nil {
                ProgressLine(progress: growth.progressToNextStage, tint: .punchGreen)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(rowFill(for: state))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText(index: index, stage: stage, state: state))
    }

    private func iconName(for stage: MascotGrowth.Stage, state: StageState) -> String {
        switch state {
        case .locked: "lock.fill"
        case .reached: "checkmark"
        case .current, .next: stage.symbolName ?? "hand.wave.fill"
        }
    }

    private func iconFill(for state: StageState) -> Color {
        switch state {
        case .reached: Color.punchBlack.opacity(0.08)
        case .current: .punchYellow
        case .next: Color.softBlockColor(for: .food)
        case .locked: Color.punchBlack.opacity(0.08)
        }
    }

    private func rowFill(for state: StageState) -> Color {
        switch state {
        case .reached, .next: .cardBackground
        case .current: .punchBlack
        case .locked: Color.punchBlack.opacity(0.05)
        }
    }

    private func trailingText(for stage: MascotGrowth.Stage, state: StageState) -> String {
        switch state {
        case .current: growth.nextStage == nil ? "已满级" : "现在"
        case .next: "再忍 \(stage.threshold - growth.resistedCount) 次"
        case .reached, .locked: "\(stage.threshold) 次"
        }
    }

    private func accessibilityText(index: Int, stage: MascotGrowth.Stage, state: StageState) -> String {
        switch state {
        case .reached: "第 \(index + 1) 级 \(stage.title)，已达到"
        case .current: "第 \(index + 1) 级 \(stage.title)，当前等级"
        case .next: "第 \(index + 1) 级 \(stage.title)，再忍 \(stage.threshold - growth.resistedCount) 次"
        case .locked: "第 \(index + 1) 级，未解锁，需要忍住 \(stage.threshold) 次"
        }
    }
}
