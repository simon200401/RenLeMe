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
            "你刚刚把选择权拿回来了。"
        case .coolingSaved:
            "先放一会儿，等心里安静一点再决定。"
        case .gaveInSaved:
            "它不是失败，只是一条线索。我们已经看见它了。"
        case .goalCompleted:
            "这份忍住的价值，真的抵达了想去的地方。"
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
    static let accentPurple = Color.punchBlack
    static let softPurple = Color(red: 1.0, green: 0.918, blue: 0.0)

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

    func shadeVariant(_ index: Int) -> Color {
        let opacity = 0.05 + Double(index % 5) * 0.035
        return index.isMultiple(of: 2)
            ? mix(with: .white, amount: opacity)
            : mix(with: .punchBlack, amount: opacity * 0.58)
    }

    private func mix(with overlay: Color, amount: Double) -> Color {
        Color(uiColor: UIColor(self).mixing(with: UIColor(overlay), amount: amount))
    }
}

private extension UIColor {
    func mixing(with other: UIColor, amount: Double) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let clamped = min(max(amount, 0), 1)
        return UIColor(
            red: r1 * (1 - clamped) + r2 * clamped,
            green: g1 * (1 - clamped) + g2 * clamped,
            blue: b1 * (1 - clamped) + b2 * clamped,
            alpha: a1 * (1 - clamped) + a2 * clamped
        )
    }
}

extension Font {
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension ResistType {
    var v2MascotColor: Color {
        switch self {
        case .money: .punchGreen
        case .food: .punchPink
        case .time: .punchYellow
        }
    }

    var v2MascotMood: MascotMood {
        MascotMoment.idle.mood
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

    var v2MascotMood: MascotMood {
        mascotMoment.mood
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

struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        PunchyCard(fill: .cardBackground, padding: padding, borderWidth: 0) {
            content
        }
    }
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var axis: Axis = .horizontal
    var lineLimit: Int = 1
    var reservesSpace = false

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

    func appKeyboardDismissal() -> some View {
        self
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        UIApplication.shared.dismissKeyboard()
                    }
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.punchBlack)
                }
            }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

    var body: some View {
        BlobMascotView(color: moment.color, mood: moment.mood, size: size)
    }
}

struct AssetMascotSticker: View {
    let mood: MascotMood
    var size: CGFloat = 54

    private var assetName: String {
        switch mood {
        case .steady:
            "xiaoren_asset_steady"
        case .proud:
            "xiaoren_asset_proud"
        case .curious, .observe:
            "xiaoren_asset_observe"
        case .calm, .relieved:
            "xiaoren_asset_relieved"
        case .struggle:
            "xiaoren_asset_struggle"
        case .cooling:
            "xiaoren_asset_cooling"
        }
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size * 211 / 220)
            .shadow(color: .punchBlack.opacity(0.18), radius: 0, x: 0, y: max(2, size * 0.06))
            .accessibilityHidden(true)
    }
}

struct TypeMascotBadge: View {
    let type: ResistType
    var size: CGFloat = 64
    var showsAccessory = true

    private var mascotMood: MascotMood {
        switch type {
        case .money:
            .steady
        case .food:
            .observe
        case .time:
            .cooling
        }
    }

    var body: some View {
        ZStack {
            BlobMascotView(color: type.v2MascotColor, mood: mascotMood, size: size * 0.94)
                .offset(y: -size * 0.04)

            if showsAccessory {
                TypeMascotPoseAccessory(type: type)
                    .frame(width: size * 1.15, height: size)
            }
        }
        .frame(width: size * 1.15, height: size)
        .accessibilityHidden(true)
    }
}

private struct TypeMascotPoseAccessory: View {
    let type: ResistType

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let stroke = max(3, w * 0.07)

            ZStack {
                switch type {
                case .money:
                    mascotArm(from: CGPoint(x: w * 0.22, y: h * 0.58), to: CGPoint(x: w * 0.46, y: h * 0.69), control: CGPoint(x: w * 0.31, y: h * 0.70), stroke: stroke)
                    mascotArm(from: CGPoint(x: w * 0.79, y: h * 0.58), to: CGPoint(x: w * 0.66, y: h * 0.70), control: CGPoint(x: w * 0.78, y: h * 0.72), stroke: stroke)
                    WalletAccessory()
                        .frame(width: w * 0.42, height: h * 0.30)
                        .position(x: w * 0.57, y: h * 0.70)
                case .food:
                    mascotArm(from: CGPoint(x: w * 0.24, y: h * 0.58), to: CGPoint(x: w * 0.45, y: h * 0.67), control: CGPoint(x: w * 0.30, y: h * 0.75), stroke: stroke)
                    mascotArm(from: CGPoint(x: w * 0.78, y: h * 0.58), to: CGPoint(x: w * 0.63, y: h * 0.67), control: CGPoint(x: w * 0.76, y: h * 0.76), stroke: stroke)
                    MilkTeaAccessory()
                        .frame(width: w * 0.34, height: h * 0.45)
                        .position(x: w * 0.55, y: h * 0.68)
                case .time:
                    mascotArm(from: CGPoint(x: w * 0.22, y: h * 0.60), to: CGPoint(x: w * 0.50, y: h * 0.63), control: CGPoint(x: w * 0.32, y: h * 0.74), stroke: stroke)
                    mascotArm(from: CGPoint(x: w * 0.80, y: h * 0.54), to: CGPoint(x: w * 0.69, y: h * 0.61), control: CGPoint(x: w * 0.84, y: h * 0.69), stroke: stroke)
                    ClockAccessory()
                        .frame(width: w * 0.38, height: h * 0.38)
                        .position(x: w * 0.62, y: h * 0.64)

                    Path { path in
                        path.move(to: CGPoint(x: w * 0.83, y: h * 0.22))
                        path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.43), control: CGPoint(x: w * 0.95, y: h * 0.32))
                    }
                    .stroke(Color.punchBlue, style: StrokeStyle(lineWidth: max(3, stroke * 0.72), lineCap: .round))
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

struct MascotFeedbackCard: View {
    let moment: MascotMoment
    var message: String?

