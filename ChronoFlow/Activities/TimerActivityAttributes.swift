import ActivityKit
import SwiftUI

/// Cyan while there's room, warming to red as the vessel fills.
/// Lives here so the app and the widget can't drift apart on the thresholds.
enum LiquidTheme {
    static func color(for progress: Double) -> Color {
        progress > 0.9 ? .red : (progress > 0.75 ? .orange : .cyan)
    }
}

/// Shared between the app and the widget extension.
/// IMPORTANT: this file must belong to BOTH targets (Xcode > File Inspector >
/// Target Membership), otherwise the extension won't resolve the type.
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Deadline while running, `nil` while paused.
        ///
        /// When this is set the widget renders `Text(timerInterval:)`, which
        /// ticks on-device. That means a running timer needs no ActivityKit
        /// updates at all — we only push on state changes, not every second.
        var endDate: Date?

        /// Seconds left. Only read for the paused label, since a paused
        /// countdown can't be expressed as an interval.
        var remaining: Double
    }

    /// The duration the user dialled in, used to draw the progress track.
    var totalTime: Double
}

extension TimerActivityAttributes.ContentState {
    var isRunning: Bool { endDate != nil }

    /// mm:ss for the paused state.
    var formattedRemaining: String {
        let clamped = max(0, remaining)
        return String(format: "%02d:%02d", Int(clamped) / 60, Int(clamped) % 60)
    }

    func progress(totalTime: Double) -> Double {
        guard totalTime > 0 else { return 0 }
        let left = endDate.map { max(0, $0.timeIntervalSinceNow) } ?? max(0, remaining)
        return min(1, 1 - left / totalTime)
    }
}
