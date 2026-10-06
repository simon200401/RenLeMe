import Foundation
import SwiftUI
import UIKit

enum MascotMood: Equatable {
    case steady
    case proud
    case curious
    case calm
    case struggle
    case cooling
    case observe
    case relieved
}

enum MascotMoment: Equatable {
    case idle
    case choosing(ResistType)
    case resistedSuccess
    case coolingSaved
    case gaveInSaved
    case observingRecord
    case coolingRecord
    case assetPositive(ResistType)
    case goalProgress(progress: Double, type: ResistType)
    case goalCompleted(ResistType)
    case reviewCalm

    var color: Color {
        switch self {
        case .idle, .resistedSuccess, .reviewCalm:
            .punchGreen
        case .choosing(let type), .assetPositive(let type), .goalProgress(_, let type), .goalCompleted(let type):
            type.v2MascotColor
        case .coolingSaved, .coolingRecord:
            .punchYellow
        case .gaveInSaved, .observingRecord:
            .punchPink
        }
    }

    var mood: MascotMood {
        switch self {
        case .idle:
            .steady
        case .choosing:
            .struggle
        case .resistedSuccess:
            .proud
        case .coolingSaved, .coolingRecord:
            .cooling
        case .gaveInSaved:
            .steady
        case .observingRecord:
            .observe
        case .assetPositive(let type):
            type == .food ? .relieved : .proud
        case .goalProgress(let progress, _):
            progress > 0 ? .proud : .steady
        case .goalCompleted:
            .relieved
        case .reviewCalm:
            .relieved
        }
    }

    var reaction: MascotReaction? {
        switch self {
        case .resistedSuccess, .goalCompleted: .celebrate
        case .coolingSaved: .waiting
        case .gaveInSaved: .acknowledge
        default: nil
        }
    }

    var feedbackTitle: String {
        switch self {
        case .resistedSuccess:
            "忍住了"
        case .coolingSaved:
            "先冷静"
        case .gaveInSaved:
            "看见了"
        case .goalCompleted:
            "目标完成"
        default:
            ""
        }
    }

    var feedbackMessage: String {
        switch self {
        case .resistedSuccess:
            "选择权 +1"
        case .coolingSaved:
            "已放入冷静箱"
        case .gaveInSaved:
            "已记录"
        case .goalCompleted:
            "已完成"
        default:
            ""
        }
    }

    var feedbackFill: Color {
        switch self {
        case .resistedSuccess, .goalCompleted:
            .punchGreen
        case .coolingSaved:
            .punchYellow
        case .gaveInSaved:
            .punchPink
        default:
            .cardBackground
        }
    }

    var feedbackUsesDarkText: Bool {
        switch self {
        case .coolingSaved:
            true
        default:
            false
        }
    }
}

extension Color {
    static let appBackground = Color(red: 0.965, green: 0.953, blue: 0.909)
    static let cardBackground = Color.white
    static let punchYellow = Color(red: 1.0, green: 0.812, blue: 0.0)
    static let punchGreen = Color(red: 0.024, green: 0.749, blue: 0.435)
    static let punchPink = Color(red: 0.957, green: 0.518, blue: 0.769)
    static let punchBlue = Color(red: 0.282, green: 0.655, blue: 1.0)
    static let punchBlack = Color(red: 0.025, green: 0.025, blue: 0.035)
    static let cream = Color(red: 0.984, green: 0.973, blue: 0.925)
    static let softCream = Color(red: 1.0, green: 0.988, blue: 0.925)
    static let ink = Color.punchBlack
    static let secondaryInk = Color(red: 0.29, green: 0.29, blue: 0.34)
    static let fieldLabelInk = Color(red: 0.265, green: 0.265, blue: 0.315)
    static let fieldPlaceholderInk = Color(red: 0.46, green: 0.46, blue: 0.48)

    static func blockColor(for type: ResistType) -> Color {
        switch type {
        case .money: .punchGreen
        case .food: .punchPink
        case .time: .punchYellow
        }
    }

    static func softBlockColor(for type: ResistType) -> Color {
        switch type {
        case .money: Color(red: 0.816, green: 0.957, blue: 0.859)
        case .food: Color(red: 1.0, green: 0.855, blue: 0.929)
        case .time: Color(red: 1.0, green: 0.925, blue: 0.245)
        }
    }

}

extension Font {
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension ResistType {
    var selectionReaction: MascotReaction {
        switch self {
        case .money: .walletHug
        case .food: .cupLift
        case .time: .clockLift
        }
    }

    var v2MascotColor: Color {
        switch self {
        case .money: .punchGreen
        case .food: .punchPink
        case .time: .punchYellow
        }
    }

}

extension ResistStatus {
    var v2MascotColor: Color {
        switch self {
        case .resisted: .punchGreen
        case .pending: .punchYellow
        case .gaveIn: .punchPink
        }
    }


    var mascotMoment: MascotMoment {
        switch self {
        case .resisted: .resistedSuccess
        case .pending: .coolingRecord
        case .gaveIn: .observingRecord
        }
    }
}

struct PressableScaleStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

struct PunchyCard<Content: View>: View {
    var fill: Color = .cardBackground
    var cornerRadius: CGFloat = 28
    var padding: CGFloat = 18
    var borderWidth: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.punchBlack.opacity(borderWidth > 0 ? 1 : 0), lineWidth: borderWidth)
            }
            .shadow(color: .punchBlack.opacity(0.14), radius: 0, x: 0, y: 7)
    }
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var axis: Axis = .horizontal
    var lineLimit: Int = 1
    var reservesSpace = false
    var focus: FocusState<Bool>.Binding?
    @FocusState private var internalFocus: Bool

    private var inputFocus: FocusState<Bool>.Binding {
        focus ?? $internalFocus
    }

    var body: some View {
        ZStack(alignment: axis == .vertical ? .topLeading : .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.rounded(16, weight: .black))
                    .foregroundStyle(Color.fieldPlaceholderInk)
                    .lineLimit(axis == .vertical ? lineLimit : 1)
                    .allowsHitTesting(false)
            }

            TextField("", text: $text, axis: axis)
                .appInputTextStyle()
                .keyboardType(keyboardType)
                .lineLimit(axis == .vertical ? lineLimit : 1, reservesSpace: reservesSpace)
                .focused(inputFocus)
                .accessibilityLabel(placeholder)
                .onSubmit {
                    inputFocus.wrappedValue = false
                    UIApplication.shared.dismissKeyboard()
                }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: axis == .vertical ? .topLeading : .leading)
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func appScrollDefaults() -> some View {
        self
            .scrollIndicators(.visible)
            .scrollBounceBehavior(.always, axes: .vertical)
            .scrollDismissesKeyboard(.interactively)
    }

    func appInputTextStyle() -> some View {
        self
            .font(.rounded(16, weight: .black))
            .foregroundStyle(Color.ink)
            .tint(Color.punchBlack)
            .submitLabel(.done)
    }

    func appKeyboardDismissal(onDismiss: @escaping () -> Void = {}) -> some View {
        self
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        onDismiss()
                        UIApplication.shared.dismissKeyboard()
                    }
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                    .accessibilityIdentifier("dismissKeyboardButton")
                }
            }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .filter(\.isKeyWindow)
            .forEach { $0.endEditing(true) }
    }
}

