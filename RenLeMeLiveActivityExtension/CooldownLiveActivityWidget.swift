import ActivityKit
import SwiftUI
import WidgetKit

@main
struct RenLeMeLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        CooldownLiveActivityWidget()
    }
}

struct CooldownLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CooldownActivityAttributes.self) { context in
            LockScreenCooldownView(context: context)
                .activityBackgroundTint(.init(red: 0.96, green: 0.93, blue: 0.86))
                .activitySystemActionForegroundColor(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandMascotView(status: context.state.status, typeRaw: context.state.typeRaw)
                        .frame(width: 48, height: 48)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.state.title)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .lineLimit(1)
                        Text(context.state.status.shortTitle)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    CountdownText(endsAt: context.state.endsAt)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.status.message)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } compactLeading: {
                IslandMascotView(status: context.state.status, typeRaw: context.state.typeRaw)
                    .frame(width: 28, height: 28)
            } compactTrailing: {
                CountdownText(endsAt: context.state.endsAt, compact: true)
            } minimal: {
                IslandMascotView(status: context.state.status, typeRaw: context.state.typeRaw)
                    .frame(width: 22, height: 22)
            }
            .keylineTint(context.state.typeColor)
        }
    }
}

private struct LockScreenCooldownView: View {
    let context: ActivityViewContext<CooldownActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            IslandMascotView(status: context.state.status, typeRaw: context.state.typeRaw)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(context.state.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(1)

                Text(context.state.status.message)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            CountdownText(endsAt: context.state.endsAt)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

private struct CountdownText: View {
    let endsAt: Date
    var compact = false

    var body: some View {
        let safeEnd = max(endsAt, Date())
        Text(timerInterval: Date()...safeEnd, countsDown: true)
            .font(.system(size: compact ? 12 : 16, weight: .black, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }
}

private struct IslandMascotView: View {
    let status: CooldownLiveStatus
    let typeRaw: String

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                BlobShape()
                    .fill(status.faceColor(for: typeRaw))
                    .overlay {
                        BlobShape()
                            .stroke(Color.white, lineWidth: max(2, size * 0.1))
                    }

                FaceView(status: status)
                    .padding(size * 0.22)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct FaceView: View {
    let status: CooldownLiveStatus

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let eyeSize = max(3, width * 0.2)

            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: eyeSize * 1.25, height: eyeSize * 1.55)
                    .position(x: width * 0.34, y: height * 0.38)
                Circle()
                    .fill(.white)
                    .frame(width: eyeSize * 1.25, height: eyeSize * 1.55)
                    .position(x: width * 0.66, y: height * 0.38)

                Circle()
                    .fill(.black)
                    .frame(width: eyeSize * 0.45, height: eyeSize * 0.45)
                    .position(x: width * 0.37, y: height * 0.43)
                Circle()
                    .fill(.black)
                    .frame(width: eyeSize * 0.45, height: eyeSize * 0.45)
                    .position(x: width * 0.63, y: height * 0.43)

                mouth(in: CGSize(width: width, height: height))
                    .stroke(.black, style: StrokeStyle(lineWidth: max(2, width * 0.08), lineCap: .round))
            }
        }
    }

    private func mouth(in size: CGSize) -> Path {
        var path = Path()
        switch status {
        case .cooling:
            path.move(to: CGPoint(x: size.width * 0.39, y: size.height * 0.66))
            path.addLine(to: CGPoint(x: size.width * 0.61, y: size.height * 0.66))
        case .almostReady:
            path.move(to: CGPoint(x: size.width * 0.36, y: size.height * 0.68))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.64, y: size.height * 0.68),
                control: CGPoint(x: size.width * 0.5, y: size.height * 0.58)
            )
        case .ready:
            path.move(to: CGPoint(x: size.width * 0.34, y: size.height * 0.63))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.66, y: size.height * 0.63),
                control: CGPoint(x: size.width * 0.5, y: size.height * 0.78)
            )
        }
        return path
    }
}

private struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.52, y: h * 0.08))
        path.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.32), control1: CGPoint(x: w * 0.66, y: h * 0.06), control2: CGPoint(x: w * 0.76, y: h * 0.22))
        path.addCurve(to: CGPoint(x: w * 0.82, y: h * 0.78), control1: CGPoint(x: w * 0.98, y: h * 0.48), control2: CGPoint(x: w * 0.9, y: h * 0.66))
        path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.86), control1: CGPoint(x: w * 0.72, y: h * 0.9), control2: CGPoint(x: w * 0.58, y: h * 0.8))
        path.addCurve(to: CGPoint(x: w * 0.17, y: h * 0.78), control1: CGPoint(x: w * 0.36, y: h * 0.88), control2: CGPoint(x: w * 0.24, y: h * 0.9))
        path.addCurve(to: CGPoint(x: w * 0.12, y: h * 0.32), control1: CGPoint(x: w * 0.08, y: h * 0.64), control2: CGPoint(x: w * 0.16, y: h * 0.48))
        path.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.08), control1: CGPoint(x: w * 0.18, y: h * 0.18), control2: CGPoint(x: w * 0.38, y: h * 0.16))
        return path
    }
}

private extension CooldownLiveStatus {
    var shortTitle: String {
        switch self {
        case .cooling: "冷静中"
        case .almostReady: "快好了"
        case .ready: "可以决定了"
        }
    }

    var message: String {
        switch self {
        case .cooling: "小忍陪你等一下"
        case .almostReady: "再等最后一会儿"
        case .ready: "现在再决定"
        }
    }

    func faceColor(for typeRaw: String) -> Color {
        switch self {
        case .ready:
            return Color(red: 0.98, green: 0.94, blue: 0.78)
        case .almostReady:
            return Color(red: 1.0, green: 0.79, blue: 0.0)
        case .cooling:
            switch typeRaw {
            case "food": return Color(red: 0.94, green: 0.49, blue: 0.72)
            case "time": return Color(red: 1.0, green: 0.79, blue: 0.0)
            default: return Color(red: 0.0, green: 0.74, blue: 0.42)
            }
        }
    }
}

private extension CooldownActivityAttributes.ContentState {
    var typeColor: Color {
        switch typeRaw {
        case "food": return Color(red: 0.94, green: 0.49, blue: 0.72)
        case "time": return Color(red: 1.0, green: 0.79, blue: 0.0)
        default: return Color(red: 0.0, green: 0.74, blue: 0.42)
        }
    }
}
