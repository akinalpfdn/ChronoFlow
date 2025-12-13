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
    private var totalTime: Double = 300
    private var currentTime: Double = 300
    
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
        // 1. Move Drops
        for i in activeDrops.indices { activeDrops[i].y += 8 }
        
        // 2. Remove drops that merged into the pool
        let threshold = UIScreen.main.bounds.height * (1.0 - CGFloat(progress))
        // In iOS 26, visual merging is automatic, we just clean up the data
        activeDrops.removeAll { $0.y > threshold + 30 }
        
        // 3. Spawn Drops
        if isRunning && progress < 0.95 && Double.random(in: 0...1) > 0.92 {
            let w = UIScreen.main.bounds.width
            activeDrops.append(LiquidDrop(
                x: CGFloat.random(in: 20...w-20),
                y: -40,
                size: CGFloat.random(in: 15...35)
            ))
        }
    }
}
