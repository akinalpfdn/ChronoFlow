import SwiftUI
import Combine
class TimerViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var timeFormatted: String = "05:00"
    @Published var statusText: String = "READY"
    @Published var isRunning: Bool = false
    @Published var activeDrops: [LiquidDrop] = []
    
    // Required for iOS 26 Glass Morphing
    @Namespace var namespace
    
    var currentThemeColor: Color {
        progress > 0.9 ? .red : (progress > 0.75 ? .orange : .cyan)
    }
    
    struct LiquidDrop: Identifiable {
        let id = UUID(); var x: CGFloat; var y: CGFloat; var size: CGFloat
    }
    
    private var timer: Timer?
    var totalTime: Double = 30 // Made internal for binding access
    @Published var currentTime: Double = 30 // Published for UI binding
    
    // Updates formatting when totalTime is manually changed
    func updateTotalTime(_ newTime: Double) {
        totalTime = newTime
        currentTime = newTime
        // Recalculate display
        let m = Int(currentTime) / 60
        let s = Int(currentTime) % 60
        timeFormatted = String(format: "%02d:%02d", m, s)
        progress = 0.0 // Reset progress
    }
    
    func toggleTimer() {
        isRunning.toggle()
        statusText = isRunning ? "FLOWING" : "PAUSED"
        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in self.tick() }
        } else {
            timer?.invalidate()
        }
    }
    
    func resetTimer() {
        isRunning = false; timer?.invalidate(); currentTime = totalTime
        progress = 0.0; timeFormatted = "05:00"; statusText = "READY"
        activeDrops.removeAll()
    }
    
    private func tick() {
        if currentTime > 0 {
            currentTime -= 1/60
            progress = 1.0 - (currentTime / totalTime)
            
            let m = Int(currentTime) / 60
            let s = Int(currentTime) % 60
            timeFormatted = String(format: "%02d:%02d", m, s)
            
            updateDrops()
        } else {
            statusText = "COMPLETE"
            timer?.invalidate()
        }
    }
    
    private func updateDrops() {
        // Old simulation logic removed.
        // Physics are now handled by LiquidGameScene in Visuals/LiquidPhysics.swift
    }
}