enum AppHaptics {
    static func lightTap() {
        guard AppSettings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard AppSettings.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// A soft pulse for breathing guidance; `intensity` runs 0...1.
    static func breath(intensity: Double) {
        guard AppSettings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: min(max(intensity, 0), 1))
    }
}

enum LocalImageStore {
    private static let folderName = "CustomPropImages"

    static func save(_ image: UIImage?) -> String? {
        guard let image, let data = image.jpegData(compressionQuality: 0.82) else { return nil }

        do {
            let folderURL = try folderURL()
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = folderURL.appendingPathComponent(fileName)
            try data.write(to: fileURL, options: [.atomic])
            return "\(folderName)/\(fileName)"
        } catch {
            return nil
        }
    }

    static func image(at relativePath: String?) -> UIImage? {
        guard let relativePath else { return nil }
        do {
            let documentsURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            return UIImage(contentsOfFile: documentsURL.appendingPathComponent(relativePath).path)
        } catch {
            return nil
        }
    }

    static func delete(_ relativePath: String?) {
        guard let relativePath else { return }
        do {
            let documentsURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            try? FileManager.default.removeItem(at: documentsURL.appendingPathComponent(relativePath))
        } catch {}
    }

    private static func folderURL() throws -> URL {
        let documentsURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folderURL = documentsURL.appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }
}

struct RecordPropIconView: View {
    let record: ResistRecord
    var size: CGFloat = 48

    var body: some View {
        if let image = LocalImageStore.image(at: record.customImagePath) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.punchBlack, lineWidth: max(2, size * 0.045))
                }
                .shadow(color: .punchBlack.opacity(0.14), radius: 0, x: 0, y: max(2, size * 0.06))
        } else if let template = PropTemplate.matching(record: record) {
            PropIconView(template: template, size: size)
        } else {
            TypeIcon(type: record.type, size: size)
        }
    }
}

struct GoalIconView: View {
    let goal: Goal
    var size: CGFloat = 68

    var body: some View {
        if let image = LocalImageStore.image(at: goal.customImagePath) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.punchBlack, lineWidth: max(2, size * 0.045))
                }
                .shadow(color: .punchBlack.opacity(0.14), radius: 0, x: 0, y: max(2, size * 0.06))
        } else if let template = PropTemplate.matching(goal: goal) {
            PropIconView(template: template, size: size)
        } else {
            PropIconView(template: PropTemplate.defaultTemplate(for: goal.type), size: size)
        }
    }
}

struct BlobMascotView: View {
    let color: Color
    var mood: MascotMood = .steady
    var size: CGFloat = 88

    private var assetName: String {
        switch mood {
        case .steady:
            "xiaoren_steady"
        case .proud:
            "xiaoren_proud"
        case .curious, .observe:
            "xiaoren_observe"
        case .calm, .relieved:
            "xiaoren_relieved"
        case .struggle:
            "xiaoren_struggle"
        case .cooling:
            "xiaoren_cooling"
        }
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size * 211 / 220)
        .accessibilityHidden(true)
    }
}

struct MascotMomentView: View {
    let moment: MascotMoment
    var size: CGFloat = 88
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    var body: some View {
        if moment == .coolingRecord {
            AnimatedXiaoRenView(color: moment.color, expression: .cooling, size: size, reduceMotion: reduceMotion)
        } else {
            BlobMascotView(color: moment.color, mood: moment.mood, size: size)
        }
    }
}

struct ReviewMascotSticker: View {
    var size: CGFloat = 54

    var body: some View {
        Image("xiaoren_asset_relieved")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size * 211 / 220)
            .shadow(color: .punchBlack.opacity(0.18), radius: 0, x: 0, y: max(2, size * 0.06))
            .accessibilityHidden(true)
    }
}

/// 小忍 peeking over a ledge: only the top half shows. Tap and it ducks, then comes back up.
struct PeekingMascot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isUp = false
    @State private var face: DynamicMascotExpression = .curious
    @State private var duckToken = 0

    private static let faces: [DynamicMascotExpression] = [.curious, .hello, .heartEyes, .lookAway, .settled, .sparkle]

    var body: some View {
        VStack(spacing: 0) {
            Button {
                AppHaptics.lightTap()
                duckToken += 1
            } label: {
                AnimatedXiaoRenView(color: .punchGreen, expression: face, size: 92, reduceMotion: reduceMotion)
                    .offset(y: isUp ? 4 : 96)
                    .frame(width: 120, height: 56, alignment: .top)
                    .clipped()
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("小忍探出头来")

            Capsule()
                .fill(Color.punchBlack.opacity(0.14))
                .frame(width: 150, height: 6)
        }
        .frame(maxWidth: .infinity)
        .task(id: duckToken) {
            if duckToken > 0 {
                setUp(false)
                try? await Task.sleep(for: .seconds(0.45))
                face = MascotVariety.next(from: Self.faces, avoiding: [face])
            } else {
                try? await Task.sleep(for: .seconds(0.5))
            }
            guard !Task.isCancelled else { return }
            setUp(true)
        }
        .accessibilityIdentifier("peekingMascot")
    }

    private func setUp(_ up: Bool) {
        if reduceMotion {
            isUp = up
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                isUp = up
            }
        }
    }
}

/// What 小忍 says, in a bubble whose tail points down at it.
struct MascotSpeechBubble: View {
    let text: String
    /// Horizontal position of the tail, measured from the bubble's trailing edge.
    var tailInset: CGFloat = 30

    var body: some View {
        Text(text)
            .font(.rounded(15, weight: .black))
            .foregroundStyle(Color.punchBlack)
            .lineLimit(1)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .background(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 13, height: 13)
                    .rotationEffect(.degrees(45))
                    .offset(x: -tailInset, y: 5)
            }
            .shadow(color: .punchBlack.opacity(0.16), radius: 0, x: 0, y: 3)
            .fixedSize()
            .accessibilityLabel("小忍说：\(text)")
    }
}

/// Picks a different face each time a screen appears, from faces that suit where 小忍 is standing.
enum MascotVariety {
    static func next(
        from pool: [DynamicMascotExpression],
        avoiding excluded: [DynamicMascotExpression?] = []
    ) -> DynamicMascotExpression {
        let candidates = pool.filter { !excluded.contains($0) }
        return (candidates.isEmpty ? pool : candidates).randomElement() ?? .hello
    }

    static func typeBadgePool(for type: ResistType) -> [DynamicMascotExpression] {
        switch type {
        case .money: [.sparkle, .craving, .curious, .proud]
        case .food: [.observe, .craving, .settled, .hello]
        case .time: [.relieved, .settled, .hello, .curious]
        }
    }

    static func assetPool(for type: ResistType) -> [DynamicMascotExpression] {
        switch type {
        case .money: [.proud, .celebrate, .sparkle]
        case .food: [.relieved, .settled, .observe]
        case .time: [.hello, .proud, .settled]
        }
    }

    /// One face per type, all different from each other and from what each showed last time.
    static func distinctFaces(
        previous: [ResistType: DynamicMascotExpression],
        pool: (ResistType) -> [DynamicMascotExpression]
    ) -> [ResistType: DynamicMascotExpression] {
        var faces: [ResistType: DynamicMascotExpression] = [:]
        for type in ResistType.allCases {
            faces[type] = next(from: pool(type), avoiding: [previous[type]] + faces.values.map(Optional.some))
        }
        return faces
    }
}

