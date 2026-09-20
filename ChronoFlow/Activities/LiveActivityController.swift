import ActivityKit
import Foundation

/// Wraps ActivityKit so the view model stays free of its lifecycle details.
///
/// Every call is a no-op when Live Activities are disabled by the user or
/// unsupported, so callers never need to check first.
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var activity: Activity<TimerActivityAttributes>?

    private var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(totalTime: Double, endDate: Date) {
        guard isAvailable else { return }

        // Never stack activities; a restart replaces the previous one.
        guard activity == nil else {
            update(endDate: endDate, remaining: endDate.timeIntervalSinceNow)
            return
        }

        let state = TimerActivityAttributes.ContentState(
            endDate: endDate,
            remaining: endDate.timeIntervalSinceNow
        )

        activity = try? Activity.request(
            attributes: TimerActivityAttributes(totalTime: totalTime),
            content: .init(state: state, staleDate: endDate),
            pushType: nil
        )
    }

    func update(endDate: Date?, remaining: Double) {
        guard let activity else { return }

        let state = TimerActivityAttributes.ContentState(endDate: endDate, remaining: remaining)
        Task {
            await activity.update(.init(state: state, staleDate: endDate))
        }
    }

    /// `showCompleted` leaves the finished state on the Lock Screen briefly
    /// instead of yanking it away the instant the timer fires.
    func end(showCompleted: Bool) {
        guard let activity else { return }
        self.activity = nil

        let state = TimerActivityAttributes.ContentState(endDate: nil, remaining: 0)
        Task {
            await activity.end(
                showCompleted ? .init(state: state, staleDate: nil) : nil,
                dismissalPolicy: showCompleted ? .after(.now + 30) : .immediate
            )
        }
    }
}
