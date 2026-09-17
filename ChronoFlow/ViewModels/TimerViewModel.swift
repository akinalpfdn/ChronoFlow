import SwiftUI
import Combine
import UserNotifications

class TimerViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var statusText: String = "READY"
    @Published var isRunning: Bool = false
    @Published var currentTime: Double = 30

    /// The duration the user dialled in. `currentTime` counts down from it.
    private(set) var totalTime: Double = 30

    var currentThemeColor: Color {
        progress > 0.9 ? .red : (progress > 0.75 ? .orange : .cyan)
    }

    /// Wall-clock deadline. Everything is derived from this, so the countdown
    /// stays accurate across drift, backgrounding and run-loop stalls.
    private var endDate: Date?
    private var timer: Timer?
    private var didWarn = false

    private let notificationID = "chronoflow.timer.complete"
    private let warningLeadTime: Double = 10

    // MARK: - Intent

    /// Dialling a new duration is only meaningful while stopped; ignoring it
    /// while running avoids the totalTime/progress mismatch a live edit causes.
    func updateTotalTime(_ newTime: Double) {
        guard !isRunning else { return }
        totalTime = max(1, newTime)
        currentTime = totalTime
        progress = 0
        statusText = "READY"
    }

    func toggleTimer() {
        isRunning ? pause() : start()
    }

    func resetTimer() {
        stopTicking()
        isRunning = false
        currentTime = totalTime
        progress = 0
        statusText = "READY"
        cancelCompletionNotification()
    }

    // MARK: - Lifecycle

    private func start() {
        guard currentTime > 0.5 else { return }

        endDate = Date().addingTimeInterval(currentTime)
        didWarn = false
        isRunning = true
        statusText = "FLOWING"
        HapticManager.shared.playFeedbackTap()
        scheduleCompletionNotification(in: currentTime)

        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common keeps the display ticking while a gesture is tracking.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func pause() {
        currentTime = remaining
        stopTicking()
        isRunning = false
        statusText = "PAUSED"
        HapticManager.shared.playFeedbackTap()
        cancelCompletionNotification()
    }

    private func complete() {
        stopTicking()
        isRunning = false
        currentTime = 0
        progress = 1
        statusText = "COMPLETE"
        HapticManager.shared.playTimeUpSignal()
    }

    private var remaining: Double {
        max(0, endDate?.timeIntervalSinceNow ?? currentTime)
    }

    private func tick() {
        let remaining = self.remaining
        currentTime = remaining
        progress = totalTime > 0 ? min(1, 1 - remaining / totalTime) : 0

        if !didWarn, remaining <= warningLeadTime, totalTime > warningLeadTime * 1.5 {
            didWarn = true
            HapticManager.shared.playWarningSignal()
        }

        if remaining <= 0 { complete() }
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    // MARK: - Background delivery

    /// Foreground completion is announced by haptics; this covers the case
    /// where the app is backgrounded or the screen is locked when time runs out.
    private func scheduleCompletionNotification(in seconds: Double) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Time's up"
            content.body = "Your flow is complete."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
            center.add(UNNotificationRequest(identifier: self.notificationID, content: content, trigger: trigger))
        }
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