struct TypeMascotBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let type: ResistType
    var size: CGFloat = 64
    var showsAccessory = true
    var reaction: MascotReaction?
    var reactionToken = 0
    var isPaused = false
    /// Overrides the default face for this type.
    var face: DynamicMascotExpression?

    private var expression: DynamicMascotExpression {
        if let face { return face }
        return switch type {
        case .money: .sparkle
        case .food: .observe
        case .time: .relieved
        }
    }

    var body: some View {
        AnimatedXiaoRenView(
            color: type.v2MascotColor, expression: expression, size: size * 0.94,
            reduceMotion: reduceMotion, reaction: reaction, reactionToken: reactionToken,
            isPaused: isPaused, heldType: showsAccessory ? type : nil
        )
        .frame(width: size * 1.15, height: size)
        .accessibilityHidden(true)
    }
}

struct TypeMascotPoseAccessory: View {
    let type: ResistType
    var lift: CGFloat = 0
    var squeeze: CGFloat = 0
    var tilt: Double = 0
    /// 0...1: the prop slides away to the side and fades as it is pushed off.
    var push: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let stroke = max(3, w * 0.07)

            ZStack {
                switch type {
                case .money:
                    let centerY = h * (0.80 - lift * 0.045)
                    mascotArm(from: CGPoint(x: w * 0.24, y: h * 0.66), to: CGPoint(x: w * (0.39 + squeeze * 0.02), y: centerY), control: CGPoint(x: w * 0.31, y: centerY + h * 0.03), stroke: stroke)
                    mascotArm(from: CGPoint(x: w * 0.78, y: h * 0.66), to: CGPoint(x: w * (0.69 - squeeze * 0.02), y: centerY), control: CGPoint(x: w * 0.75, y: centerY + h * 0.03), stroke: stroke)
                    WalletAccessory()
                        .frame(width: w * 0.36, height: h * 0.22)
                        .scaleEffect(x: 1 - squeeze * 0.08, y: 1)
                        .rotationEffect(.degrees(tilt))
                        .position(x: w * 0.54, y: centerY)
                        .offset(x: push * w * 0.5)
                        .opacity(1 - push)
                case .food:
                    let centerY = h * (0.82 - lift * 0.04)
                    mascotArm(from: CGPoint(x: w * 0.25, y: h * 0.66), to: CGPoint(x: w * 0.45, y: centerY + h * 0.01), control: CGPoint(x: w * 0.31, y: centerY + h * 0.025), stroke: stroke)
                    mascotArm(from: CGPoint(x: w * 0.76, y: h * 0.66), to: CGPoint(x: w * 0.64, y: centerY), control: CGPoint(x: w * 0.74, y: centerY + h * 0.025), stroke: stroke)
                    MilkTeaAccessory()
                        .frame(width: w * 0.25, height: h * 0.30)
                        .rotationEffect(.degrees(tilt))
                        .position(x: w * 0.54, y: centerY)
                        .offset(x: push * w * 0.5)
                        .opacity(1 - push)
                case .time:
                    let centerY = h * (0.80 - lift * 0.055)
                    mascotArm(from: CGPoint(x: w * 0.24, y: h * 0.65), to: CGPoint(x: w * 0.43, y: centerY + h * 0.04), control: CGPoint(x: w * 0.32, y: centerY + h * 0.06), stroke: stroke)
                    mascotArm(from: CGPoint(x: w * 0.77, y: h * 0.65), to: CGPoint(x: w * 0.68, y: centerY + h * 0.04), control: CGPoint(x: w * 0.77, y: centerY + h * 0.06), stroke: stroke)
                    ClockAccessory()
                        .frame(width: w * 0.29, height: h * 0.29)
                        .rotationEffect(.degrees(tilt))
                        .position(x: w * 0.55, y: centerY)
                        .offset(x: push * w * 0.5)
                        .opacity(1 - push)
                }
            }
        }
    }

    private func mascotArm(from start: CGPoint, to end: CGPoint, control: CGPoint, stroke: CGFloat) -> some View {
        Path { path in
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))
    }
}

private struct WalletAccessory: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                RoundedRectangle(cornerRadius: h * 0.24, style: .continuous)
                    .fill(Color.softCream)
                    .overlay {
                        RoundedRectangle(cornerRadius: h * 0.24, style: .continuous)
                            .stroke(Color.punchBlack, lineWidth: max(3, w * 0.09))
                    }

                RoundedRectangle(cornerRadius: h * 0.16, style: .continuous)
                    .fill(Color.punchGreen)
                    .overlay {
                        RoundedRectangle(cornerRadius: h * 0.16, style: .continuous)
                            .stroke(Color.punchBlack, lineWidth: max(2, w * 0.06))
                    }
                    .frame(width: w * 0.44, height: h * 0.42)
                    .offset(x: w * 0.17)

                Circle()
                    .fill(Color.punchBlack)
                    .frame(width: w * 0.08, height: w * 0.08)
                    .offset(x: w * 0.18)
            }
        }
    }
}

private struct MilkTeaAccessory: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: w * 0.26, y: h * 0.08))
                    path.addLine(to: CGPoint(x: w * 0.84, y: -h * 0.20))
                }
                .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: max(3, w * 0.12), lineCap: .round))

                RoundedRectangle(cornerRadius: w * 0.18, style: .continuous)
                    .fill(Color.softCream)
                    .overlay {
                        RoundedRectangle(cornerRadius: w * 0.18, style: .continuous)
                            .stroke(Color.punchBlack, lineWidth: max(3, w * 0.10))
                    }

                RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                    .fill(Color.punchPink)
                    .frame(width: w * 0.68, height: h * 0.18)
                    .offset(y: h * 0.02)

                HStack(spacing: w * 0.14) {
                    Circle().fill(Color.punchBlack)
                    Circle().fill(Color.punchBlack)
                }
                .frame(width: w * 0.42, height: w * 0.08)
                .offset(y: h * 0.28)
            }
            .frame(width: w * 0.82, height: h * 0.78)
            .position(x: w * 0.50, y: h * 0.56)
        }
    }
}

private struct ClockAccessory: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let d = min(w, h)

            ZStack {
                Circle()
                    .fill(Color.softCream)
                    .overlay {
                        Circle().stroke(Color.punchBlack, lineWidth: max(3, d * 0.10))
                    }

                Path { path in
                    path.move(to: CGPoint(x: d * 0.50, y: d * 0.50))
                    path.addLine(to: CGPoint(x: d * 0.50, y: d * 0.27))
                    path.move(to: CGPoint(x: d * 0.50, y: d * 0.50))
                    path.addLine(to: CGPoint(x: d * 0.68, y: d * 0.58))
                }
                .stroke(Color.punchBlack, style: StrokeStyle(lineWidth: max(2, d * 0.08), lineCap: .round))

                HStack(spacing: d * 0.26) {
                    RoundedRectangle(cornerRadius: d * 0.04)
                        .fill(Color.punchBlack)
                    RoundedRectangle(cornerRadius: d * 0.04)
                        .fill(Color.punchBlack)
                }
                .frame(width: d * 0.78, height: d * 0.08)
                .offset(y: -d * 0.54)
            }
            .frame(width: d, height: d)
            .position(x: w * 0.5, y: h * 0.5)
        }
    }
}

