import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The cooldown countdown on the Lock Screen and in the Dynamic Island. Collapsed, it is only 小忍 and
/// the time left — the thing being waited for is named only once the island is opened, so that it is
/// not held in front of the user for the whole wait.
struct CooldownActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CooldownActivityAttributes.self) { context in
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ActivityMascot(isDue: context.isDue, size: 52)
                    ActivityTitle(context: context)
                    Spacer(minLength: 8)
                    ActivityTimer(context: context, size: 30)
                }
                ActivityButtons(recordId: context.attributes.recordId)
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.55))
            .activitySystemActionForegroundColor(.white)
            .widgetURL(WidgetShared.cooldownURL(context.attributes.recordId))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        ActivityMascot(isDue: context.isDue, size: 46)
                        ActivityTitle(context: context)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ActivityTimer(context: context, size: 26)
                        .frame(maxHeight: .infinity)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ActivityButtons(recordId: context.attributes.recordId)
                        .padding(.top, 6)
                }
            } compactLeading: {
                ActivityMascot(isDue: context.isDue, size: 24)
            } compactTrailing: {
                ActivityTimer(context: context, size: 14)
                    .frame(maxWidth: 48)
            } minimal: {
                ActivityMascot(isDue: context.isDue, size: 22)
            }
            .widgetURL(WidgetShared.cooldownURL(context.attributes.recordId))
            .keylineTint(ActivityPalette.green)
        }
    }
}

private enum ActivityPalette {
    static let green = Color(red: 0.024, green: 0.749, blue: 0.435)
    static let ink = Color(red: 0.025, green: 0.025, blue: 0.035)
}

private extension ActivityViewContext<CooldownActivityAttributes> {
    /// The app is not running to say so when the time is up; the stale date and the clock do.
    var isDue: Bool {
        isStale || state.until <= .now
    }
}

private struct ActivityMascot: View {
    let isDue: Bool
    let size: CGFloat

    var body: some View {
        Image(isDue ? "mascot_hello" : "mascot_cooling")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct ActivityTitle: View {
    let context: ActivityViewContext<CooldownActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(context.isDue ? "还想要吗" : "冷静中")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

private struct ActivityTimer: View {
    let context: ActivityViewContext<CooldownActivityAttributes>
    let size: CGFloat

    var body: some View {
        Group {
            if context.isDue {
                Text(size < 20 ? "到了" : "到时间了")
                    .font(.system(size: size < 20 ? size : size * 0.66, weight: .black, design: .rounded))
            } else {
                Text(timerInterval: Date.now...context.state.until, countsDown: true)
                    .font(.system(size: size, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
            }
        }
        .foregroundStyle(ActivityPalette.green)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

private struct ActivityButtons: View {
    let recordId: UUID

    var body: some View {
        HStack(spacing: 10) {
            Button(intent: CooldownDecisionIntent(recordId: recordId, resisted: true)) {
                Label("我忍住了", systemImage: "checkmark")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(ActivityPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(ActivityPalette.green)
                    .clipShape(Capsule())
            }

            Button(intent: CooldownDecisionIntent(recordId: recordId, resisted: false)) {
                Text("我还是做了")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.white.opacity(0.16))
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}
