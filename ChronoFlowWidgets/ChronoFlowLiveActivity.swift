import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Shared pieces

private extension TimerActivityAttributes.ContentState {
    /// `Text(timerInterval:)` needs a range that ends in the future; a deadline
    /// that has already passed would render as a stuck or negative countdown.
    var safeRange: ClosedRange<Date>? {
        guard let endDate else { return nil }
        return Date.now...max(endDate, Date.now.addingTimeInterval(1))
    }
}

/// Renders the live countdown when running, a frozen label when paused.
/// Running never needs an ActivityKit push — the system ticks this locally.
private struct Countdown: View {
    let state: TimerActivityAttributes.ContentState
    var font: Font

    var body: some View {
        Group {
            if let range = state.safeRange {
                Text(timerInterval: range, countsDown: true)
            } else {
                Text(state.formattedRemaining)
            }
        }
        .font(font)
        .monospacedDigit()
        .contentTransition(.numericText())
    }
}

private struct FlowProgress: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        let total = context.attributes.totalTime
        let tint = LiquidTheme.color(for: context.state.progress(totalTime: total))

        Group {
            if let endDate = context.state.endDate {
                // The bar spans the full dialled duration and lands on the
                // deadline, so it stays correct across pause and resume.
                ProgressView(timerInterval: endDate.addingTimeInterval(-total)...endDate,
                             countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                ProgressView(value: context.state.progress(totalTime: total))
            }
        }
        .progressViewStyle(.linear)
        .tint(tint)
    }
}

// MARK: - Lock Screen

private struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        let tint = LiquidTheme.color(for: context.state.progress(totalTime: context.attributes.totalTime))

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(context.state.isRunning ? "FLOWING" : "PAUSED")
                    .font(.caption2)
                    .tracking(4)
                    .foregroundStyle(.secondary)

                Spacer()

                Countdown(state: context.state,
                          font: .system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
            }

            FlowProgress(context: context)
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.6))
        .activitySystemActionForegroundColor(tint)
    }
}

// MARK: - Widget

struct ChronoFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            let tint = LiquidTheme.color(for: context.state.progress(totalTime: context.attributes.totalTime))

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isRunning ? "drop.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundStyle(tint)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(state: context.state,
                              font: .system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    FlowProgress(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.isRunning ? "drop.fill" : "pause.fill")
                    .foregroundStyle(tint)
            } compactTrailing: {
                Countdown(state: context.state, font: .caption2)
                    .foregroundStyle(tint)
                    // Fixed width stops the island resizing every second as
                    // the digits change.
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(tint)
            }
            .keylineTint(tint)
        }
    }
}