struct MascotFeedbackPopup: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let moment: MascotMoment
    var message: String?
    /// Replaces the moment's default motion, e.g. with the success move for one kind of urge.
    var reaction: MascotReaction?
    var face: DynamicMascotExpression?
    var heldType: ResistType?
    var onDismiss: () -> Void = {}

    var body: some View {
        ZStack {
            Color.punchBlack.opacity(0.24)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            if moment.reaction == .celebrate {
                ConfettiBurst()
            }

            VStack(spacing: 16) {
                AnimatedXiaoRenView(
                    color: moment.color,
                    expression: face ?? DynamicMascotExpression(moment: moment),
                    size: 124,
                    reduceMotion: reduceMotion,
                    reaction: reaction ?? moment.reaction,
                    heldType: heldType
                )
                    .padding(.top, 4)

                VStack(spacing: 8) {
                    Text(moment.feedbackTitle)
                        .font(.rounded(32, weight: .black))
                        .foregroundStyle(moment.feedbackUsesDarkText ? Color.punchBlack : .white)

                    if !(message ?? moment.feedbackMessage).isEmpty {
                        Text(message ?? moment.feedbackMessage)
                            .font(.rounded(17, weight: .black))
                            .multilineTextAlignment(.center)
                            .foregroundStyle((moment.feedbackUsesDarkText ? Color.punchBlack : .white).opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: 320)
            .background(moment.feedbackFill)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .punchBlack.opacity(0.22), radius: 0, x: 0, y: 10)
            .padding(.horizontal, 24)
            .accessibilityElement(children: .combine)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct TypeIcon: View {
    let type: ResistType
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: type.symbolName)
            .font(.rounded(size * 0.46, weight: .black))
            .foregroundStyle(Color.punchBlack)
            .frame(width: size, height: size)
            .background(Color.softBlockColor(for: type))
            .clipShape(Circle())
            .overlay {
                Circle().stroke(Color.punchBlack, lineWidth: max(2, size * 0.055))
            }
    }
}

struct PropIconView: View {
    let template: PropTemplate
    var size: CGFloat = 54
    var showsBackground = true

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(template.displayColor)
            }

            CartoonPropGlyphView(iconKey: template.iconKey, size: size * 0.76)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct CartoonPropGlyphView: View {
    let iconKey: PropIconKey
    var size: CGFloat

    private var line: CGFloat { max(3, size * 0.074) }
    private var thinLine: CGFloat { max(2, size * 0.052) }
    private var cream: Color { .softCream }
    private var pink: Color { .punchPink }
    private var green: Color { .punchGreen }
    private var yellow: Color { .punchYellow }
    private var black: Color { .punchBlack }

    var body: some View {
        ZStack {
            switch iconKey {
            case .coolBox:
                coolBox
            case .badge:
                badge
            case .calendar:
                calendar
            case .chart:
                chart
            case .milkTea:
                milkTea
            case .snack:
                snack
            case .takeout:
                takeout
            case .dessert:
                dessert
            case .friedChicken:
                friedChicken
            case .clock:
                clock
            case .gaming:
                gaming
            case .drama:
                drama
            case .shortVideo:
                shortVideo
            case .sleep:
                sleep
            case .chat:
                chat
            case .stayUp:
                stayUp
            case .delay:
                delay
            case .wallet:
                wallet
            case .camera:
                camera
            case .clothes:
                clothes
            case .gamingGear:
                gamingGear
            case .misc:
                misc
            case .phone:
                phone
            case .laptop:
                laptop
            case .jewelry:
                jewelry
            case .subscription:
                subscription
            case .cosmetics:
                cosmetics
            case .shoes:
                shoes
            case .bag:
                bag
            case .blindBox:
                blindBox
            case .travel:
                travel
            case .course:
                course
            }
        }
        .frame(width: size, height: size)
    }

    private var coolBox: some View {
        ZStack {
            roundedBox(width: 0.62, height: 0.48, corner: 0.11, fill: yellow)
                .offset(y: size * 0.08)
            roundedBox(width: 0.72, height: 0.24, corner: 0.08, fill: yellow)
                .offset(y: -size * 0.14)
            lineCapsule(width: 0.18, height: 0.052, color: .white)
                .offset(x: -size * 0.17, y: -size * 0.14)
        }
    }

    private var badge: some View {
        ZStack {
            StarShape(points: 5, innerRatio: 0.48)
                .fill(cream)
                .overlay {
                    StarShape(points: 5, innerRatio: 0.48)
                        .stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round))
                }
                .frame(width: size * 0.68, height: size * 0.68)
            lineCapsule(width: 0.32, height: 0.06, color: .punchBlue)
                .rotationEffect(.degrees(-42))
        }
    }

    private var calendar: some View {
        ZStack {
            roundedBox(width: 0.66, height: 0.58, corner: 0.1, fill: cream)
            lineCapsule(width: 0.66, height: 0.045)
                .offset(y: -size * 0.12)
            HStack(spacing: size * 0.08) {
                Circle().fill(Color.punchBlue)
                Circle().fill(Color.punchBlue)
                Circle().fill(Color.punchBlue)
            }
            .frame(width: size * 0.42, height: size * 0.06)
            .offset(y: size * 0.04)
            checkMark
                .frame(width: size * 0.22, height: size * 0.16)
                .offset(x: size * 0.14, y: size * 0.18)
        }
    }

    private var chart: some View {
        ZStack {
            roundedBox(width: 0.70, height: 0.58, corner: 0.1, fill: cream)
            HStack(alignment: .bottom, spacing: size * 0.06) {
                bar(height: 0.24)
                bar(height: 0.38)
                bar(height: 0.50)
            }
            .offset(y: size * 0.10)
            lineCapsule(width: 0.42, height: 0.045)
                .offset(y: -size * 0.18)
        }
    }

    private var milkTea: some View {
        ZStack {
            roundedBox(width: 0.48, height: 0.68, corner: 0.11, fill: .white)
            lineCapsule(width: 0.62, height: 0.055)
                .offset(y: -size * 0.34)
            RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                .fill(pink)
                .frame(width: size * 0.34, height: size * 0.13)
                .offset(y: -size * 0.04)
            Circle().fill(black).frame(width: size * 0.07, height: size * 0.07).offset(x: -size * 0.10, y: size * 0.22)
            Circle().fill(black).frame(width: size * 0.07, height: size * 0.07).offset(x: size * 0.10, y: size * 0.28)
        }
    }

    private var snack: some View {
        ZStack {
            Ellipse()
                .fill(.white)
                .frame(width: size * 0.88, height: size * 0.76)
            roundedBox(width: 0.48, height: 0.66, corner: 0.06, fill: pink)
                .rotationEffect(.degrees(5))
            roundedBox(width: 0.32, height: 0.23, corner: 0.05, fill: cream)
            face(y: size * 0.06)
            Circle().fill(green).overlay(Circle().stroke(black, lineWidth: thinLine)).frame(width: size * 0.16).offset(x: -size * 0.34, y: size * 0.02)
            Circle().fill(green).overlay(Circle().stroke(black, lineWidth: thinLine)).frame(width: size * 0.16).offset(x: size * 0.34, y: -size * 0.02)
        }
    }

    private var takeout: some View {
        ZStack {
            roundedBox(width: 0.46, height: 0.48, corner: 0.07, fill: cream)
                .offset(y: size * 0.06)
            lineCapsule(width: 0.30, height: 0.055)
                .offset(y: -size * 0.20)
            lineCapsule(width: 0.28, height: 0.075, color: pink)
                .offset(y: size * 0.02)
            face(y: size * 0.20)
        }
    }

    private var dessert: some View {
        ZStack {
            Circle()
                .fill(yellow)
                .overlay(Circle().stroke(black, lineWidth: line))
                .frame(width: size * 0.18)
                .offset(y: -size * 0.34)
            cupShape
                .fill(cream)
                .overlay { cupShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.48, height: size * 0.48)
                .offset(y: size * 0.06)
            lineCapsule(width: 0.34, height: 0.07, color: pink)
                .offset(y: -size * 0.04)
            lineCapsule(width: 0.20, height: 0.04)
                .offset(y: size * 0.18)
        }
    }

    private var friedChicken: some View {
        ZStack {
            Circle()
                .fill(yellow)
                .overlay(Circle().stroke(black, lineWidth: line))
                .frame(width: size * 0.46)
                .offset(x: -size * 0.08, y: -size * 0.06)
            lineCapsule(width: 0.26, height: 0.09)
                .rotationEffect(.degrees(42))
                .offset(x: size * 0.23, y: size * 0.16)
            Circle()
                .fill(cream)
                .overlay(Circle().stroke(black, lineWidth: thinLine))
                .frame(width: size * 0.18)
                .offset(x: size * 0.38, y: size * 0.26)
            face(y: size * 0.04)
        }
    }

    private var clock: some View {
        ZStack {
            Circle()
                .fill(.white)
                .overlay(Circle().stroke(black, lineWidth: line))
                .frame(width: size * 0.58)
            lineCapsule(width: 0.22, height: 0.05)
            lineCapsule(width: 0.24, height: 0.05)
                .rotationEffect(.degrees(-52))
                .offset(x: size * 0.08, y: -size * 0.05)
            lineCapsule(width: 0.10, height: 0.045)
                .offset(x: -size * 0.25, y: -size * 0.37)
            lineCapsule(width: 0.10, height: 0.045)
                .offset(x: size * 0.25, y: -size * 0.37)
        }
    }

    private var gaming: some View {
        ZStack {
            roundedBox(width: 0.70, height: 0.42, corner: 0.14, fill: cream)
                .offset(y: size * 0.08)
            plusGlyph.offset(x: -size * 0.18, y: size * 0.04)
            Circle().fill(black).frame(width: size * 0.08).offset(x: size * 0.16, y: size * 0.00)
            Circle().fill(black).frame(width: size * 0.08).offset(x: size * 0.28, y: size * 0.10)
        }
    }

    private var drama: some View {
        ZStack {
            roundedBox(width: 0.66, height: 0.46, corner: 0.10, fill: cream)
            triangle(fill: pink, stroke: true)
                .frame(width: size * 0.24, height: size * 0.24)
            lineCapsule(width: 0.36, height: 0.045)
                .rotationEffect(.degrees(24))
                .offset(y: -size * 0.34)
            lineCapsule(width: 0.36, height: 0.045)
                .rotationEffect(.degrees(-24))
                .offset(y: size * 0.34)
        }
    }

    private var shortVideo: some View {
        ZStack {
            roundedBox(width: 0.38, height: 0.72, corner: 0.10, fill: cream)
            triangle(fill: green, stroke: true)
                .frame(width: size * 0.22, height: size * 0.25)
            Circle().fill(black).frame(width: size * 0.055).offset(y: size * 0.26)
            Circle().fill(pink).overlay(Circle().stroke(black, lineWidth: thinLine)).frame(width: size * 0.18).offset(x: size * 0.28, y: -size * 0.28)
            Circle().fill(yellow).overlay(Circle().stroke(black, lineWidth: thinLine)).frame(width: size * 0.15).offset(x: -size * 0.28, y: size * 0.18)
        }
    }

    private var sleep: some View {
        ZStack {
            roundedBox(width: 0.70, height: 0.26, corner: 0.04, fill: cream)
                .offset(y: size * 0.18)
            roundedBox(width: 0.30, height: 0.22, corner: 0.06, fill: pink)
                .offset(x: -size * 0.20, y: size * 0.02)
            Text("Z")
                .font(.rounded(size * 0.34, weight: .black))
                .foregroundStyle(black)
                .offset(x: size * 0.20, y: -size * 0.20)
        }
    }

    private var chat: some View {
        ZStack {
            roundedBox(width: 0.74, height: 0.42, corner: 0.11, fill: cream)
            HStack(spacing: size * 0.08) {
                Circle().fill(black)
                Circle().fill(black)
                Circle().fill(black)
            }
            .frame(width: size * 0.42, height: size * 0.07)
        }
    }

    private var stayUp: some View {
        ZStack {
            CrescentShape()
                .fill(cream)
                .overlay {
                    CrescentShape()
                        .stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round))
                }
                .frame(width: size * 0.52, height: size * 0.62)
                .offset(x: -size * 0.08)
            Text("Z")
                .font(.rounded(size * 0.25, weight: .black))
                .foregroundStyle(pink)
                .offset(x: size * 0.26, y: -size * 0.18)
        }
    }

    private var delay: some View {
        ZStack {
            hourglassShape
                .fill(cream)
                .overlay { hourglassShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.42, height: size * 0.62)
            lineCapsule(width: 0.30, height: 0.05, color: pink)
                .offset(y: -size * 0.12)
        }
    }

    private var wallet: some View {
        ZStack {
            roundedBox(width: 0.72, height: 0.44, corner: 0.10, fill: cream)
            roundedBox(width: 0.34, height: 0.20, corner: 0.08, fill: green)
                .offset(x: size * 0.14)
            Circle().fill(black).frame(width: size * 0.055).offset(x: size * 0.14)
        }
    }

    private var camera: some View {
        ZStack {
            roundedBox(width: 0.76, height: 0.44, corner: 0.10, fill: .white)
                .offset(y: size * 0.06)
            roundedBox(width: 0.32, height: 0.18, corner: 0.06, fill: .white)
                .offset(y: -size * 0.16)
            Circle()
                .fill(yellow)
                .overlay(Circle().stroke(black, lineWidth: line))
                .frame(width: size * 0.26)
                .offset(y: size * 0.06)
            Circle().fill(black).frame(width: size * 0.10).offset(x: size * 0.30, y: -size * 0.04)
        }
    }

    private var clothes: some View {
        ZStack {
            shirtShape
                .fill(cream)
                .overlay { shirtShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.70, height: size * 0.64)
            lineCapsule(width: 0.22, height: 0.06, color: pink)
                .offset(y: size * 0.18)
        }
    }

    private var gamingGear: some View {
        ZStack {
            roundedBox(width: 0.50, height: 0.36, corner: 0.08, fill: cream)
            roundedBox(width: 0.30, height: 0.18, corner: 0.04, fill: green)
            lineCapsule(width: 0.40, height: 0.05)
                .offset(y: size * 0.32)
            plusBadge
                .offset(x: size * 0.30, y: size * 0.16)
        }
    }

    private var misc: some View {
        ZStack {
            boxShape
                .fill(cream)
                .overlay { boxShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.50, height: size * 0.58)
            face(y: size * 0.14)
            PolygonShape(sides: 4)
                .fill(yellow)
                .overlay { PolygonShape(sides: 4).stroke(black, lineWidth: line) }
                .frame(width: size * 0.50, height: size * 0.26)
                .offset(y: -size * 0.26)
        }
    }

    private var phone: some View {
        ZStack {
            roundedBox(width: 0.32, height: 0.68, corner: 0.09, fill: cream)
            roundedBox(width: 0.18, height: 0.18, corner: 0.05, fill: pink)
                .offset(y: size * 0.06)
            lineCapsule(width: 0.14, height: 0.04)
                .offset(y: -size * 0.22)
        }
    }

    private var laptop: some View {
        ZStack {
            roundedBox(width: 0.48, height: 0.34, corner: 0.05, fill: cream)
                .offset(y: -size * 0.08)
            laptopBase
                .fill(green)
                .overlay { laptopBase.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.70, height: size * 0.24)
                .offset(y: size * 0.22)
            Circle().fill(pink).frame(width: size * 0.06)
                .offset(y: -size * 0.08)
        }
    }

    private var jewelry: some View {
        ZStack {
            Circle()
                .fill(green)
                .overlay(Circle().stroke(black, lineWidth: line))
                .frame(width: size * 0.44)
                .offset(y: size * 0.12)
            lineCapsule(width: 0.28, height: 0.06, color: pink)
                .rotationEffect(.degrees(6))
                .offset(y: -size * 0.20)
            Circle()
                .fill(yellow)
                .overlay(Circle().stroke(black, lineWidth: thinLine))
                .frame(width: size * 0.18)
                .offset(x: size * 0.28, y: -size * 0.24)
        }
    }

    private var subscription: some View {
        ZStack {
            roundedBox(width: 0.42, height: 0.54, corner: 0.08, fill: cream)
            lineCapsule(width: 0.26, height: 0.04)
                .offset(y: -size * 0.10)
            plusBadge
                .offset(x: size * 0.24, y: size * 0.23)
        }
    }

    private var cosmetics: some View {
        HStack(spacing: size * 0.08) {
            roundedBox(width: 0.18, height: 0.56, corner: 0.06, fill: cream)
            roundedBox(width: 0.18, height: 0.50, corner: 0.06, fill: cream)
        }
        .overlay {
            lineCapsule(width: 0.12, height: 0.16, color: pink)
                .offset(x: size * 0.12, y: -size * 0.02)
        }
    }

    private var shoes: some View {
        ZStack {
            shoeShape
                .fill(cream)
                .overlay { shoeShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.66, height: size * 0.38)
            lineCapsule(width: 0.22, height: 0.05, color: pink)
                .offset(y: size * 0.08)
        }
    }

    private var bag: some View {
        ZStack {
            roundedBox(width: 0.48, height: 0.52, corner: 0.06, fill: cream)
                .offset(y: size * 0.08)
            lineCapsule(width: 0.28, height: 0.05)
                .offset(y: -size * 0.22)
            face(y: size * 0.13)
        }
    }

    private var blindBox: some View {
        ZStack {
            boxShape
                .fill(cream)
                .overlay { boxShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.50, height: size * 0.58)
            Text("?")
                .font(.rounded(size * 0.26, weight: .black))
                .foregroundStyle(pink)
                .offset(y: size * 0.12)
            PolygonShape(sides: 4)
                .fill(yellow)
                .overlay { PolygonShape(sides: 4).stroke(black, lineWidth: line) }
                .frame(width: size * 0.50, height: size * 0.26)
                .offset(y: -size * 0.26)
        }
    }

    private var travel: some View {
        paperPlaneShape
            .fill(cream)
            .overlay { paperPlaneShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
            .frame(width: size * 0.66, height: size * 0.56)
            .rotationEffect(.degrees(-12))
            .overlay {
                Circle()
                    .fill(pink)
                    .overlay(Circle().stroke(black, lineWidth: thinLine))
                    .frame(width: size * 0.12)
                    .offset(x: -size * 0.18, y: -size * 0.26)
            }
    }

    private var course: some View {
        ZStack {
            capShape
                .fill(cream)
                .overlay { capShape.stroke(black, style: StrokeStyle(lineWidth: line, lineJoin: .round)) }
                .frame(width: size * 0.72, height: size * 0.42)
            lineCapsule(width: 0.30, height: 0.06, color: pink)
                .offset(y: size * 0.15)
        }
    }

    private func roundedBox(width: CGFloat, height: CGFloat, corner: CGFloat, fill: Color) -> some View {
        RoundedRectangle(cornerRadius: size * corner, style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: size * corner, style: .continuous)
                    .stroke(black, lineWidth: line)
            }
            .frame(width: size * width, height: size * height)
    }

    private func lineCapsule(width: CGFloat, height: CGFloat, color: Color = .punchBlack) -> some View {
        Capsule()
            .fill(color)
            .frame(width: size * width, height: max(thinLine, size * height))
    }

    private func bar(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.025, style: .continuous)
            .fill(Color.punchBlue)
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.025, style: .continuous)
                    .stroke(black, lineWidth: thinLine)
            }
            .frame(width: size * 0.10, height: size * height)
    }

    private var plusGlyph: some View {
        ZStack {
            lineCapsule(width: 0.20, height: 0.055)
            lineCapsule(width: 0.20, height: 0.055)
                .rotationEffect(.degrees(90))
        }
    }

    private var plusBadge: some View {
        Circle()
            .fill(pink)
            .overlay(Circle().stroke(black, lineWidth: thinLine))
            .frame(width: size * 0.22)
            .overlay {
                plusGlyph
                    .scaleEffect(0.55)
            }
    }

    private var checkMark: some View {
        Path { path in
            path.move(to: CGPoint(x: 0.05, y: 0.52))
            path.addLine(to: CGPoint(x: 0.34, y: 0.82))
            path.addLine(to: CGPoint(x: 0.95, y: 0.12))
        }
        .stroke(black, style: StrokeStyle(lineWidth: thinLine, lineCap: .round, lineJoin: .round))
    }

    private func face(y: CGFloat) -> some View {
        ZStack {
            Circle().fill(black).frame(width: size * 0.055).offset(x: -size * 0.10, y: y)
            Circle().fill(black).frame(width: size * 0.055).offset(x: size * 0.10, y: y)
            lineCapsule(width: 0.18, height: 0.035)
                .offset(y: y + size * 0.14)
        }
    }

    private func triangle(fill: Color, stroke: Bool) -> some View {
        TriangleShape()
            .fill(fill)
            .overlay {
                if stroke {
                    TriangleShape()
                        .stroke(black, style: StrokeStyle(lineWidth: thinLine, lineJoin: .round))
                }
            }
    }

    private var cupShape: some Shape { TaperedCupShape() }
    private var hourglassShape: some Shape { HourglassShape() }
    private var shirtShape: some Shape { ShirtShape() }
    private var boxShape: some Shape { BoxFrontShape() }
    private var laptopBase: some Shape { LaptopBaseShape() }
    private var shoeShape: some Shape { ShoeShape() }
    private var paperPlaneShape: some Shape { PaperPlaneShape() }
    private var capShape: some Shape { CapShape() }
}

