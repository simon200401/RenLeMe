import SwiftData
import SwiftUI

extension ResistType {
    var urgeTitle: String {
        switch self {
        case .money: "想买"
        case .food: "想吃"
        case .time: "想玩"
        }
    }

    /// The move 小忍 makes when this kind of urge is resisted.
    var successReaction: MascotReaction {
        switch self {
        case .money: .stashWallet
        case .food: .pushCup
        case .time: .stopClock
        }
    }

    var urgeVerb: String {
        switch self {
        case .money: "买"
        case .food: "吃"
        case .time: "玩"
        }
    }

    var untitledRecordTitle: String {
        switch self {
        case .money: "想买的东西"
        case .food: "想吃的东西"
        case .time: "想玩一会儿"
        }
    }

    var savedValueQuestion: String {
        switch self {
        case .money: "省下多少钱"
        case .food: "守住多少热量"
        case .time: "拿回多少时间"
        }
    }

    var quickValues: [Double] {
        switch self {
        case .money: [20, 50, 100, 300]
        case .food: [200, 400, 600]
        case .time: [15, 30, 60, 120]
        }
    }

}

struct PauseFlowView: View {
    static let pauseSeconds: TimeInterval = 15
    private static let collapsedTemplateCount = 10
    private static let mascotCream = Color(red: 1.0, green: 0.949, blue: 0.839)

    private enum Stage {
        case pausing
        case deciding
        case value
        case goalPrompt
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]

    let type: ResistType

    @State private var stage: Stage = .pausing
    @State private var pauseStartedAt: Date?
    @State private var selectedTemplate: PropTemplate?
    @State private var isShowingAllTemplates = false
    @State private var isCustomSelected = false
    @State private var customTitle = ""
    @State private var valueText = ""
    @State private var selectedGoalId: UUID?
    @State private var reaction: MascotReaction?
    @State private var reactionToken = 0
    @State private var mascotTapCount = 0
    @State private var completionMoment: MascotMoment?
    @State private var completionMessage: String?
    @State private var completionReaction: MascotReaction?
    @State private var completionFace: DynamicMascotExpression?
    @State private var decidingFace: DynamicMascotExpression = .curious
    @State private var isHandlingTap = false
    @State private var saveFailed = false
    @State private var savedRecord: ResistRecord?
    @State private var shouldOfferGoal = false
    @State private var isAddingGoal = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isValueFocused: Bool

    /// Declining the invitation to make a goal is remembered for this kind of urge only.
    private var declinedGoalPromptKey: String {
        "didDeclineGoalPrompt.\(type.rawValue)"
    }

    private var filteredGoals: [Goal] {
        goals.active.filter { $0.type == type }
    }

    private var parsedValue: Double? {
        guard let value = Double(valueText.replacingOccurrences(of: ",", with: "")),
              value.isFinite, value > 0
        else { return nil }
        return value
    }

    private var recordTitle: String {
        if let selectedTemplate { return selectedTemplate.title }
        let trimmed = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return isCustomSelected && !trimmed.isEmpty ? trimmed : type.untitledRecordTitle
    }

    private var hasNamedItem: Bool {
        recordTitle != type.untitledRecordTitle
    }

