import SwiftUI

struct LiquidShaderView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    // Animation states
    @State private var time: TimeInterval = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                // 1. Define the "Metaball" rendering layer
                // We draw everything in white (alpha 1.0) first to calculate shapes
                context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                context.addFilter(.blur(radius: 15)) // The "Goo" factor
                
                context.drawLayer { ctx in
                    // A. Draw the base liquid (rising up)
                    let progressHeight = size.height * CGFloat(viewModel.progress)
                    let baseRect = CGRect(
                        x: 0,
                        y: size.height - progressHeight,
                        width: size.width,
                        height: progressHeight + 50 // Extra buffer
                    )
                    ctx.fill(Path(roundedRect: baseRect, cornerRadius: 0), with: .color(.white))
                    
                    // B. Draw the "Surface Tension" Wave
                    // We draw oscillating circles at the surface to simulate fluid tension
                    if viewModel.progress > 0 && viewModel.progress < 1.0 {
                        let surfaceY = size.height - progressHeight
                        for i in 0...5 {
                            let xOffset = (size.width / 5) * CGFloat(i)
                            let waveOffset = sin(now * 2 + Double(i)) * 15
                            let circleRect = CGRect(x: xOffset - 25, y: surfaceY - 25 + waveOffset, width: 60, height: 60)
                            ctx.fill(Circle().path(in: circleRect), with: .color(.white))
                        }
                    }
                    
                    // C. Draw Falling Drops (Only if running)
                    if viewModel.isRunning && viewModel.progress < 0.95 {
                        let dropCount = 12
                        for i in 0..<dropCount {
                            // Procedural pseudo-random motion based on time
                            let speed = 200.0 + Double(i * 10)
                            let yPos = (now * speed).truncatingRemainder(dividingBy: Double(size.height))
                            let xPos = (Double(i) / Double(dropCount)) * size.width + sin(now * 3 + Double(i)) * 20
                            
                            // Only draw if it's above the liquid line
                            if CGFloat(yPos) < (size.height - progressHeight + 30) {
                                let dropSize = 25.0 + sin(Double(i)) * 5
                                let dropRect = CGRect(x: xPos, y: CGFloat(yPos), width: dropSize, height: dropSize + 10)
                                ctx.fill(Capsule().path(in: dropRect), with: .color(.white))
                            }
                        }
                    }
                }
            }
            // 2. MASK: Use the gooey shape to mask a beautiful Mesh Gradient
            .overlay(
                LinearGradient(
                    colors: [
                        viewModel.currentThemeColor,
                        viewModel.currentThemeColor.opacity(0.6),
                        .purple.opacity(0.3) // Adds that "Oil" look
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .mask(
                    Canvas { context, size in
                        // Re-draw the exact same filter logic for the mask
                        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        context.addFilter(.blur(radius: 15))
                        context.drawLayer { ctx in
                            let progressHeight = size.height * CGFloat(viewModel.progress)
                            let baseRect = CGRect(x: 0, y: size.height - progressHeight, width: size.width, height: progressHeight + 50)
                            ctx.fill(Path(roundedRect: baseRect, cornerRadius: 0), with: .color(.white))
                            
                            if viewModel.progress > 0 && viewModel.progress < 1.0 {
                                let surfaceY = size.height - progressHeight
                                for i in 0...5 {
                                    let xOffset = (size.width / 5) * CGFloat(i)
                                    let waveOffset = sin(now * 2 + Double(i)) * 15
                                    let circleRect = CGRect(x: xOffset - 25, y: surfaceY - 25 + waveOffset, width: 60, height: 60)
                                    ctx.fill(Circle().path(in: circleRect), with: .color(.white))
                                }
                            }
                            
                            if viewModel.isRunning && viewModel.progress < 0.95 {
                                let dropCount = 12
                                for i in 0..<dropCount {
                                    let speed = 200.0 + Double(i * 10)
                                    let yPos = (now * speed).truncatingRemainder(dividingBy: Double(size.height))
                                    let xPos = (Double(i) / Double(dropCount)) * size.width + sin(now * 3 + Double(i)) * 20
                                    
                                    if CGFloat(yPos) < (size.height - progressHeight + 30) {
                                        let dropSize = 25.0 + sin(Double(i)) * 5
                                        let dropRect = CGRect(x: xPos, y: CGFloat(yPos), width: dropSize, height: dropSize + 10)
                                        ctx.fill(Capsule().path(in: dropRect), with: .color(.white))
                                    }
                                }
                            }
                        }
                    }
                )
            )
        }
    }
}