private struct StarShape: Shape {
    var points: Int
    var innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()

        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) * .pi / CGFloat(points) - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct TaperedCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width * 0.42, startAngle: .degrees(104), endAngle: .degrees(256), clockwise: false)
        path.addArc(center: CGPoint(x: rect.midX + rect.width * 0.23, y: rect.midY), radius: rect.width * 0.35, startAngle: .degrees(250), endAngle: .degrees(110), clockwise: true)
        path.closeSubpath()
        return path
    }
}

private struct HourglassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct ShirtShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width * 0.20, y: rect.minY + rect.height * 0.05))
        path.addQuadCurve(to: CGPoint(x: rect.midX + rect.width * 0.20, y: rect.minY + rect.height * 0.05), control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.30, y: rect.minY + rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.30, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.28))
        path.closeSubpath()
        return path
    }
}

private struct BoxFrontShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PolygonShape: Shape {
    var sides: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<max(sides, 3) {
            let angle = CGFloat(index) * 2 * .pi / CGFloat(max(sides, 3)) - .pi / 4
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct LaptopBaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ShoeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.18), control: CGPoint(x: rect.width * 0.28, y: rect.minY + rect.height * 0.08))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.midY), control: CGPoint(x: rect.width * 0.66, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY - rect.height * 0.20))
        path.closeSubpath()
        return path
    }
}

