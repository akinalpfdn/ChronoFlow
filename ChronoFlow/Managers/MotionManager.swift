import CoreMotion
import SwiftUI
import Combine
class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0
    
    init() {
        startMotionUpdates()
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let data = data else { return }
                
                withAnimation(.linear(duration: 0.1)) {
                    // We clamp the roll so the liquid doesn't fly off screen
                    self?.roll = data.attitude.roll
                    self?.pitch = data.attitude.pitch
                }
            }
        }
    }
}
