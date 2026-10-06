import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mascotMotionEnabled) private var motionEnabled
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]

    @State private var isAddingGoal = false
    @State private var isShowingGrowth = false
    @State private var openedPending: ResistRecord?
    @State private var heroFace: DynamicMascotExpression?
    @State private var heroEntered = false
    @State private var overrideFace: DynamicMascotExpression?
    @State private var overrideToken = 0
    @State private var pokeCount = 0
    @State private var lastPokeAt = Date.distantPast
    @State private var isSulking = false
    @State private var stretch = CGSize.zero
    @State private var speech: String?
    @State private var speechToken = 0
    @State private var lastSeenRecordId: UUID?
    @State private var lastSeenRecordCount = 0
    @State private var lastSeenLevel = 1
    /// Yawning or asleep; sits under any momentary face.
    @State private var restFace: DynamicMascotExpression?
    @State private var restToken = 0
    @State private var tileFaces: [ResistType: DynamicMascotExpression] = [:]
    @State private var hasGreeted = false
    @State private var greeting: MascotReaction?
    @State private var mascotReaction: MascotReaction?
    @State private var mascotReactionToken = 0
    @State private var mascotTapCount = 0

    /// Content height shared by the slim rows under the main card, so they line up.
    static let slimRowHeight: CGFloat = 44

    let onPause: (ResistType) -> Void
    let onDirectRecord: () -> Void
    let onShowResults: () -> Void

    private var weekAssets: AssetSummary {
        StatsCalculator.assets(from: records, period: .week)
    }

    private var todayCount: Int {
        StatsCalculator.resistedToday(in: records)
    }

    private var pendingRecords: [ResistRecord] {
        records
            .filter { $0.status == .pending }
            .sorted {
                ($0.cooldownUntil ?? .distantFuture) < ($1.cooldownUntil ?? .distantFuture)
            }
    }

    private var growth: MascotGrowth {
        MascotGrowth(records: records)
    }

    private var nearestGoal: Goal? {
        StatsCalculator.nearestUnfinishedGoal(in: goals, records: records)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    pendingSection
                    goalSection
                    weekSummary
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .appScrollDefaults()
            // The ground line stays in view above the tab bar, however long the page gets.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SlidingPeekMascot(records: records)
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
                    .background(Color.appBackground)
            }
        }
        .navigationTitle("忍了么")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: motionEnabled) {
            guard motionEnabled else { return }
            if !hasGreeted {
                // First sight after launch: 小忍 pops in, waves, and says something.
                hasGreeted = true
                lastSeenRecordId = records.first?.id
                lastSeenRecordCount = records.count
                lastSeenLevel = growth.level
                if reduceMotion {
                    heroEntered = true
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
                        heroEntered = true
                    }
                }
                say(mascotContext.line)
                greeting = .greeting
                defer { greeting = nil }
                try? await Task.sleep(for: .seconds(MascotReaction.greeting.duration))
            } else if let newest = records.first, newest.id != lastSeenRecordId, records.count > lastSeenRecordCount {
                // Back from recording something: react to what just happened.
                lastSeenRecordId = newest.id
                lastSeenRecordCount = records.count
                refreshFaces()
                if growth.level > lastSeenLevel {
                    lastSeenLevel = growth.level
                    overrideFace = .surprised
                    overrideToken += 1
                    play(.levelUp)
                    say("我长大了！")
                } else {
                    switch newest.status {
                    case .resisted: say("也就…还不错嘛")
                    case .pending: say("我帮你记着呢")
                    case .gaveIn: say("没事啦，下次再说")
                    }
                }
            } else {
                // Nothing new was added (a record may have been deleted); just keep the baseline current.
                lastSeenRecordId = records.first?.id
                lastSeenRecordCount = records.count
            }
        }
        .task(id: restToken) {
            // Left alone long enough, 小忍 yawns and nods off. Late at night that happens quickly.
            guard motionEnabled, !reduceMotion else { return }
            let hour = Calendar.current.component(.hour, from: Date())
            let isLate = hour >= 23 || hour < 6
            do {
                try await Task.sleep(for: .seconds(isLate ? 6 : 25))
                guard !isSulking, overrideFace == nil else { return }
                restFace = .yawn
                play(.timeStretch)
                try await Task.sleep(for: .seconds(1.5))
                restFace = .asleep
            } catch {
                return
            }
        }
        .task(id: "\(motionEnabled)-\(pendingRecords.isEmpty)") {
            // With something waiting in the cooldown box, 小忍 paces and checks the time.
            guard motionEnabled, !reduceMotion, !pendingRecords.isEmpty else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(7))
                } catch {
                    return
                }
                if restFace == nil, overrideFace == nil, mascotReaction == nil, greeting == nil, stretch == .zero {
                    play(.pace)
                }
            }
        }
        .task(id: mascotReactionToken) {
            guard let mascotReaction else { return }
            do {
                try await Task.sleep(for: .seconds(mascotReaction.duration))
            } catch {
                return
            }
            self.mascotReaction = nil
        }
        .task(id: speechToken) {
            guard speech != nil else { return }
            do {
                try await Task.sleep(for: .seconds(2.8))
            } catch {
                return
            }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                speech = nil
            }
        }
        .task(id: overrideToken) {
            guard overrideFace != nil else { return }
            do {
                try await Task.sleep(for: .seconds(isSulking ? 3 : 1.8))
            } catch {
                return
            }
            if isSulking {
                // Comes round on its own.
                isSulking = false
                pokeCount = 0
                overrideFace = nil
                play(.shy)
                say("…好吧，原谅你")
            } else {
                overrideFace = nil
            }
        }
        .onChange(of: motionEnabled) { _, enabled in
            if !enabled { mascotReaction = nil }
            wake()
        }
        .onDisappear { mascotReaction = nil }
        .onAppear(perform: refreshFaces)
        .navigationDestination(item: $openedPending) { record in
            RecordDetailView(record: record)
        }
        .sheet(isPresented: $isShowingGrowth) {
            GrowthLadderView(growth: growth)
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isAddingGoal) {
            NavigationStack {
                AddGoalView()
            }
        }
    }

    private var hero: some View {
        heroCard
            .overlay(alignment: .topTrailing) {
                if let speech {
                    MascotSpeechBubble(text: speech)
                        .padding(.trailing, 30)
                        // Sits across the card's top edge, above 小忍's head.
                        .offset(y: -26)
                        .transition(.scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity))
                        .accessibilityIdentifier("homeSpeechBubble")
                }
            }
    }

    private var heroCard: some View {
        PunchyCard(fill: .cream, cornerRadius: 34, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                statusRow

                HStack(alignment: .firstTextBaseline) {
                    Text("忍一下")
                        .font(.rounded(26, weight: .black))
                        .foregroundStyle(Color.punchBlack)

                    Spacer()

                    Button(action: onDirectRecord) {
                        HStack(spacing: 4) {
                            Text("直接记录")
                            Image(systemName: "chevron.right")
                        }
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityIdentifier("directRecordButton")
                }

                HStack(spacing: 10) {
                    ForEach(ResistType.allCases) { type in
                        Button {
                            AppHaptics.lightTap()
                            onPause(type)
                        } label: {
                            VStack(spacing: 8) {
                                TypeMascotBadge(type: type, size: 58, face: tileFaces[type])
                                Text(type.urgeTitle)
                                    .font(.rounded(17, weight: .black))
                                    .foregroundStyle(Color.punchBlack)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.softBlockColor(for: type))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .punchBlack.opacity(0.14), radius: 0, x: 0, y: 5)
                        }
                        .buttonStyle(PressableScaleStyle())
                        .accessibilityLabel("\(type.urgeTitle)，开始暂停 15 秒")
                        .accessibilityIdentifier("pauseType-\(type.rawValue)")
                    }
                }
            }
        }
    }

    private var statusRow: some View {
        HStack(alignment: .center) {
            // The whole status block opens the level ladder, not just the small chip.
            Button {
                AppHaptics.lightTap()
                isShowingGrowth = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today: \(todayCount) 次")
                        .font(.rounded(30, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: todayCount)

                    HStack(spacing: 8) {
                        StatusChip(title: "Lv.\(growth.level) \(growth.stage.title)", fill: .punchBlack)

                        if let remaining = growth.remainingToNextStage {
                            Text("再忍 \(remaining) 次")
                                .font(.rounded(13, weight: .black))
                                .foregroundStyle(Color.secondaryInk)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableScaleStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("查看小忍的等级")
            .accessibilityIdentifier("mascotGrowthRow")

            Button(action: greetMascot) {
                AnimatedXiaoRenView(
                    color: todayCount > 0 ? Color.punchGreen : Color(red: 1.0, green: 0.949, blue: 0.839),
                    expression: heroExpression,
                    size: 72,
                    reduceMotion: reduceMotion,
                    reaction: mascotReaction ?? greeting,
                    reactionToken: mascotReactionToken,
                    allowsIdleMotion: true
                )
                .frame(width: 80, height: 80)
                .contentShape(Rectangle())
                .overlay(alignment: .topLeading) {
                    if let symbolName = growth.stage.symbolName {
                        Image(systemName: symbolName)
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .frame(width: 28, height: 28)
                            .background(Color.punchYellow)
                            .clipShape(Circle())
                            .overlay { Circle().stroke(Color.white, lineWidth: 3) }
                            .offset(x: -8, y: -6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.55), value: growth.level)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(heroEntered ? 1 : 0.2)
            .scaleEffect(
                x: 1 + min(abs(stretch.width) / 150, 0.5),
                y: 1 + min(abs(stretch.height) / 150, 0.5)
            )
            .offset(x: stretch.width * 0.3, y: stretch.height * 0.3)
            .highPriorityGesture(stretchGesture)
            .accessibilityLabel("小忍")
            .accessibilityHint("轻点和小忍打个招呼，按住可以拉一拉")
            .accessibilityIdentifier("homeMascotButton")
        }
    }

    private var heroExpression: DynamicMascotExpression {
        if let overrideFace { return overrideFace }
        if let restFace { return restFace }
        return switch mascotReaction {
        case .some(.shy): .observe
        case .some(.headTilt): .curious
        default: heroFace ?? (todayCount > 0 ? .proud : .hello)
        }
    }

    // MARK: - 小忍记得发生过什么

    private struct MascotContext {
        let faces: [DynamicMascotExpression]
        let line: String
    }

    /// What 小忍 looks like and says on arrival, from what happened most recently.
    private var mascotContext: MascotContext {
        let now = Date()
        let decided = records
            .filter { $0.status != .pending }
            .sorted { ($0.resolvedAt ?? $0.createdAt) > ($1.resolvedAt ?? $1.createdAt) }

        if pendingRecords.contains(where: { ($0.cooldownUntil ?? .distantFuture) <= now }) {
            return MascotContext(faces: [.cooling], line: "有件事可以决定了")
        }
        if let nearestGoal,
           StatsCalculator.currentValue(for: nearestGoal, records: records) / max(nearestGoal.targetValue, 1) >= 0.9 {
            return MascotContext(faces: [.heartEyes], line: "「\(nearestGoal.title)」就差一点了")
        }
        if let last = decided.first, last.status == .gaveIn,
           now.timeIntervalSince(last.resolvedAt ?? last.createdAt) < 86_400 {
            return MascotContext(faces: [.settled, .lookAway], line: "没事啦，下次再说")
        }
        let streak = decided.prefix { $0.status == .resisted }.count
        if streak >= 3 {
            return MascotContext(faces: [.proud, .celebrate], line: "连着忍住 \(streak) 次，还行嘛")
        }
        if let newest = records.first, now.timeIntervalSince(newest.createdAt) > 3 * 86_400 {
            return MascotContext(faces: [.touched, .hello], line: "回来啦，我一直在这儿")
        }
        if !pendingRecords.isEmpty {
            return MascotContext(faces: [.cheer, .cooling], line: "冷静箱里的，我陪你等")
        }
        if todayCount > 0 {
            return MascotContext(faces: [.proud, .celebrate, .settled, .sparkle], line: "今天状态不错嘛")
        }
        return MascotContext(faces: [.hello, .curious, .relieved, .settled], line: "来啦？才没有在等你")
    }

    /// Called every time the screen comes into view, so no two visits look the same.
    private func refreshFaces() {
        heroFace = MascotVariety.next(from: mascotContext.faces, avoiding: [heroFace])
        wake()
        tileFaces = MascotVariety.distinctFaces(previous: tileFaces, pool: MascotVariety.typeBadgePool)
    }

    // MARK: - 戳、拉、说话

    /// Any attention wakes 小忍 and restarts the wait before it dozes off again.
    private func wake() {
        restFace = nil
        restToken += 1
    }

    private func say(_ line: String) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
            speech = line
        }
        speechToken += 1
    }

    private func play(_ reaction: MascotReaction) {
        guard !reduceMotion else { return }
        mascotReaction = reaction
        mascotReactionToken += 1
    }

    /// A poke or two gets a friendly reaction; keep going and 小忍 gets dizzy, then turns its back.
    private func greetMascot() {
        guard motionEnabled, greeting == nil, !isSulking else { return }
        AppHaptics.lightTap()

        if restFace == .asleep {
            // Woken with a start; this one does not count as a poke.
            wake()
            overrideFace = .startled
            overrideToken += 1
            play(.startle)
            say("哇！")
            return
        }
        wake()

        let now = Date()
        if now.timeIntervalSince(lastPokeAt) > 4 { pokeCount = 0 }
        lastPokeAt = now
        pokeCount += 1

        switch pokeCount {
        case ..<5:
            guard mascotReaction == nil else { return }
            let reactions: [MascotReaction] = [.shy, .headTilt, .wink, .shy]
            play(reactions[(pokeCount - 1) % reactions.count])
            if pokeCount == 4 {
                // Enjoying the attention, just before it becomes too much.
                overrideFace = .heartEyes
                overrideToken += 1
            }
        case 5..<10:
            overrideFace = .dizzy
            overrideToken += 1
            play(.dizzy)
            if pokeCount == 5 { say("别戳了…晕") }
        default:
            isSulking = true
            mascotReaction = nil
            overrideFace = .sulk
            overrideToken += 1
            say("哼")
        }
    }

    /// Drag 小忍 and it stretches like dough, then snaps back.
    private var stretchGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard motionEnabled, !isSulking else { return }
                if stretch == .zero {
                    AppHaptics.lightTap()
                    wake()
                    overrideFace = .observe
                    say("诶诶诶——")
                }
                stretch = CGSize(
                    width: min(max(value.translation.width, -70), 70),
                    height: min(max(value.translation.height, -70), 70)
                )
            }
            .onEnded { _ in
                guard stretch != .zero else { return }
                AppHaptics.lightTap()
                withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.32)) {
                    stretch = .zero
                }
                if !isSulking { overrideFace = nil }
            }
    }

    @ViewBuilder
    private var pendingSection: some View {
        if !pendingRecords.isEmpty {
            PendingStack(records: pendingRecords, opened: $openedPending)
        }
    }

    @ViewBuilder
    private var goalSection: some View {
        if let nearestGoal {
            GoalProgressCard(goal: nearestGoal, records: records, isCompact: true, onTap: onShowResults)
        } else if goals.isEmpty {
            GoalPlaceholderCard(isCompact: true) {
                isAddingGoal = true
            }
            .accessibilityIdentifier("homeAddGoalButton")
        }
    }

    private var weekSummary: some View {
        Button(action: onShowResults) {
            HStack(spacing: 8) {
                Text("本周")
                    .font(.rounded(14, weight: .black))
                    .foregroundStyle(Color.secondaryInk)

                Text("\(weekAssets.money.moneyString) · \(weekAssets.calories.calorieString) · \(weekAssets.minutes.displayValue(for: .time))")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.rounded(13, weight: .black))
                    .foregroundStyle(Color.punchBlack)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("本周成果，\(weekAssets.money.moneyString)，\(weekAssets.calories.calorieString)，\(weekAssets.minutes.displayValue(for: .time))")
        .accessibilityIdentifier("weekSummaryButton")
    }
}