    private var pauseForeground: Color {
        type == .time ? .punchBlack : .white
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
                .onTapGesture(perform: dismissInput)

            VStack(spacing: 0) {
                HStack {
                    Button("关闭") {
                        dismissInput()
                        // A quick wave goodbye before the sheet goes.
                        after(reduceMotion || completionMoment != nil || stage == .goalPrompt ? nil : .waveBye, delay: 0.4) {
                            dismiss()
                        }
                    }
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.softCream)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("pauseCloseButton")

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                ScrollView {
                    Group {
                        switch stage {
                        case .pausing: pausingStage
                        case .deciding: decidingStage
                        case .value: valueStage
                        case .goalPrompt: goalPromptStage
                        }
                    }
                    .padding(18)
                }
                .appScrollDefaults()
            }

            if let completionMoment {
                MascotFeedbackPopup(
                    moment: completionMoment,
                    message: completionMessage,
                    reaction: completionReaction,
                    face: completionFace,
                    heldType: completionReaction?.isPropInteraction == true ? type : nil
                ) {
                    finishCelebration()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .appKeyboardDismissal(onDismiss: dismissInput)
        .task(id: pauseStartedAt) {
            // The countdown only runs once the user has said what they want.
            guard stage == .pausing, let pauseStartedAt else { return }

            // Pulses swell through each inhale and stay quiet through the exhale.
            var step = 0
            while Double(step) * Self.hapticStep < Self.pauseSeconds {
                let offset = Double(step) * Self.hapticStep
                let wait = pauseStartedAt.addingTimeInterval(offset).timeIntervalSinceNow
                if wait > 0 {
                    do {
                        try await Task.sleep(for: .seconds(wait))
                    } catch {
                        return
                    }
                }
                guard stage == .pausing else { return }
                // A pulse that is already late (the app was in the background) is dropped, not replayed.
                if wait > -0.25, Self.isInhaling(at: offset) {
                    AppHaptics.breath(intensity: 0.35 + 0.65 * Self.breathLevel(at: offset + Self.hapticStep))
                }
                step += 1
            }

            let remaining = pauseStartedAt.addingTimeInterval(Self.pauseSeconds).timeIntervalSinceNow
            if remaining > 0 {
                do {
                    try await Task.sleep(for: .seconds(remaining))
                } catch {
                    return
                }
            }
            guard stage == .pausing else { return }
            AppHaptics.success()
            advance(to: .deciding)
            playReaction(.riseStretch)
        }
        .task(id: reactionToken) {
            guard let reaction else { return }
            do {
                try await Task.sleep(for: .seconds(reaction.duration))
            } catch {
                return
            }
            self.reaction = nil
        }
        .task(id: completionMoment) {
            guard completionMoment != nil else { return }
            do {
                try await Task.sleep(for: .seconds(1.6))
            } catch {
                return
            }
            finishCelebration()
        }
        .sheet(isPresented: $isAddingGoal) {
            NavigationStack {
                AddGoalView(initialType: type) { goal in
                    linkSavedRecord(to: goal)
                }
            }
        }
        .alert("保存失败，请重试", isPresented: $saveFailed) {
            Button("知道了", role: .cancel) {}
        }
    }

    private var background: Color {
        stage == .pausing ? Color.blockColor(for: type) : .appBackground
    }

    // MARK: - 暂停

    private var pausingStage: some View {
        let isCounting = pauseStartedAt != nil
        let ringSize: CGFloat = isCounting ? 264 : 220

        return VStack(spacing: 22) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isCounting)) { context in
                let elapsed = pauseStartedAt.map {
                    min(max(context.date.timeIntervalSince($0), 0), Self.pauseSeconds)
                } ?? 0
                let remaining = Int((Self.pauseSeconds - elapsed).rounded(.up))
                let breath = isCounting ? Self.breathLevel(at: elapsed) : 0
                let motion = reduceMotion ? 0 : CGFloat(breath)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(pauseForeground.opacity(isCounting ? 0.2 : 0))
                            .scaleEffect(0.7 + 0.24 * motion)
                        Circle()
                            .stroke(pauseForeground.opacity(0.28), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: elapsed / Self.pauseSeconds)
                            .stroke(pauseForeground, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Button(action: pokeMascot) {
                            AnimatedXiaoRenView(
                                color: Self.mascotCream,
                                expression: pauseExpression(elapsed: elapsed),
                                size: isCounting ? 150 : 132,
                                reduceMotion: reduceMotion,
                                reaction: reaction,
                                reactionToken: reactionToken,
                                allowsIdleMotion: true,
                                isPaused: isTitleFocused,
                                heldType: type
                            )
                            .frame(width: 180, height: 180)
                            .contentShape(Circle())
                        }
                        .buttonStyle(PressableScaleStyle())
                        .scaleEffect(0.94 + 0.1 * motion)
                        .accessibilityLabel("小忍")
                        .accessibilityHint("轻点和小忍互动")
                        .accessibilityIdentifier("pauseMascotButton")
                    }
                    .frame(width: ringSize, height: ringSize)
                    .overlay(alignment: .topTrailing) {
                        if isCounting {
                            speechBubble(pauseLine(elapsed: elapsed))
                                .offset(x: 18, y: -6)
                                .transition(.scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity))
                        }
                    }

                    Text("\(remaining)")
                        .font(.rounded(64, weight: .black))
                        .monospacedDigit()
                        .foregroundStyle(pauseForeground)
                        .contentTransition(.numericText(countsDown: true))
                        .accessibilityLabel("还剩 \(remaining) 秒")
                }
            }
            .padding(.top, isCounting ? 28 : 4)

            if !isCounting {
                itemChips
            } else {
                Text(recordTitle)
                    .font(.rounded(20, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Color.softCream)
                    .clipShape(Capsule())

                Button {
                    dismissInput()
                    advance(to: .deciding)
                } label: {
                    Text("不等了，现在决定")
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.punchBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
                .accessibilityIdentifier("skipPauseButton")
            }
        }
    }

    // MARK: - 小忍的话

    /// What 小忍 says during the countdown, so the number reads as time to think it over.
    private func pauseLine(elapsed: TimeInterval) -> String {
        switch elapsed {
        case ..<5: "想一下？"
        case ..<10: "真的要\(type.urgeVerb)吗"
        default: "快好了"
        }
    }

    private func speechBubble(_ text: String) -> some View {
        Text(text)
            .font(.rounded(16, weight: .black))
            .foregroundStyle(Color.punchBlack)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background(alignment: .bottomLeading) {
                // The tail points down toward 小忍.
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(45))
                    .offset(x: 16, y: 5)
            }
            .contentTransition(.opacity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: text)
            .accessibilityIdentifier("pauseSpeechBubble")
    }

    // MARK: - 呼吸节奏

    /// One breath is 5 seconds, so the 15-second pause is exactly three breaths.
    private static let breathSeconds: TimeInterval = 5
    private static let hapticStep: TimeInterval = 0.5

    private static func isInhaling(at elapsed: TimeInterval) -> Bool {
        elapsed.truncatingRemainder(dividingBy: breathSeconds) < breathSeconds / 2
    }

    /// 0 at the start of an inhale, 1 at full breath, back to 0 at the end of the exhale.
    private static func breathLevel(at elapsed: TimeInterval) -> Double {
        0.5 - 0.5 * cos(2 * .pi * elapsed / breathSeconds)
    }

    private var itemChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(type.urgeTitle)什么")
                .font(.rounded(24, weight: .black))
                .foregroundStyle(pauseForeground)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], alignment: .leading, spacing: 8) {
                customChip
                ForEach(visibleTemplates) { template in
                    chip(template.title, isSelected: false) {
                        selectTemplate(template)
                    }
                }
                if !isShowingAllTemplates, orderedTemplates.count > Self.collapsedTemplateCount {
                    Button {
                        AppHaptics.lightTap()
                        isShowingAllTemplates = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("更多")
                            Image(systemName: "chevron.down")
                        }
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(pauseForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay {
                            Capsule().stroke(pauseForeground, lineWidth: 2)
                        }
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityIdentifier("moreItemsChip")
                }
            }

            if isCustomSelected {
                AppTextField(placeholder: "叫什么", text: $customTitle, focus: $isTitleFocused)
                    .onSubmit(startCustomPause)

                if hasCustomTitle {
                    Button(action: startCustomPause) {
                        Text("开始")
                            .font(.rounded(18, weight: .black))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.punchBlack)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityIdentifier("startCustomPauseButton")
                }
            }
        }
    }

    /// Always first and inverted, so writing your own item never hides among the presets.
    private var customChip: some View {
        Button(action: toggleCustom) {
            HStack(spacing: 4) {
                Image(systemName: "pencil")
                Text("自填")
            }
            .font(.rounded(15, weight: .black))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.punchBlack)
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(Color.white, lineWidth: isCustomSelected ? 3 : 0)
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityAddTraits(isCustomSelected ? .isSelected : [])
        .accessibilityIdentifier("customItemChip")
    }

    private var orderedTemplates: [PropTemplate] {
        PropTemplate.templates(for: type, orderedByUsageIn: records)
    }

    private var visibleTemplates: [PropTemplate] {
        isShowingAllTemplates ? orderedTemplates : Array(orderedTemplates.prefix(Self.collapsedTemplateCount))
    }

    private var hasCustomTitle: Bool {
        !customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.rounded(15, weight: .black))
                .foregroundStyle(isSelected ? Color.white : .punchBlack)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? Color.punchBlack : .softCream)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func pauseExpression(elapsed: TimeInterval) -> DynamicMascotExpression {
        guard pauseStartedAt != nil else { return .craving }
        // The last out-breath is the moment the urge lets go.
        if elapsed >= Self.pauseSeconds - Self.breathSeconds / 2 { return .settled }
        return Self.isInhaling(at: elapsed) ? .inhale : .exhale
    }

    // MARK: - 决定

    private var decidingStage: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                AnimatedXiaoRenView(
                    color: type.v2MascotColor,
                    expression: decidingFace,
                    size: 84,
                    reduceMotion: reduceMotion,
                    reaction: reaction,
                    reactionToken: reactionToken,
                    allowsIdleMotion: true,
                    heldType: type
                )
                .frame(width: 96, height: 92)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("还想要吗")
                        .font(.rounded(34, weight: .black))
                        .foregroundStyle(Color.ink)

                    if hasNamedItem {
                        StatusChip(title: recordTitle, fill: Color.softBlockColor(for: type), foreground: .punchBlack)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .padding(.bottom, 6)

            decisionButton(
                "我忍住了", systemImage: "checkmark", fill: .punchBlack, foreground: .white,
                identifier: "decideResisted"
            ) {
                decidingFace = .proud
                after(.nod) {
                    valueText = selectedTemplate?.defaultValue?.cleanString ?? ""
                    selectedGoalId = StatsCalculator.suggestedGoalId(for: type, goals: goals, records: records)
                    advance(to: .value)
                }
            }

            decisionButton(
                "再等等", systemImage: "pause.fill", fill: .punchYellow, foreground: .punchBlack,
                trailing: type.cooldownDurationText, identifier: "decidePending"
            ) {
                decidingFace = .cheer
                after(.nod) {
                    save(.pending, value: selectedTemplate?.defaultValue)
                }
            }

            decisionButton(
                "我还是做了", systemImage: "eye.fill", fill: .cardBackground, foreground: .punchBlack,
                identifier: "decideGaveIn"
            ) {
                decidingFace = .settled
                after(.pat) {
                    save(.gaveIn, value: selectedTemplate?.defaultValue)
                }
            }
        }
    }

    private func decisionButton(
        _ title: String,
        systemImage: String,
        fill: Color,
        foreground: Color,
        trailing: String? = nil,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.rounded(18, weight: .black))
                Text(title)
                    .font(.rounded(20, weight: .black))
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.rounded(13, weight: .black))
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .punchBlack.opacity(0.14), radius: 0, x: 0, y: 6)
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityIdentifier(identifier)
    }

    // MARK: - 忍住后补数值

    private var valueStage: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AnimatedXiaoRenView(
                    color: .punchGreen,
                    expression: isBigValue ? .surprised : .proud,
                    size: 84,
                    reduceMotion: reduceMotion,
                    reaction: reaction,
                    reactionToken: reactionToken,
                    allowsIdleMotion: true,
                    isPaused: isValueFocused
                )
                .frame(width: 96, height: 92)
                .accessibilityHidden(true)

                Text(type.savedValueQuestion)
                    .font(.rounded(30, weight: .black))
                    .foregroundStyle(Color.ink)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(type.quickValues, id: \.self) { value in
                    chip(value.displayValue(for: type), isSelected: parsedValue == value) {
                        dismissInput()
                        valueText = value.cleanString
                        AppHaptics.lightTap()
                    }
                }
            }

            if let selectedTemplate, let defaultValue = selectedTemplate.defaultValue {
                Text("\(selectedTemplate.caption) ≈ \(defaultValue.displayValue(for: type))")
                    .font(.rounded(14, weight: .black))
                    .foregroundStyle(Color.secondaryInk)
                    .accessibilityIdentifier("defaultServingText")
            }

            AppTextField(
                placeholder: "\(type.valueTitle) · \(unitText)",
                text: $valueText,
                keyboardType: .decimalPad,
                focus: $isValueFocused
            )
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            if !filteredGoals.isEmpty {
                GoalMenuRow(goals: filteredGoals, selection: $selectedGoalId, labelColor: .fieldLabelInk, fill: .cardBackground)
            }

            Button {
                save(.resisted, value: parsedValue)
            } label: {
                Text(parsedValue == nil ? "先不填" : "保存")
                    .font(.rounded(18, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.punchBlack)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityIdentifier("saveResistedButton")
        }
    }

    // MARK: - 忍住后给成果找个去处

    private var goalPromptStage: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AnimatedXiaoRenView(
                    color: .punchGreen,
                    expression: .settled,
                    size: 84,
                    reduceMotion: reduceMotion,
                    allowsIdleMotion: true
                )
                .frame(width: 96, height: 92)
                .accessibilityHidden(true)

                Text("把这 \(savedRecord?.displayValueText ?? "") 存进一个目标")
                    .font(.rounded(26, weight: .black))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            Button {
                isAddingGoal = true
            } label: {
                Text("新建目标")
                    .font(.rounded(18, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.punchBlack)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityIdentifier("goalPromptCreateButton")

            Button {
                // Asked once; the home screen keeps a quiet slot for later.
                UserDefaults.standard.set(true, forKey: declinedGoalPromptKey)
                dismiss()
            } label: {
                Text("以后再说")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.secondaryInk)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityIdentifier("goalPromptLaterButton")
        }
    }

    private func finishCelebration() {
        guard shouldOfferGoal else {
            dismiss()
            return
        }
        shouldOfferGoal = false
        completionMoment = nil
        advance(to: .goalPrompt)
    }

    private func linkSavedRecord(to goal: Goal) {
        if let savedRecord, savedRecord.type == goal.type {
            savedRecord.goalId = goal.id
            try? modelContext.save()
        }
        dismiss()
    }

    /// Big enough to make 小忍's eyes go wide.
    private var isBigValue: Bool {
        guard let parsedValue else { return false }
        return switch type {
        case .money: parsedValue >= 1000
        case .food: parsedValue >= 1500
        case .time: parsedValue >= 180
        }
    }

    /// Lets 小忍 react to a tap for a beat before the tap takes effect.
    private func after(_ reaction: MascotReaction?, delay: Double = 0.45, perform action: @escaping () -> Void) {
        guard !isHandlingTap else { return }
        guard let reaction, !reduceMotion else {
            action()
            return
        }
        isHandlingTap = true
        playReaction(reaction)
        Task {
            try? await Task.sleep(for: .seconds(delay))
            isHandlingTap = false
            action()
        }
    }

    private var unitText: String {
        switch type {
        case .money: "¥"
        case .food: "kcal"
        case .time: "分钟"
        }
    }

    // MARK: - 动作

    private func advance(to next: Stage) {
        if reduceMotion {
            stage = next
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                stage = next
            }
        }
    }

    private func pokeMascot() {
        guard reaction == nil else { return }
        let reactions: [MascotReaction] = [.shy, type.selectionReaction, .headTilt, .wink]
        playReaction(reactions[mascotTapCount % reactions.count])
        mascotTapCount += 1
        AppHaptics.lightTap()
    }

    private func playReaction(_ next: MascotReaction) {
        guard !reduceMotion else { return }
        reaction = next
        reactionToken += 1
    }

    private func selectTemplate(_ template: PropTemplate) {
        isCustomSelected = false
        selectedTemplate = template
        startCountdown()
    }

    private func toggleCustom() {
        selectedTemplate = nil
        isCustomSelected.toggle()
        if isCustomSelected {
            isTitleFocused = true
        } else {
            dismissInput()
        }
        AppHaptics.lightTap()
    }

    private func startCustomPause() {
        guard hasCustomTitle, pauseStartedAt == nil else { return }
        startCountdown()
    }

    private func startCountdown() {
        dismissInput()
        AppHaptics.lightTap()
        if reduceMotion {
            pauseStartedAt = Date()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                pauseStartedAt = Date()
            }
        }
        playReaction(type.selectionReaction)
    }

    private func dismissInput() {
        isTitleFocused = false
        isValueFocused = false
        UIApplication.shared.dismissKeyboard()
    }

    private func save(_ status: ResistStatus, value: Double?) {
        dismissInput()
        guard completionMoment == nil else { return }

        let estimate = value.flatMap { $0 > 0 ? $0 : nil }
        // Something put in the cooldown box is already pointed at the goal being saved towards, so
        // it counts there if it is resisted later. It only ever counts once it is resisted.
        let goalId = status == .resisted
            ? selectedGoalId
            : status == .pending ? StatsCalculator.suggestedGoalId(for: type, goals: goals, records: records) : nil
        let goal = filteredGoals.first { $0.id == goalId }
        let ledgerBeforeSave = GoalLedger(goals: goals, records: records)
        let growthCountBeforeSave = MascotGrowth(records: records).resistedCount
        let cooldownUntil = status == .pending ? Date().addingTimeInterval(type.cooldownSeconds) : nil

        let record = ResistRecord(
            type: type,
            title: recordTitle,
            value: estimate ?? 0,
            hasEstimatedValue: estimate != nil,
            status: status,
            reason: "",
            resolvedAt: status == .pending ? nil : Date(),
            cooldownUntil: cooldownUntil,
            enteredCooldown: status == .pending,
            goalId: goal?.id,
            propTemplateId: selectedTemplate?.id,
            propIconKey: selectedTemplate?.iconKey ?? PropTemplate.customFallbackTemplate(for: type).iconKey
        )

        modelContext.insert(record)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveFailed = true
            return
        }

        if status == .pending {
            CooldownCoordinator.schedule(for: record)
        }

        savedRecord = record
        shouldOfferGoal = status == .resisted && estimate != nil && filteredGoals.isEmpty
            && !UserDefaults.standard.bool(forKey: declinedGoalPromptKey)

        if status == .resisted {
            AppHaptics.success()
        } else {
            AppHaptics.lightTap()
        }

        let grownStage = status == .resisted
            ? MascotGrowth(resistedCount: growthCountBeforeSave + 1).stage
            : nil

        completionReaction = status == .resisted ? type.successReaction : nil
        completionFace = nil

        if let grownStage, grownStage != MascotGrowth(resistedCount: growthCountBeforeSave).stage {
            completionMessage = "小忍长大了 · \(grownStage.title)"
            completionReaction = .levelUp
            completionFace = .surprised
        } else if status == .resisted, let goal, estimate != nil {
            let ledger = GoalLedger(goals: goals, records: records.filter { $0.id != record.id } + [record])
            let remaining = ledger.remaining(for: goal)
            // What went past this goal's target shows up as a gain on another goal of the same kind.
            let next = filteredGoals
                .filter { $0.id != goal.id }
                .map { ($0, ledger.value(for: $0) - ledgerBeforeSave.value(for: $0)) }
                .first { $0.1 > 0 }
            if remaining > 0 {
                completionMessage = "「\(goal.title)」还差 \(remaining.displayValue(for: type))"
            } else if let next {
                completionMessage = "「\(goal.title)」完成了，多出的 \(next.1.displayValue(for: type)) 进了「\(next.0.title)」"
            } else {
                completionMessage = "「\(goal.title)」完成了"
            }
        } else {
            completionMessage = nil
        }

        let moment: MascotMoment = switch status {
        case .resisted: .resistedSuccess
        case .pending: .coolingSaved
        case .gaveIn: .gaveInSaved
        }
        if reduceMotion {
            completionMoment = moment
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                completionMoment = moment
            }
        }
    }
}