private struct PaperPlaneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.26, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.30))
        path.closeSubpath()
        return path
    }
}

private struct CapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ValueDefaultChip: View {
    let text: String
    var fill: Color = .cream

    var body: some View {
        Text(text)
            .font(.rounded(11, weight: .black))
            .foregroundStyle(Color.punchBlack)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(fill)
            .clipShape(Capsule())
    }
}

struct PropCard: View {
    let template: PropTemplate
    var isSelected = false
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            PropIconView(template: template, size: compact ? 48 : 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.rounded(compact ? 14 : 16, weight: .black))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Text(template.caption)
                    .font(.rounded(11, weight: .bold))
                    .foregroundStyle(Color.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            if !compact {
                ValueDefaultChip(text: template.defaultValueText, fill: template.displayColor.opacity(0.34))
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 120 : 154, alignment: .topLeading)
        .padding(compact ? 11 : 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? Color.punchBlack : Color.clear, lineWidth: isSelected ? 3 : 0)
        }
        .shadow(color: .punchBlack.opacity(isSelected ? 0.15 : 0.08), radius: 0, x: 0, y: isSelected ? 6 : 3)
    }
}

struct CustomPropCard: View {
    let type: ResistType
    var selectedImage: UIImage?
    var isSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.punchBlack, lineWidth: 3)
                        }
                } else {
                    PropIconView(template: PropTemplate.customFallbackTemplate(for: type), size: 58)
                }

                Circle()
                    .fill(Color.punchBlack)
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.rounded(12, weight: .black))
                            .foregroundStyle(Color.white)
                    }
                    .offset(x: 24, y: 24)
            }

            Text("自选")
                .font(.rounded(16, weight: .black))
                .foregroundStyle(Color.ink)

            ValueDefaultChip(text: "可拍照 / 相册", fill: Color.softBlockColor(for: type))
        }
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? Color.punchBlack : Color.clear, lineWidth: isSelected ? 3 : 0)
        }
        .shadow(color: .punchBlack.opacity(isSelected ? 0.15 : 0.08), radius: 0, x: 0, y: isSelected ? 6 : 3)
    }
}