/// Things waiting in the cooldown box, grouped the way iOS groups notifications: collapsed, the
/// most urgent one sits in front with the edges of the others showing above it; a tap fans the
/// group out into a list, and "收起" gathers it back. No custom drag, so the page scrolls as usual.
private struct PendingStack: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let records: [ResistRecord]

    /// Owned by the home screen: this section disappears when the last record is decided, and a
    /// destination declared in here would take the open detail page with it.
    @Binding var opened: ResistRecord?

    @State private var isExpanded = false

    private static let peek: CGFloat = 10
    private static let gap: CGFloat = 10
    private static let cardHeight: CGFloat = HomeView.slimRowHeight + 24
    private static let shadowDepth: CGFloat = 7

    private var isGrouped: Bool {
        records.count > 1
    }

    /// How many cards show an edge above the front one while collapsed.
    private var peekCount: Int {
        min(records.count, 3) - 1
    }

    private var height: CGFloat {
        let count = CGFloat(records.count)
        let stacked = Self.cardHeight + CGFloat(peekCount) * Self.peek
        let listed = count * Self.cardHeight + (count - 1) * Self.gap
        return (isExpanded ? listed : stacked) + Self.shadowDepth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("待决定 · \(records.count)")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)

                Spacer()

                if isGrouped {
                    Button {
                        toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "收起" : "展开")
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                        .font(.rounded(13, weight: .black))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.punchBlack)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityIdentifier("pendingStackToggle")
                }
            }

            ZStack(alignment: .top) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    card(record, index: index)
                }
            }
            .frame(height: height, alignment: .top)
        }
        .onChange(of: records.count) { _, count in
            if count < 2 { isExpanded = false }
        }
        .accessibilityIdentifier("pendingStack")
    }

    private func card(_ record: ResistRecord, index: Int) -> some View {
        // Collapsed, only the first three have a place; the rest wait behind the third.
        let depth = CGFloat(min(index, 2))
        let isHiddenInStack = index > 2
        let isCovered = isGrouped && !isExpanded && index > 0
        // Collapsed, the front card sits lowest and each one behind steps up by one edge.
        let stackedY = (CGFloat(peekCount) - depth) * Self.peek
        let listedY = CGFloat(index) * (Self.cardHeight + Self.gap)

        return Button {
            if isGrouped, !isExpanded {
                toggle()
            } else {
                opened = record
            }
        } label: {
            PunchyCard(fill: Color.softBlockColor(for: record.type), cornerRadius: 24, padding: 12) {
                HStack(spacing: 12) {
                    RecordPropIconView(record: record, size: 42)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(record.title)
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)

                        CooldownStatusLabel(record: record, isCompact: true)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.right")
                        .font(.rounded(13, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .opacity(isGrouped && !isExpanded ? 0 : 1)
                }
                .frame(height: HomeView.slimRowHeight)
                // Covered cards show only their edge, so their contents step back.
                .opacity(isCovered ? 0 : 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        // A shade darker with each layer, so edges read even when the colours match.
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.punchBlack.opacity(isExpanded ? 0 : Double(depth) * 0.08))
                .allowsHitTesting(false)
        }
        // Scaling from the top keeps each covered card's upper edge in view.
        .scaleEffect(isExpanded ? 1 : 1 - depth * 0.06, anchor: .top)
        .offset(y: isExpanded ? listedY : stackedY)
        .opacity(!isExpanded && isHiddenInStack ? 0 : 1)
        .zIndex(Double(records.count - index))
        .allowsHitTesting(isExpanded || index == 0)
        .accessibilityHidden(isCovered)
        .accessibilityLabel(
            isGrouped && !isExpanded
                ? "待决定 \(records.count) 件，最前面是\(record.title)"
                : "继续处理\(record.title)"
        )
        .accessibilityHint(isGrouped && !isExpanded ? "轻点展开" : "")
    }

    private func toggle() {
        AppHaptics.lightTap()
        if reduceMotion {
            isExpanded.toggle()
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

/// Stands in for a goal card until the first goal exists, at the same size as the real one.
struct GoalPlaceholderCard: View {
    var isCompact = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            PunchyCard(fill: .cardBackground, cornerRadius: isCompact ? 24 : 28, padding: isCompact ? 12 : 16) {
                HStack(spacing: isCompact ? 12 : 14) {
                    Image(systemName: "target")
                        .font(.rounded(isCompact ? 18 : 28, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .frame(width: isCompact ? 42 : 68, height: isCompact ? 42 : 68)
                        .background(Color.punchYellow)
                        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 14 : 20, style: .continuous))

                    VStack(alignment: .leading, spacing: isCompact ? 7 : 9) {
                        Text("省下的想用来做什么")
                            .font(.rounded(isCompact ? 16 : 18, weight: .black))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Capsule()
                            .fill(Color.punchBlack.opacity(0.12))
                            .frame(height: isCompact ? 8 : 12)

                        if !isCompact {
                            Text("新建目标")
                                .font(.rounded(13, weight: .bold))
                                .foregroundStyle(Color.secondaryInk)
                        }
                    }

                    Image(systemName: "plus")
                        .font(.rounded(isCompact ? 13 : 15, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(width: isCompact ? 30 : 34, height: isCompact ? 30 : 34)
                        .background(Color.punchBlack)
                        .clipShape(Circle())
                }
                .frame(height: isCompact ? HomeView.slimRowHeight : nil)
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("新建目标")
    }
}

struct GoalProgressCard: View {
    let goal: Goal
    let records: [ResistRecord]
    /// The slim layout used on the home screen, where the card is a glance rather than a detail.
    var isCompact = false
    var onTap: () -> Void = {}

    private var current: Double {
        StatsCalculator.currentValue(for: goal, records: records)
    }

    private var progress: Double {
        current / max(goal.targetValue, 1)
    }

    private var remaining: Double {
        max(goal.targetValue - current, 0)
    }

    private var compactCard: some View {
        PunchyCard(fill: Color.softBlockColor(for: goal.type), cornerRadius: 24, padding: 12) {
            HStack(spacing: 12) {
                GoalIconView(goal: goal, size: 42)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(goal.title)
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Spacer(minLength: 4)

                        Text(remaining > 0 ? "还差 \(remaining.displayValue(for: goal.type))" : "已完成")
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                            .fixedSize()
                    }

                    ProgressLine(progress: progress, tint: Color.blockColor(for: goal.type))
                }
            }
            .frame(height: HomeView.slimRowHeight)
        }
    }

    var body: some View {
        Button(action: onTap) {
            if isCompact {
                compactCard
            } else {
            PunchyCard(fill: Color.softBlockColor(for: goal.type), cornerRadius: 28, padding: 16) {
                HStack(spacing: 14) {
                    GoalIconView(goal: goal, size: 68)

                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 10) {
                            Text(goal.title)
                                .font(.rounded(18, weight: .black))
                                .foregroundStyle(Color.ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)

                            Spacer()

                            StatusChip(title: "\(Int(min(progress, 1) * 100))%", fill: .punchBlack)
                        }

                        ProgressLine(progress: progress, tint: Color.blockColor(for: goal.type))

                        Text(remaining > 0 ? "还差 \(remaining.displayValue(for: goal.type))" : "已经完成，点一下庆祝。")
                            .font(.rounded(13, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }
            }
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("\(goal.title)，进度 \(Int(min(progress, 1) * 100))%\(remaining > 0 ? "" : "，已完成")")
    }
}

struct RecordRow: View {
    let record: ResistRecord

    private var rowFill: Color {
        switch record.status {
        case .resisted: Color.softBlockColor(for: record.type)
        case .pending: Color.punchYellow.opacity(0.82)
        case .gaveIn: Color.cardBackground
        }
    }

    var body: some View {
        PunchyCard(fill: rowFill, cornerRadius: 24, padding: 12) {
            HStack(spacing: 12) {
                RecordPropIconView(record: record, size: 48)

                VStack(alignment: .leading, spacing: 5) {
                    Text(record.title)
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("\(recordValueText) · \(record.status.title)")
                        .font(.rounded(13, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    if record.type == .food, let grams = record.foodServingGrams, let source = record.foodSourceName {
                        Text("\(grams.cleanString)g · \(source)")
                            .font(.rounded(11, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    StatusChip(title: record.status.title, fill: statusColor)
                    Text(record.createdAt.shortTimeText)
                        .font(.rounded(12, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
    }

    private var statusColor: Color {
        switch record.status {
        case .resisted: .punchGreen
        case .pending: .punchBlack
        case .gaveIn: .secondaryInk
        }
    }

    private var recordValueText: String {
        record.displayValueText
    }
}
