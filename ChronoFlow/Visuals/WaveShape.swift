import SwiftUI

// MARK: - Wave Shape
// Creates the undulating top surface of the liquid
struct WaveShape: Shape {
    var offset: Angle
    var percent: Double // How high up the wave is (0.0 - 1.0)
    var waveHeight: Double = 0.025 // Relative height of the wave crests

    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let lowestPoint = rect.maxY
        let highestPoint = rect.maxY * (1.0 - percent)
        
        let actualWaveHeight = rect.height * waveHeight

        // Start at bottom left
        p.move(to: CGPoint(x: rect.minX, y: lowestPoint))
        
        // Draw line up to the start of the wave
        p.addLine(to: CGPoint(x: rect.minX, y: highestPoint))

        // Draw the wave across the top
        for x in stride(from: rect.minX, to: rect.maxX, by: 2) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 2 + offset.radians)
            let y = highestPoint + sine * actualWaveHeight
            p.addLine(to: CGPoint(x: x, y: y))
        }

        // Draw down to bottom right and close
        p.addLine(to: CGPoint(x: rect.maxX, y: lowestPoint))
        p.closeSubpath()
        return p
    }
}

// MARK: - Liquid Gradients
struct LiquidGradients {
    static func fluidGradient(baseColor: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                baseColor.opacity(0.6),
                baseColor,
                baseColor.opacity(0.8)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static let glassOverlay = LinearGradient(
        colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