    private var usesDarkText: Bool {
        moment.feedbackUsesDarkText
    }

    private var textColor: Color {
        usesDarkText ? .punchBlack : .white
    }

    var body: some View {
        PunchyCard(fill: moment.feedbackFill, cornerRadius: 30, padding: 16) {
            HStack(spacing: 14) {
                MascotMomentView(moment: moment, size: 78)

                VStack(alignment: .leading, spacing: 6) {
                    Text(moment.feedbackTitle)
                        .font(.rounded(22, weight: .black))
                        .foregroundStyle(textColor)

                    Text(message ?? moment.feedbackMessage)
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(textColor.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    }
}

struct MascotFeedbackPopup: View {
    let moment: MascotMoment
    var message: String?
    var onDismiss: () -> Void = {}

    var body: some View {
        ZStack {
            Color.punchBlack.opacity(0.24)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                MascotMomentView(moment: moment, size: 124)
                    .padding(.top, 4)

                VStack(spacing: 8) {
                    Text(moment.feedbackTitle)
                        .font(.rounded(32, weight: .black))
                        .foregroundStyle(moment.feedbackUsesDarkText ? Color.punchBlack : .white)

                    Text(message ?? moment.feedbackMessage)
                        .font(.rounded(17, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle((moment.feedbackUsesDarkText ? Color.punchBlack : .white).opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
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

            VStack(alignment: .leading, spacing: 4) {
                Text("自选")
                    .font(.rounded(16, weight: .black))
                    .foregroundStyle(Color.ink)

                Text("自己填写")
                    .font(.rounded(11, weight: .bold))
                    .foregroundStyle(Color.secondaryInk)
            }

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

struct PropCategorySection: View {
    let title: String
    let templates: [PropTemplate]
    let selectedTemplate: PropTemplate?
    let onSelect: (PropTemplate) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.rounded(18, weight: .black))
                .foregroundStyle(Color.ink)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(templates) { template in
                    Button {
                        onSelect(template)
                    } label: {
                        PropCard(template: template, isSelected: selectedTemplate?.id == template.id)
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityLabel("选择\(template.title)")
                }
            }
        }
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

struct PrimaryBlobButton: View {
    let title: String
    var systemImage: String?
    var fill: Color = .punchBlack
    var foreground: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.rounded(17, weight: .black))
                }
                Text(title)
                    .font(.rounded(18, weight: .black))
            }
            .foregroundStyle(foreground)
            .frame(minHeight: 54)
            .frame(maxWidth: .infinity)
            .background(fill)
            .clipShape(Capsule())
            .shadow(color: .punchBlack.opacity(0.22), radius: 0, x: 0, y: 6)
        }
        .buttonStyle(PressableScaleStyle())
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

    private let days = ["一", "二", "三", "四", "五", "六", "日"]

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
    @State private var bounceToken = 0
    @State private var isReacting = false

    private var mascotMood: MascotMood {
        if isReacting {
            return type == .food ? .relieved : .proud
        }

        switch type {
        case .money:
            return .proud
        case .food:
            return .relieved
        case .time:
            return .cooling
        }
    }

    var body: some View {
        Button {
            playReaction()
        } label: {
            PunchyCard(fill: Color.blockColor(for: type), cornerRadius: 28, padding: 16) {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(type.assetTitle)
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(type == .time ? Color.punchBlack : .white)

                        Text(value)
                            .font(.rounded(28, weight: .black))
                            .foregroundStyle(type == .time ? Color.punchBlack : .white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)

                        Text(subtitle)
                            .font(.rounded(12, weight: .bold))
                            .foregroundStyle((type == .time ? Color.punchBlack : .white).opacity(0.78))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    AssetMascotSticker(mood: mascotMood, size: isReacting ? 54 : 46)
                        .rotationEffect(.degrees(isReacting ? mascotReactionRotation : 0))
                        .offset(x: 8 + (isReacting ? mascotReactionOffset : 0), y: -8)
                        .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.46), value: isReacting)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .modifier(ShakeEffect(animatableData: CGFloat(bounceToken)))
        .accessibilityLabel("\(type.assetTitle)，\(value)，点击查看反馈")
    }

    private var mascotReactionRotation: Double {
        switch type {
        case .money: -10
        case .food: 8
        case .time: -7
        }
    }

    private var mascotReactionOffset: CGFloat {
        switch type {
        case .money: -4
        case .food: 2
        case .time: 4
        }
    }

    private func playReaction() {
        if reduceMotion { return }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.58)) {
            bounceToken += 1
            isReacting = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.72)) {
                isReacting = false
            }
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

            Text(message)
                .font(.rounded(15, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
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
