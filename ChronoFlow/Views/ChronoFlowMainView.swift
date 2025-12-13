import SwiftUI

struct ChronoFlowMainView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        ZStack {
            // 1. Deep Background (Required for Glass refraction)
            Color.black.ignoresSafeArea()
            
            // 2. NATIVE iOS 26 LIQUID CONTAINER
            // "GlassEffectContainer" automatically blends overlapping children
            // We set spacing to 0 to ensure immediate fluid merging.
            GlassEffectContainer(spacing: 0) {
                
                // A. The Rising Pool
                GeometryReader { geo in
                    let fillHeight = geo.size.height * CGFloat(viewModel.progress)
                    let topOffset = geo.size.height - fillHeight
                    
                    // The main body of liquid
                    Rectangle()
                        .fill(viewModel.currentThemeColor)
                        .frame(height: fillHeight + 100)
                        .offset(y: topOffset)
                        // NATIVE API: Applies the refractive material
                        .glassEffect(.regular)
                        // NATIVE API: Identifies this shape for morphing
                        .glassEffectID("pool", in: viewModel.namespace)
                }
                
                // B. The Falling Drops
                ForEach(viewModel.activeDrops) { drop in
                    Capsule()
                        .fill(viewModel.currentThemeColor)
                        .frame(width: drop.size, height: drop.size * 1.5)
                        .position(x: drop.x, y: drop.y)
                        // The container merges this drop into the pool when they touch
                        .glassEffect(.regular)
                }
            }
            .ignoresSafeArea()
            
            // 3. Floating Interface
            VStack {
                Spacer()
                
                // NATIVE API: Text with glass material
                Text(viewModel.timeFormatted)
                    .font(.system(size: 130, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    // iOS 26 modifier to let background refract through text
                    .glassEffect(.regular)
                
                Text(viewModel.statusText)
                    .font(.caption)
                    .tracking(8)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 4. NATIVE GLASS BUTTONS
                HStack(spacing: 60) {
                    Button(action: viewModel.resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                    }
                    .buttonStyle(.glass) // Native iOS 26 style
                    
                    Button(action: viewModel.toggleTimer) {
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                            .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.glassProminent) // Native "Prominent" glass style
                }
                .padding(.bottom, 60)
            }
        }
    }
}