struct StatusChip: View {
    let title: String
    var fill: Color = .punchBlack
    var foreground: Color = .white

    var body: some View {
        Text(title)
            .font(.rounded(13, weight: .black))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(fill)
            .clipShape(Capsule())
    }
}

struct ProgressLine: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.punchBlack.opacity(0.12))

                Capsule()
                    .fill(tint)
                    .frame(width: max(10, geometry.size.width * min(max(progress, 0), 1)))
                    .overlay {
                        Capsule().stroke(Color.punchBlack.opacity(0.16), lineWidth: 1)
                    }
            }
        }
        .frame(height: 12)
    }
}

struct WeekDotRow: View {
    let completedWeekdays: Set<Int>
    var activeColor: Color = .punchBlack

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<7, id: \.self) { index in
                let weekday = index + 2 > 7 ? 1 : index + 2
                VStack(spacing: 6) {
                    Text(days[index])
                        .font(.rounded(11, weight: .black))
                        .foregroundStyle(Color.secondaryInk)

                    ZStack {
                        Circle()
                            .fill(completedWeekdays.contains(weekday) ? activeColor : Color.punchBlack.opacity(0.08))
                            .frame(width: 36, height: 36)

                        if completedWeekdays.contains(weekday) {
                            Image(systemName: "checkmark")
                                .font(.rounded(15, weight: .black))
                                .foregroundStyle(Color.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct AssetBlockCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let type: ResistType
    let value: String
    var subtitle: String
    var isPaused = false
    /// Overrides the default face for this type.
    var face: DynamicMascotExpression?
    var onReaction: () -> Void = {}
    @State private var bounceToken = 0
    @State private var lastPlayedToken = 0
    @State private var isReacting = false

    private var mascotExpression: DynamicMascotExpression {
        if let face { return face }
        return switch type {
        case .money: .proud
        case .food: .relieved
        case .time: .hello
        }
    }

    private var reaction: MascotReaction {
        switch type {
        case .money: .moneyPride
        case .food: .foodRelief
        case .time: .timeStretch
        }
    }

    var body: some View {
        Button {
            playReaction()
        } label: {
            PunchyCard(fill: Color.blockColor(for: type), cornerRadius: 28, padding: subtitle.isEmpty ? 14 : 16) {
                VStack(alignment: .leading, spacing: subtitle.isEmpty ? 8 : 12) {
                    HStack(spacing: 6) {
                        Text(type.assetTitle)
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(type == .time ? Color.punchBlack : .white)

                        Spacer(minLength: 0)
                        AnimatedXiaoRenView(
                            color: Color(red: 1.0, green: 0.949, blue: 0.839),
                            expression: mascotExpression,
                            size: 42,
                            reduceMotion: reduceMotion,
                            reaction: isReacting ? reaction : nil,
                            reactionToken: bounceToken,
                            isPaused: isPaused
                        )
                    }

                    Text(value)
                        .font(.rounded(28, weight: .black))
                        .foregroundStyle(type == .time ? Color.punchBlack : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.rounded(12, weight: .bold))
                            .foregroundStyle((type == .time ? Color.punchBlack : .white).opacity(0.78))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .modifier(ShakeEffect(amount: reduceMotion || isPaused ? 0 : 3, animatableData: CGFloat(bounceToken)))
        .accessibilityLabel("\(type.assetTitle)，\(value)，点击查看反馈")
        .task(id: bounceToken) {
            guard bounceToken > lastPlayedToken, !reduceMotion, !isPaused else { return }
            lastPlayedToken = bounceToken
            isReacting = true
            do {
                try await Task.sleep(for: .seconds(reaction.duration))
            } catch {
                return
            }
            isReacting = false
        }
        .onChange(of: isPaused) { _, paused in
            if paused { isReacting = false }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { isReacting = false }
        }
        .onDisappear { isReacting = false }
    }

    private func playReaction() {
        guard !isReacting else { return }
        AppHaptics.lightTap()
        onReaction()
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            bounceToken += 1
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 7
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * shakesPerUnit),
            y: 0
        ))
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            MascotMomentView(moment: .idle, size: 76)

            Text(title)
                .font(.rounded(20, weight: .black))
                .foregroundStyle(Color.ink)

            if !message.isEmpty {
                Text(message)
                    .font(.rounded(15, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.rounded(22, weight: .black))
                .foregroundStyle(Color.ink)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.rounded(14, weight: .black))
                    .foregroundStyle(Color.punchBlack)
            }
        }
    }
}

struct CooldownStatusLabel: View {
    let record: ResistRecord
    /// One line of plain text instead of a chip, for slim rows.
    var isCompact = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            let isReady = (record.cooldownUntil ?? .distantPast) <= context.date

            if isCompact {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isReady ? Color.punchGreen : Color.punchBlack)
                        .frame(width: 8, height: 8)

                    Text(isReady ? "可以决定了" : "冷静中")
                        .font(.rounded(13, weight: .black))
                        .foregroundStyle(Color.ink)

                    if !isReady, let cooldownUntil = record.cooldownUntil {
                        Text(timerInterval: context.date...cooldownUntil, countsDown: true)
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
            } else {
            HStack(spacing: 8) {
                StatusChip(
                    title: isReady ? "可以决定了" : "冷静中",
                    fill: isReady ? .punchGreen : .punchBlack
                )

                if !isReady, let cooldownUntil = record.cooldownUntil {
                    Text(timerInterval: context.date...cooldownUntil, countsDown: true)
                        .font(.rounded(13, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            }
        }
    }
}

struct CooldownActionRequest: Identifiable {
    enum Action {
        case resolve(ResistStatus)
        case delay
    }

    let id = UUID()
    let record: ResistRecord
    let action: Action
}

private enum CooldownActionResult {
    case resolved(ResistRecord, ResistStatus, Double?)
    case delayed(ResistRecord, TimeInterval)
}

extension View {
    func cooldownActionSheet(
        request: Binding<CooldownActionRequest?>,
        onFeedback: @escaping (MascotMoment) -> Void
    ) -> some View {
        modifier(CooldownActionSheetPresenter(request: request, onFeedback: onFeedback))
    }
}

private struct CooldownActionSheetPresenter: ViewModifier {
    @Binding var request: CooldownActionRequest?
    let onFeedback: (MascotMoment) -> Void
    @State private var pendingResult: CooldownActionResult?

    func body(content: Content) -> some View {
        content.sheet(item: $request, onDismiss: applyPendingResult) { request in
            Group {
                switch request.action {
                case .resolve(let status):
                    CooldownValueSheet(record: request.record, status: status) { value in
                        pendingResult = .resolved(request.record, status, value)
                        self.request = nil
                    }
                case .delay:
                    CooldownDelaySheet(record: request.record) { interval in
                        pendingResult = .delayed(request.record, interval)
                        self.request = nil
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func applyPendingResult() {
        guard let result = pendingResult else { return }
        pendingResult = nil

        // Keep the presenting row alive until the sheet finishes dismissing.
        switch result {
        case .resolved(let record, let status, let value):
            CooldownCoordinator.resolve(record, as: status, estimatedValue: value)
            if status == .resisted {
                AppHaptics.success()
                onFeedback(.resistedSuccess)
            } else {
                AppHaptics.lightTap()
                onFeedback(.gaveInSaved)
            }
        case .delayed(let record, let interval):
            CooldownCoordinator.extend(record, by: interval)
            AppHaptics.lightTap()
            onFeedback(.coolingSaved)
        }
    }
}

struct CooldownDecisionActions: View {
    let record: ResistRecord
    var onRequest: (CooldownActionRequest) -> Void
    var onFeedback: (MascotMoment) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                decisionButton(
                    title: "我忍住了",
                    systemImage: "checkmark",
                    fill: .punchBlack,
                    foreground: .white,
                    status: .resisted
                )

                decisionButton(
                    title: "我还是做了",
                    systemImage: "eye.fill",
                    fill: .cream,
                    foreground: .punchBlack,
                    status: .gaveIn
                )
            }

            Button {
                onRequest(CooldownActionRequest(record: record, action: .delay))
            } label: {
                Label("再等一会", systemImage: "clock.arrow.circlepath")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.softBlockColor(for: record.type))
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableScaleStyle())
        }
    }

    private func decisionButton(
        title: String,
        systemImage: String,
        fill: Color,
        foreground: Color,
        status: ResistStatus
    ) -> some View {
        Button {
            requestResolution(as: status)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.rounded(15, weight: .black))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(fill)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.punchBlack.opacity(fill == Color.cream ? 1 : 0), lineWidth: 2)
                }
        }
        .buttonStyle(PressableScaleStyle())
    }

    private func requestResolution(as status: ResistStatus) {
        if record.hasEstimatedValue {
            resolve(as: status, estimatedValue: nil)
        } else {
            onRequest(CooldownActionRequest(record: record, action: .resolve(status)))
        }
    }

    private func resolve(as status: ResistStatus, estimatedValue: Double?) {
        CooldownCoordinator.resolve(record, as: status, estimatedValue: estimatedValue)
        if status == .resisted {
            AppHaptics.success()
            onFeedback(.resistedSuccess)
        } else {
            AppHaptics.lightTap()
            onFeedback(.gaveInSaved)
        }
    }

}

private struct CooldownDelaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: ResistRecord
    let onComplete: (TimeInterval) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(record.title)
                        .font(.rounded(26, weight: .black))
                        .foregroundStyle(Color.ink)

                    ForEach(delayOptions, id: \.seconds) { option in
                        Button {
                            onComplete(option.seconds)
                        } label: {
                            Label(option.title, systemImage: "clock.arrow.circlepath")
                                .font(.rounded(17, weight: .black))
                                .foregroundStyle(Color.punchBlack)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.softBlockColor(for: record.type))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("再等多久？")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var delayOptions: [(title: String, seconds: TimeInterval)] {
        switch record.type {
        case .money:
            [("再等 1 小时", 60 * 60), ("再等 24 小时", 24 * 60 * 60), ("再等 3 天", 3 * 24 * 60 * 60)]
        case .food:
            [("再等 10 分钟", 10 * 60), ("再等 30 分钟", 30 * 60), ("再等 1 小时", 60 * 60)]
        case .time:
            [("再等 15 分钟", 15 * 60), ("再等 30 分钟", 30 * 60), ("再等 1 小时", 60 * 60)]
        }
    }
}

private struct CooldownValueSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: ResistRecord
    let status: ResistStatus
    let onComplete: (Double?) -> Void

    @State private var valueText = ""

    private var parsedValue: Double? {
        guard let value = Double(valueText.replacingOccurrences(of: ",", with: "")), value > 0 else {
            return nil
        }
        return value
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.title)
                            .font(.rounded(26, weight: .black))
                            .foregroundStyle(Color.ink)
                        Text("补充\(record.type.valueTitle)")
                            .font(.rounded(15, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                    }

                    Spacer()
                    MascotMomentView(moment: status == .resisted ? .resistedSuccess : .observingRecord, size: 64)
                }

                AppTextField(
                    placeholder: valuePlaceholder,
                    text: $valueText,
                    keyboardType: .decimalPad
                )

                Button {
                    guard let parsedValue else { return }
                    finish(with: parsedValue)
                } label: {
                    Text("保存决定")
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.punchBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
                .disabled(parsedValue == nil)
                .opacity(parsedValue == nil ? 0.45 : 1)

                Button("暂不填写") {
                    finish(with: nil)
                }
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.secondaryInk)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(20)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("完成冷静")
            .navigationBarTitleDisplayMode(.inline)
            .appKeyboardDismissal()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var valuePlaceholder: String {
        switch record.type {
        case .money: "金额 · ¥"
        case .food: "热量 · kcal"
        case .time: "时长 · 分钟"
        }
    }

    private func finish(with value: Double?) {
        UIApplication.shared.dismissKeyboard()
        onComplete(value)
    }
}
